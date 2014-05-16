//
//  CCTableViewCell.m
//  ColorCube
//
//  Created by Ole Krause-Sparmann on 16.05.14.
//  Copyright (c) 2014 Ole Krause-Sparmann. All rights reserved.
//

#import "CCTableViewCell.h"

@implementation CCTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
