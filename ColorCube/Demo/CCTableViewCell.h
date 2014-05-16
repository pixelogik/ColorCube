//
//  CCTableViewCell.h
//  ColorCube
//
//  Created by Ole Krause-Sparmann on 16.05.14.
//  Copyright (c) 2014 Ole Krause-Sparmann. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CCImageColors;

@interface CCTableViewCell : UITableViewCell

- (void)fillWithColors:(CCImageColors *)colors;
- (void)fillWithImage:(UIImage*)image;

@end
