ColorCube
=========

Fast and easy color extraction from RGB images on iOS using a 3d histogram ("color cube").

This comes in handy if you want to colorize UI elements in the context of an image.

The algorithm goes like this:

1. All pixels of the image are projected into the 3d histogram grid.
2. Local maxima of the hit count ("pixels in cell") in this grid are searched for.
3. These local maxima are then sorted by hit count (highest first = "color frequency").
4. The average color of each maximum cell is used in the resulting array.

The methods support different options via flags:

- CCOnlyBrightColors: Ignore all pixels that are darker than a threshold
- CCOnlyDarkColors: Ignore all pixels that are brighter than a threshold
- CCOnlyDistinctColors: Filters the result array so that only distinct colors are returned
- CCOrderByBrightness: Orders the result array by color brightness
- CCOrderByDarkness: Orders the result array by color darkness
- CCAvoidWhite: Removes colors from the result if they are too close to white
- CCAvoidBlack: Removes colors from the result if they are too close to black

Most simple usage:

// Get four dominant colors from the image, but avoid the background color of our UI
CCColorCube *colorCube = [[CCColorCube alloc] init];
UIImage *img = [UIImage imageNamed:@"test2.jpg"];
NSArray *imgColors = [colorCube extractColorsFromImage:img avoidColor:myBackgroundColor count:4];

This project contains the core classes (CCColorCube and CCLocalMaximum) and some demo code, an iPhone app, that shows a table of images with their corresponding four "palette" colors, extracted using CCColorCube.

[IMAGE OF APP]

If you want to know more about the method, check out this blog post about it.

(im blogpost auch etwas über itunes sagen, und deren fx, etc....)


