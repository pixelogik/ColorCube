//
//  CCImageColors.m
//  ColorCube
//
//  Created by Ole Krause-Sparmann on 16.05.14.
//  Copyright (c) 2014 Ole Krause-Sparmann. All rights reserved.
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
