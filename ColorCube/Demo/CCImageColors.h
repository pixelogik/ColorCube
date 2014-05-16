//
//  CCImageColors.h
//  ColorCube
//
//  Created by Ole Krause-Sparmann on 16.05.14.
//  Copyright (c) 2014 Ole Krause-Sparmann. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCImageColors : NSObject

- (id)initWithExtractedColors:(NSArray *)colors;

@property (nonatomic, readonly) UIColor *color1;
@property (nonatomic, readonly) UIColor *color2;
@property (nonatomic, readonly) UIColor *color3;
@property (nonatomic, readonly) UIColor *color4;

@end
