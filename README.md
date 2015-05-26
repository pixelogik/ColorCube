ColorCube
=========

![alt tag](http://www.pixelogik.de/static/images/articles/local-maxima-in-color-histogram//ColorCubeCover2.jpg)

In a current iOS project I needed to get dominant colors from images. Some hints were going into some code that tried to mimic iTunes way of doing it, but they did not work for me. So I did this thing, called ColorCube.

It performs fast and easy color extraction from RGB images on iOS using a 3d histogram ("color cube"). It is fast because in order to extract colors you can downscale your image if it is too large and still get nice colors.

We use this at [you & the gang](http://youandthegang.com/) for in-house projects.

I just added a Python version of the algorithm, used by [marvel](https://marvelapp.com/). Marvel builds great mobile & web prototyping tools, check it out! 

###  The algorithm goes like this:

1. All pixels of the image are projected into the 3d histogram grid.
2. Local maxima of the hit count ("pixels in cell") in this grid are searched for.
3. These local maxima are then sorted by hit count (highest first = "color frequency").
4. The average color of each maximum cell is used in the resulting array.

### The methods support different options via flags:

- CCOnlyBrightColors: Ignore all pixels that are darker than a threshold
- CCOnlyDarkColors: Ignore all pixels that are brighter than a threshold
- CCOnlyDistinctColors: Filters the result array so that only distinct colors are returned
- CCOrderByBrightness: Orders the result array by color brightness
- CCOrderByDarkness: Orders the result array by color darkness
- CCAvoidWhite: Removes colors from the result if they are too close to white
- CCAvoidBlack: Removes colors from the result if they are too close to black

###  Most simple usage:

    // Get four dominant colors from the image, but avoid the background color of our UI
    CCColorCube *colorCube = [[CCColorCube alloc] init];
    UIImage *img = [UIImage imageNamed:@"test2.jpg"];
    NSArray *imgColors = [colorCube extractColorsFromImage:img avoidColor:myBackgroundColor count:4];

###  Demo:

This project contains the core classes (CCColorCube and CCLocalMaximum) and some demo code, an iPhone app, that shows a table of images with their corresponding four "palette" colors, extracted using CCColorCube.

The demo app has a segmented control at the bottom for three different configurations of the method. They all extract four bright colors from the images. The second method also tries to avoid colors too close to white. The third method does the same with blue. Avoiding the background color of your UI is handy to make the extracted colors stand out.

![alt tag](http://www.pixelogik.de/static/images/articles/local-maxima-in-color-histogram//ColorCubeDemo.jpg)

###  The algorithm:

A RGB color image is nothing but a set of points in five dimensional vector space (ignoring alpha here). The dimensions are

- x position in image grid
- y position in image grid
- red color component
- green color component
- blue color component

When extracting dominant colors we are only interested in the three color dimensions.

![alt tag](http://www.pixelogik.de/static/images/articles/local-maxima-in-color-histogram/colorcube_scan_1.jpg)

I figured that finding dominant colors is nothing but looking for local maxima in the density distribution of the color space. To model the density a 3d histogram is used, that is a 3d grid, in each axis going from 0 to 1, here visualized in 2d (green crosss are image pixel):

![alt tag](http://www.pixelogik.de/static/images/articles/local-maxima-in-color-histogram/colorcube_scan_2.jpg)

After projecting all pixels into individual cells of the grid, local maxima are found by checking differences in density to all neighbours cells. If all neighbours of a cell have a lower density ("hit count" = "pixels in that cell"), then the particular cell is a local maximum:

![alt tag](http://www.pixelogik.de/static/images/articles/local-maxima-in-color-histogram/colorcube_scan_3.jpg)

Finally the detected local maxima are ordered by density ("hit count") and for each the average color of the pixels within is computed. This results in an array of colors with the first color being the most dominant in the image.

With some images this results in many colors. Sometimes you only want distinct colors. If that option is used the algorithm makes sure that no color in the result set is too close to any of the other colors:

![alt tag](http://www.pixelogik.de/static/images/articles/local-maxima-in-color-histogram/colorcube_scan_4.jpg)
