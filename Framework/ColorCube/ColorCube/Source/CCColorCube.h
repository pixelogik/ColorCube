//
//  CCColorCube.h
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

#import <TargetConditionals.h>

#if TARGET_OS_OSX
    #import <Cocoa/Cocoa.h>

    #define UIImage NSImage
    #define UIColor NSColor
#else
    #import <UIKit/UIKit.h>
#endif

// Flags that determine how the colors are extract
typedef enum CCFlags: NSUInteger
{
    // This ignores all pixels that are darker than a threshold
    CCOnlyBrightColors   = 1 << 0,

    // This ignores all pixels that are brighter than a threshold
    CCOnlyDarkColors     = 1 << 1,

    // This filters the result array so that only distinct colors are returned
    CCOnlyDistinctColors = 1 << 2,
    
    // This orders the result array by color brightness (first color has highest brightness). If not set,
    // colors are ordered by frequency (first color is "most frequent").
    CCOrderByBrightness  = 1 << 3,
    
    // This orders the result array by color darkness (first color has lowest brightness). If not set,
    // colors are ordered by frequency (first color is "most frequent").
    CCOrderByDarkness    = 1 << 4,

    // Removes colors from the result if they are too close to white
    CCAvoidWhite         = 1 << 5,
    
    // Removes colors from the result if they are too close to black
    CCAvoidBlack         = 1 << 6
    
} CCFlags;

// The color cube is made out of these cells
typedef struct CCCubeCell {
    
    // Count of hits (dividing the accumulators by this value gives the average)
    unsigned int hitCount;

    // Accumulators for color components
    double redAcc;
    double greenAcc;
    double blueAcc;
    
} CCCubeCell;

// This class implements a simple method to extract the most dominant colors of an image.
// How it does it: It projects all pixels of the image into a three dimensional grid (the "cube"),
// then finds local maximas in that grid and returns the average colors of these "maximum cells"
// ordered by their hit count (kind of "color frequency").
// You should call these methods on a background thread. Depending on the image size they can take
// some time.
@interface CCColorCube : NSObject

// Extracts and returns dominant colors of the image (the array contains UIColor objects). Result might be empty.
- (NSArray <UIColor *> * _Nullable )extractColorsFromImage:(UIImage * _Nonnull)image flags:(CCFlags)flags;

// Same as above but avoids colors too close to the specified one.
// IMPORTANT: The avoidColor must be in RGB, so create it with colorWithRed method of UIColor!
- (NSArray <UIColor *> * _Nullable )extractColorsFromImage:(UIImage * _Nonnull)image flags:(CCFlags)flags avoidColor:(UIColor * _Nonnull)avoidColor;

// Tries to get count bright colors from the image, avoiding the specified one (only if avoidColor is non-nil).
// IMPORTANT: The avoidColor (if set) must be in RGB, so create it with colorWithRed method of UIColor!
// Might return less than count colors! 
- (NSArray <UIColor *> * _Nullable )extractBrightColorsFromImage:(UIImage * _Nonnull)image avoidColor:(UIColor * _Nonnull)avoidColor count:(NSUInteger)count;

// Tries to get count dark colors from the image, avoiding the specified one (only if avoidColor is non-nil).
// IMPORTANT: The avoidColor (if set) must be in RGB, so create it with colorWithRed method of UIColor!
// Might return less than count colors!
- (NSArray <UIColor *> * _Nullable )extractDarkColorsFromImage:(UIImage * _Nonnull)image avoidColor:(UIColor * _Nonnull)avoidColor count:(NSUInteger)count;

// Tries to get count colors from the image
// Might return less than count colors!
- (NSArray <UIColor *> * _Nullable )extractColorsFromImage:(UIImage * _Nonnull)image flags:(CCFlags)flags count:(NSUInteger)count;

@end
