//
//  MainViewController.m
//  ASMediaFocusExample
//
//  Created by Philippe Converset on 21/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import "MainViewController.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const kMaxAngle = 0.1;
static CGFloat const kMaxOffset = 20;

@interface MainViewController ()
@property (nonatomic, assign) BOOL statusBarHidden;
@property (nonatomic, strong) NSArray *medias;
@end

@implementation MainViewController

+ (float)randomFloatBetween:(float)smallNumber andMax:(float)bigNumber
{
    float diff = bigNumber - smallNumber;
    
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

- (void)addSomeRandomTransformOnThumbnailViews
{
    for(UIView *view in self.imageViews)
    {
        CGFloat angle;
        NSInteger offsetX;
        NSInteger offsetY;
        
        angle = [MainViewController randomFloatBetween:-kMaxAngle andMax:kMaxAngle];
        offsetX = (NSInteger)[MainViewController randomFloatBetween:-kMaxOffset andMax:kMaxOffset];
        offsetY = (NSInteger)[MainViewController randomFloatBetween:-kMaxOffset andMax:kMaxOffset];
        view.transform = CGAffineTransformMakeRotation(angle);
        view.center = CGPointMake(view.center.x + offsetX, view.center.y + offsetY);
        
        // This is going to avoid crispy edges.
        view.layer.shouldRasterize = YES;
        view.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.mediaFocusManager = [[ASMediaFocusManager alloc] init];
    self.mediaFocusManager.delegate = self;
    
    // Tells which views need to be focusable. You can put your image views in an array and give it to the focus manager.
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:4];
    
    for (NSInteger i = 0; i < 4; ++i) {
        NSString *path = [NSString stringWithFormat:@"%ld.jpg", i + 1];
        UIImage *image = [UIImage imageNamed:path];
        [images addObject:image];
    }
    
    self.medias = [NSArray arrayWithArray:images];
}

- (NSUInteger)supportedInterfaceOrientations
{
     return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

#pragma mark - ASMediaFocusDelegate
- (UIImageView *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager imageViewForIndex:(NSUInteger) index
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    UIImageView *imageView = cell.imageView;
    return imageView;
}

- (CGRect)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager finalFrameForIndex:(NSUInteger)index
{
    return self.view.bounds;
}

- (UIViewController *)parentViewControllerForMediaFocusManager:(ASMediaFocusManager *)mediaFocusManager
{
    return self;
}

- (id)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager mediaForIndex:(NSUInteger)index
{
    
#if 0
    id media = self.medias[index];
    return media;
#else
    NSString *name = [NSString stringWithFormat:@"%ldf", (long)index + 1];
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"jpg"];
    
    NSURL *url = [NSURL fileURLWithPath:path];
    
    return url;
#endif

}

- (NSString *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager titleForIndex:(NSUInteger) index
{
    NSString *title;
    
    id media = self.medias[index];
    if ([media respondsToSelector:@selector(lastPathComponent)]) {
        title = [NSString stringWithFormat:@"Image %@", [media lastPathComponent]];
    }
    
    return @"Of course, you can zoom in and out on the image.";
}

- (void)mediaFocusManagerWillAppear:(ASMediaFocusManager *)mediaFocusManager
{
    self.statusBarHidden = YES;
    if([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
    {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)mediaFocusManagerWillDisappear:(ASMediaFocusManager *)mediaFocusManager
{
    self.statusBarHidden = NO;
    if([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
    {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)mediaFocusManagerDidDisappear:(ASMediaFocusManager *)mediaFocusManager
{
    NSLog(@"The view has been dismissed");
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    NSString *path;
    UIImage *image;
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    path = [NSString stringWithFormat:@"%ld.jpg", indexPath.row + 1];
    image = [UIImage imageNamed:path];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.imageView.image = image;
    cell.imageView.tag = indexPath.row + 1;
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.mediaFocusManager startFocusingOnIndex:indexPath.row];
}
@end
