//
//  CCColorCube.mm
//
//  Copyright (c) 2014 Ole Krause-Sparmann
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
//  and associated documentation files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial
//  portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
//  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "CCColorCube.h"

#import "CCLocalMaximum.h"

// The cell resolution in each color dimension
#define COLOR_CUBE_RESOLUTION 30

// Threshold used to filter bright colors
#define BRIGHT_COLOR_THRESHOLD 0.6

// Threshold used to filter dark colors
#define DARK_COLOR_THRESHOLD 0.4

// Threshold (distance in color space) for distinct colors
#define DISTINCT_COLOR_THRESHOLD 0.2

// Helper macro to compute linear index for cells
#define CELL_INDEX(r,g,b) (r+g*COLOR_CUBE_RESOLUTION+b*COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION)

// Helper macro to get total count of cells
#define CELL_COUNT COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION

// Indices for neighbour cells in three dimensional grid
int neighbourIndices[27][3] = {
    { 0, 0, 0},
    { 0, 0, 1},
    { 0, 0,-1},

    { 0, 1, 0},
    { 0, 1, 1},
    { 0, 1,-1},

    { 0,-1, 0},
    { 0,-1, 1},
    { 0,-1,-1},

    { 1, 0, 0},
    { 1, 0, 1},
    { 1, 0,-1},

    { 1, 1, 0},
    { 1, 1, 1},
    { 1, 1,-1},

    { 1,-1, 0},
    { 1,-1, 1},
    { 1,-1,-1},

    {-1, 0, 0},
    {-1, 0, 1},
    {-1, 0,-1},

    {-1, 1, 0},
    {-1, 1, 1},
    {-1, 1,-1},

    {-1,-1, 0},
    {-1,-1, 1},
    {-1,-1,-1}
};

@interface CCColorCube () {
    CCCubeCell cells[COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION];
}

// Returns array of raw pixel data (needs to be freed)
- (unsigned char *)rawPixelDataFromImage:(UIImage *)image pixelCount:(unsigned int*)pixelCount;

// Resets all cells
- (void)clearCells;

// Returns array of CCLocalMaximum objects
- (NSArray *)findLocalMaximaInImage:(UIImage *)image flags:(NSUInteger)flags;

// Returns array of CCLocalMaximum objects
- (NSArray *)findAndSortMaximaInImage:(UIImage *)image flags:(NSUInteger)flags;

// Returns array of CCLocalMaximum objects
- (NSArray *)extractAndFilterMaximaFromImage:(UIImage *)image flags:(NSUInteger)flags;

// Returns array of UIColor objects
- (NSArray *)colorsFromMaxima:(NSArray *)maxima;

// Returns new array with only distinct maxima
- (NSArray *)filterDistinctMaxima:(NSArray *)maxima threshold:(CGFloat)threshold;

// Removes maxima too close to specified color
- (NSArray *)filterMaxima:(NSArray *)maxima tooCloseToColor:(UIColor *)color;

// Tries to get count distinct maxima
- (NSArray *)performAdaptiveDistinctFilteringForMaxima:(NSArray *)maxima count:(NSUInteger)count;

// Orders maxima by brightness
- (NSArray *)orderByBrightness:(NSArray *)maxima;

// Orders maxima by darkness
- (NSArray *)orderByDarkness:(NSArray *)maxima;

@end

@implementation CCColorCube

#pragma mark - Object lifecycle

- (id)init
{
    self = [super init];
    if (self) {

    }

    return self;
}

- (void)dealloc
{
}

#pragma mark - Local maxima search

- (NSArray *)findLocalMaximaInImage:(UIImage *)image flags:(NSUInteger)flags
{
    // Reset all cells
    [self clearCells];

    // Get raw pixel data from image
    unsigned int pixelCount;
    unsigned char *rawData = [self rawPixelDataFromImage:image pixelCount:&pixelCount];
    if (!rawData) return nil;

    // Helper variables
    double red, green, blue;
    int redIndex, greenIndex, blueIndex, cellIndex, localHitCount;
    BOOL isLocalMaximum;

    // Project each pixel into one of the cells in the three dimensional grid
    for (int k=0; k<pixelCount; k++) {
        // Get color components as floating point value in [0,1]
        red   = (double)rawData[k*4+0]/255.0;
        green = (double)rawData[k*4+1]/255.0;
        blue  = (double)rawData[k*4+2]/255.0;

        // If we only want bright colors and this pixel is dark, ignore it
        if (flags & CCOnlyBrightColors) {
            if (red < BRIGHT_COLOR_THRESHOLD && green < BRIGHT_COLOR_THRESHOLD && blue < BRIGHT_COLOR_THRESHOLD) continue;
        }
        else if (flags & CCOnlyDarkColors) {
            if (red >= DARK_COLOR_THRESHOLD || green >= DARK_COLOR_THRESHOLD || blue >= DARK_COLOR_THRESHOLD) continue;
        }

        // Map color components to cell indices in each color dimension
        redIndex   = (int)(red*(COLOR_CUBE_RESOLUTION-1.0));
        greenIndex = (int)(green*(COLOR_CUBE_RESOLUTION-1.0));
        blueIndex  = (int)(blue*(COLOR_CUBE_RESOLUTION-1.0));

        // Compute linear cell index
        cellIndex = CELL_INDEX(redIndex, greenIndex, blueIndex);

        // Increase hit count of cell
        cells[cellIndex].hitCount++;

        // Add pixel colors to cell color accumulators
        cells[cellIndex].redAcc   += red;
        cells[cellIndex].greenAcc += green;
        cells[cellIndex].blueAcc  += blue;
    }

    // Deallocate raw pixel data memory
    free(rawData);

    // We collect local maxima in here
    NSMutableArray *localMaxima = [NSMutableArray array];

    // Find local maxima in the grid
    for (int r=0; r<COLOR_CUBE_RESOLUTION; r++) {
        for (int g=0; g<COLOR_CUBE_RESOLUTION; g++) {
            for (int b=0; b<COLOR_CUBE_RESOLUTION; b++) {
                // Get hit count of this cell
                localHitCount = cells[CELL_INDEX(r, g, b)].hitCount;

                // If this cell has no hits, ignore it (we are not interested in zero hits)
                if (localHitCount == 0) continue;

                // It is local maximum until we find a neighbour with a higher hit count
                isLocalMaximum = YES;

                // Check if any neighbour has a higher hit count, if so, no local maxima
                for (int n=0; n<27; n++) {
                    redIndex   = r+neighbourIndices[n][0];
                    greenIndex = g+neighbourIndices[n][1];
                    blueIndex  = b+neighbourIndices[n][2];

                    // Only check valid cell indices (skip out of bounds indices)
                    if (redIndex >= 0 && greenIndex >= 0 && blueIndex >= 0) {
                        if (redIndex < COLOR_CUBE_RESOLUTION && greenIndex < COLOR_CUBE_RESOLUTION && blueIndex < COLOR_CUBE_RESOLUTION) {
                            if (cells[CELL_INDEX(redIndex, greenIndex, blueIndex)].hitCount > localHitCount) {
                                // Neighbour hit count is higher, so this is NOT a local maximum.
                                isLocalMaximum = NO;
                                // Break inner loop
                                break;
                            }
                        }
                    }
                }

                // If this is not a local maximum, continue with loop.
                if (!isLocalMaximum) continue;

                // Otherwise add this cell as local maximum
                CCLocalMaximum *maximum = [[CCLocalMaximum alloc] init];
                maximum.cellIndex = CELL_INDEX(r, g, b);
                maximum.hitCount = cells[maximum.cellIndex].hitCount;
                maximum.red   = cells[maximum.cellIndex].redAcc / (double)cells[maximum.cellIndex].hitCount;
                maximum.green = cells[maximum.cellIndex].greenAcc / (double)cells[maximum.cellIndex].hitCount;
                maximum.blue  = cells[maximum.cellIndex].blueAcc / (double)cells[maximum.cellIndex].hitCount;
                maximum.brightness = fmax(fmax(maximum.red, maximum.green), maximum.blue);
                [localMaxima addObject:maximum];
            }
        }
    }

    // Finally sort the array of local maxima by hit count
    NSArray *sortedMaxima = [localMaxima sortedArrayUsingComparator:^NSComparisonResult(CCLocalMaximum *m1, CCLocalMaximum *m2){
        if (m1.hitCount == m2.hitCount) return NSOrderedSame;
        return m1.hitCount > m2.hitCount ? NSOrderedAscending : NSOrderedDescending;
    }];

    return sortedMaxima;
}

- (NSArray *)findAndSortMaximaInImage:(UIImage *)image flags:(NSUInteger)flags
{
    // First get local maxima of image
    NSArray *sortedMaxima = [self findLocalMaximaInImage:image flags:flags];

    // Filter the maxima if we want only distinct colors
    if (flags & CCOnlyDistinctColors) {
        sortedMaxima = [self filterDistinctMaxima:sortedMaxima threshold:DISTINCT_COLOR_THRESHOLD];
    }

    // If we should order the result array by brightness, do it
    if (flags & CCOrderByBrightness) {
        sortedMaxima = [self orderByBrightness:sortedMaxima];
    }
    else if (flags & CCOrderByDarkness) {
        sortedMaxima = [self orderByDarkness:sortedMaxima];
    }

    return sortedMaxima;
}

#pragma mark - Filtering and sorting

- (NSArray *)filterDistinctMaxima:(NSArray *)maxima threshold:(CGFloat)threshold
{
    NSMutableArray *filteredMaxima = [NSMutableArray array];

    // Check for each maximum
    for (int k=0; k<maxima.count; k++) {
        // Get the maximum we are checking out
        CCLocalMaximum *max1 = maxima[k];

        // This color is distinct until a color from before is too close
        BOOL isDistinct = YES;

        // Go through previous colors and look if any of them is too close
        for (int n=0; n<k; n++) {
            // Get the maximum we compare to
            CCLocalMaximum *max2 = maxima[n];

            // Compute delta components
            double redDelta   = max1.red - max2.red;
            double greenDelta = max1.green - max2.green;
            double blueDelta  = max1.blue - max2.blue;

            // Compute delta in color space distance
            double delta = sqrt(redDelta*redDelta + greenDelta*greenDelta + blueDelta*blueDelta);

            // If too close mark as non-distinct and break inner loop
            if (delta < threshold) {
                isDistinct = NO;
                break;
            }
        }

        // Add to filtered array if is distinct
        if (isDistinct) {
            [filteredMaxima addObject:max1];
        }
    }

    return [NSArray arrayWithArray:filteredMaxima];
}

- (NSArray *)filterMaxima:(NSArray *)maxima tooCloseToColor:(UIColor*)color
{
    // Get color components
    const CGFloat *components = CGColorGetComponents(color.CGColor);

    NSMutableArray *filteredMaxima = [NSMutableArray array];

    // Check for each maximum
    for (int k=0; k<maxima.count; k++) {
        // Get the maximum we are checking out
        CCLocalMaximum *max1 = maxima[k];

        // Compute delta components
        double redDelta   = max1.red - components[0];
        double greenDelta = max1.green - components[1];
        double blueDelta  = max1.blue - components[2];

        // Compute delta in color space distance
        double delta = sqrt(redDelta*redDelta + greenDelta*greenDelta + blueDelta*blueDelta);

        // If not too close add it
        if (delta >= 0.5) {
            [filteredMaxima addObject:max1];
        }
    }

    return [NSArray arrayWithArray:filteredMaxima];
}

- (NSArray *)orderByBrightness:(NSArray *)maxima
{
    return [maxima sortedArrayUsingComparator:^NSComparisonResult(CCLocalMaximum *m1, CCLocalMaximum *m2){
        return m1.brightness > m2.brightness ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (NSArray *)orderByDarkness:(NSArray *)maxima
{
    return [maxima sortedArrayUsingComparator:^NSComparisonResult(CCLocalMaximum *m1, CCLocalMaximum *m2){
        return m1.brightness < m2.brightness ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (NSArray *)performAdaptiveDistinctFilteringForMaxima:(NSArray *)maxima count:(NSUInteger)count
{
    // If the count of maxima is higher than the requested count, perform distinct thresholding
    if (maxima.count > count) {

        NSArray *tempDistinctMaxima = maxima;
        double distinctThreshold = 0.1;

        // Decrease the threshold ten times. If this does not result in the wanted count
        for (int k=0; k<10; k++) {
            // Get array with current distinct threshold
            tempDistinctMaxima = [self filterDistinctMaxima:maxima threshold:distinctThreshold];

            // If this array has less than count, break and take the current sortedMaxima
            if (tempDistinctMaxima.count <= count) {
                break;
            }

            // Keep this result (length is > count)
            maxima = tempDistinctMaxima;

            // Increase threshold by 0.05
            distinctThreshold += 0.05;
        }

        // Only take first count maxima
        maxima = [maxima subarrayWithRange:NSMakeRange(0, count)];
    }

    return maxima;
}

#pragma mark - Maximum to color conversion

- (NSArray *)colorsFromMaxima:(NSArray *)maxima
{
    // Build the resulting color array
    NSMutableArray *colorArray = [NSMutableArray array];

    // For each local maximum generate UIColor and add it to the result array
    for (CCLocalMaximum *maximum in maxima) {
        [colorArray addObject:[UIColor colorWithRed:maximum.red green:maximum.green blue:maximum.blue alpha:1.0]];
    }

    return [NSArray arrayWithArray:colorArray];
}

#pragma mark - Default maxima extraction and filtering

- (NSArray *)extractAndFilterMaximaFromImage:(UIImage *)image flags:(NSUInteger)flags
{
    // Get maxima
    NSArray *sortedMaxima = [self findAndSortMaximaInImage:image flags:flags];

    // Filter out colors too close to black
    if (flags & CCAvoidBlack) {
        sortedMaxima = [self filterMaxima:sortedMaxima tooCloseToColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
    }

    // Filter out colors too close to white
    if (flags & CCAvoidWhite) {
        sortedMaxima = [self filterMaxima:sortedMaxima tooCloseToColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
    }

    // Return maxima array
    return sortedMaxima;
}
#pragma mark - Public methods

- (NSArray <UIColor *> *)extractColorsFromImage:(UIImage *)image flags:(CCFlags)flags
{
    // Get maxima
    NSArray *sortedMaxima = [self extractAndFilterMaximaFromImage:image flags:flags];

    // Return color array
    return [self colorsFromMaxima:sortedMaxima];
}

- (NSArray <UIColor *> *)extractColorsFromImage:(UIImage *)image flags:(CCFlags)flags avoidColor:(UIColor*)avoidColor
{
    // Get maxima
    NSArray *sortedMaxima = [self extractAndFilterMaximaFromImage:image flags:flags];

    // Filter out colors that are too close to the specified color
    sortedMaxima = [self filterMaxima:sortedMaxima tooCloseToColor:avoidColor];

    // Return color array
    return [self colorsFromMaxima:sortedMaxima];
}

- (NSArray <UIColor *> *)extractBrightColorsFromImage:(UIImage *)image avoidColor:(UIColor *)avoidColor count:(NSUInteger)count
{
    // Get maxima (bright only)
    NSArray *sortedMaxima = [self findAndSortMaximaInImage:image flags:CCOnlyBrightColors];

    if (avoidColor) {
        // Filter out colors that are too close to the specified color
        sortedMaxima = [self filterMaxima:sortedMaxima tooCloseToColor:avoidColor];
    }

    // Do clever distinct color filtering
    sortedMaxima = [self performAdaptiveDistinctFilteringForMaxima:sortedMaxima count:count];

    // Return color array
    return [self colorsFromMaxima:sortedMaxima];
}

- (NSArray *)extractDarkColorsFromImage:(UIImage *)image avoidColor:(UIColor*)avoidColor count:(NSUInteger)count
{
    // Get maxima (dark only)
    NSArray *sortedMaxima = [self findAndSortMaximaInImage:image flags:CCOnlyDarkColors];

    if (avoidColor) {
        // Filter out colors that are too close to the specified color
        sortedMaxima = [self filterMaxima:sortedMaxima tooCloseToColor:avoidColor];
    }

    // Do clever distinct color filtering
    sortedMaxima = [self performAdaptiveDistinctFilteringForMaxima:sortedMaxima count:count];

    // Return color array
    return [self colorsFromMaxima:sortedMaxima];
}

- (NSArray <UIColor *> *)extractColorsFromImage:(UIImage *)image flags:(CCFlags)flags count:(NSUInteger)count
{
    // Get maxima
    NSArray *sortedMaxima = [self extractAndFilterMaximaFromImage:image flags:flags];

    // Do clever distinct color filtering
    sortedMaxima = [self performAdaptiveDistinctFilteringForMaxima:sortedMaxima count:count];

    // Return color array
    return [self colorsFromMaxima:sortedMaxima];
}

#pragma mark - Resetting cells

- (void)clearCells
{
    for (int k=0; k<COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION; k++) {
        cells[k].hitCount = 0;
        cells[k].redAcc = 0.0;
        cells[k].greenAcc = 0.0;
        cells[k].blueAcc = 0.0;
    }
}

#pragma mark - Pixel data extraction

- (unsigned char *)rawPixelDataFromImage:(UIImage *)image pixelCount:(unsigned int*)pixelCount
{
    // Get cg image and its size
    CGImageRef cgImage;
    
    #if TARGET_OS_OSX
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)[image TIFFRepresentation], NULL);
        cgImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    #else
        cgImage = [image CGImage];
    #endif
    
    NSUInteger width = CGImageGetWidth(cgImage);
    NSUInteger height = CGImageGetHeight(cgImage);

    // Allocate storage for the pixel data
    unsigned char *rawData = (unsigned char *)malloc(height * width * 4);

    // If allocation failed, return NULL
    if (!rawData) return NULL;

    // Create the color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // Set some metrics
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;

    // Create context using the storage
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    // Release the color space
    CGColorSpaceRelease(colorSpace);

    // Draw the image into the storage
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);

    // We are done with the context
    CGContextRelease(context);
    
    #if TARGET_OS_OSX
        // We are done with the image
        CGImageRelease(cgImage);
    
        // We are done with the source
        CFRelease(source);
    #endif

    // Write pixel count to passed pointer
    *pixelCount = (int)width * (int)height;

    // Return pixel data (needs to be freed)
    return rawData;
}

@end
