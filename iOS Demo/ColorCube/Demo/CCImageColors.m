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

#import "CCImageColors.h"

@interface CCImageColors ()

@property (strong, nonatomic) UIColor *color1;
@property (strong, nonatomic) UIColor *color2;
@property (strong, nonatomic) UIColor *color3;
@property (strong, nonatomic) UIColor *color4;

@end

@implementation CCImageColors

- (id)initWithExtractedColors:(NSArray *)colors
{
    self = [super init];
    if (self) {
        _color1 = colors.count > 0 ? colors[0] : [UIColor blackColor];
        _color2 = colors.count > 1 ? colors[1] : _color1;
        _color3 = colors.count > 2 ? colors[2] : _color2;
        _color4 = colors.count > 3 ? colors[3] : _color3;
    }
    return self;
}

@end
