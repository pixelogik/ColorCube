//
//  CCViewController.m
//  ColorCube
//
//  Created by Ole Krause-Sparmann on 15.05.14.
//  Copyright (c) 2014 Ole Krause-Sparmann. All rights reserved.
//

#import "CCViewController.h"

#import "CCColorCube.h"

@interface CCViewController ()

@property (strong, nonatomic) CCColorCube *colorCube;

@end

@implementation CCViewController

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _colorCube = [[CCColorCube alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        UIImage *img = [UIImage imageNamed:@"test2.jpg"];
        NSArray *imgColors = [_colorCube extractColorsFromImage:img avoidColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1] count:4];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            for (UIColor *color in imgColors) {
                UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(0, 80+40*[imgColors indexOfObject:color], 320, 40)];
                colorView.layer.borderColor = [UIColor blackColor].CGColor;
                colorView.layer.borderWidth = 1;
                colorView.backgroundColor = color;
                [self.view addSubview:colorView];
            }
        });
    });
    
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
