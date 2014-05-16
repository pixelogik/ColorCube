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

#import "CCViewController.h"

#import "CCColorCube.h"
#import "CCTableViewCell.h"
#import "CCImageColors.h"

@interface CCViewController ()

@property (strong, nonatomic) CCColorCube *colorCube;

@property (strong, nonatomic) NSArray *images;
@property (strong, nonatomic) NSArray *imageColors;

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) UISegmentedControl *segmented;

- (void)segmentedChanged:(id)sender;
- (void)computeImageColorsWithMode:(NSUInteger)mode;

@end

@implementation CCViewController

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [_tableView registerClass:[CCTableViewCell class] forCellReuseIdentifier:@"CCTableViewCell"];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
    
    _segmented = [[UISegmentedControl alloc] initWithItems:@[@"Bright", @"Bright -white", @"Bright -blue"]];
    [_segmented addTarget:self action:@selector(segmentedChanged:) forControlEvents:UIControlEventValueChanged];
    _segmented.selectedSegmentIndex = 0;
    [self.view addSubview:_segmented];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _colorCube = [[CCColorCube alloc] init];
    
    NSArray *imgNames = @[
                          @"schnee.jpg",
                          @"berlin.jpg",
                          @"markt.jpg",
                          @"melone.jpg",
                          @"xberg.jpg",
                          @"glotze.jpg",
                          @"streetart.jpg",
                          @"club.jpg",
                          @"museum.jpg",
                          @"strand.jpg"
                          ];

    _images = [NSArray array];
    for (NSString *imgName in imgNames) {
        _images = [_images arrayByAddingObject:[UIImage imageNamed:imgName]];
    }
    
    [self computeImageColorsWithMode:0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGSize s = self.view.bounds.size;
    
    _segmented.frame = CGRectMake(0, s.height-50, s.width, 50);
    _tableView.frame = CGRectMake(0, 0, s.width, s.height-50);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _images.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get cell from layout
    CCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CCTableViewCell" forIndexPath:indexPath];

    // Tell cell about image
    [cell fillWithImage:_images[indexPath.row]];

    // Tell cell about image colors
    if (_imageColors) {
        [cell fillWithColors:_imageColors[indexPath.row]];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 160;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 160;
}

#pragma mark - Color extraction 

- (void)computeImageColorsWithMode:(NSUInteger)mode
{
    __weak CCViewController *wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSMutableArray *newColorsArray = [NSMutableArray array];
        
        // White (need to create with RGB components. [UIColor whiteColor] returns two component color (gray intensity & alpha)).
        UIColor *rgbWhite = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
        UIColor *rgbBlue  = [UIColor colorWithRed:0.3 green:0.3 blue:1 alpha:1];
        
        for (UIImage *image in _images) {
            NSArray *extractedColors = nil;
            
            // Extract colors (try to get four distinct)
            switch (mode) {
                case 0:
                    extractedColors = [_colorCube extractBrightColorsFromImage:image avoidColor:nil count:4];
                    break;
                case 1:
                    extractedColors = [_colorCube extractBrightColorsFromImage:image avoidColor:rgbWhite count:4];
                    break;
                case 2:
                    extractedColors = [_colorCube extractBrightColorsFromImage:image avoidColor:rgbBlue count:4];
                    break;
            }
            
            // Create object with definitly four colors
            CCImageColors *imageColors = [[CCImageColors alloc] initWithExtractedColors:extractedColors];
            // Add to array of new colors
            [newColorsArray addObject:imageColors];
        }
        
        // Set new color array on main thread and refresh table view
        dispatch_async(dispatch_get_main_queue(), ^{
            wself.imageColors = [NSArray arrayWithArray:newColorsArray];
            [wself.tableView reloadData];
            wself.segmented.enabled = YES;
        });
    });
    
}

#pragma mark - Button actions 

- (void)segmentedChanged:(id)sender
{
    _segmented.enabled = NO;
    [self computeImageColorsWithMode:_segmented.selectedSegmentIndex];
}

@end
