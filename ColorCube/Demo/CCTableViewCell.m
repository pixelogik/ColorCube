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

#import "CCTableViewCell.h"

#import "CCImageColors.h"

@interface CCTableViewCell ()

@property (strong, nonatomic) UIView *colorView1;
@property (strong, nonatomic) UIView *colorView2;
@property (strong, nonatomic) UIView *colorView3;
@property (strong, nonatomic) UIView *colorView4;

@property (strong, nonatomic) UIImageView *bigImageView;

@end

@implementation CCTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _colorView1 = [[UIView alloc] initWithFrame:CGRectZero];
        _colorView2 = [[UIView alloc] initWithFrame:CGRectZero];
        _colorView3 = [[UIView alloc] initWithFrame:CGRectZero];
        _colorView4 = [[UIView alloc] initWithFrame:CGRectZero];
        
        _bigImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _bigImageView.contentMode = UIViewContentModeScaleToFill;
        
        [self.contentView addSubview:_colorView1];
        [self.contentView addSubview:_colorView2];
        [self.contentView addSubview:_colorView3];
        [self.contentView addSubview:_colorView4];
        [self.contentView addSubview:_bigImageView];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
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

- (void)layoutSubviews
{
    _bigImageView.frame = CGRectMake(0, 0, 160, 160);
    _colorView1.frame = CGRectMake(160, 0, 80, 80);
    _colorView2.frame = CGRectMake(160, 80, 80, 80);
    _colorView3.frame = CGRectMake(160+80, 0, 80, 80);
    _colorView4.frame = CGRectMake(160+80, 80, 80, 80);
}

- (void)fillWithColors:(CCImageColors *)colors
{
    _colorView1.backgroundColor = colors.color1;
    _colorView2.backgroundColor = colors.color2;
    _colorView3.backgroundColor = colors.color3;
    _colorView4.backgroundColor = colors.color4;
}

- (void)fillWithImage:(UIImage*)image
{
    _bigImageView.image = image;
}

@end
