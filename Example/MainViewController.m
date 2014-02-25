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
    [self.mediaFocusManager installOnViews:self.imageViews];
    
    [self addSomeRandomTransformOnThumbnailViews];
}

- (NSUInteger)supportedInterfaceOrientations
{
    //return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
     return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

#pragma mark - ASMediaFocusDelegate
- (UIImage *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager imageForView:(UIView *)view
{
    return ((UIImageView *)view).image;
}

- (CGRect)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager finalFrameforView:(UIView *)view
{
    return self.view.bounds;
}

- (UIViewController *)parentViewControllerForMediaFocusManager:(ASMediaFocusManager *)mediaFocusManager
{
    return self;
}

- (NSURL *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager mediaURLForView:(UIView *)view
{
    NSString *path;
    NSString *name;
    NSInteger index;
    NSURL *url;
    
    if(self.tableView == nil)
    {
        index = ([self.imageViews indexOfObject:view] + 1);
    }
    else
    {
        index = view.tag;
    }
    
    // Here, images are accessed through their name "1f.jpg", "2f.jpg", …
    name = [NSString stringWithFormat:@"%df", index];
    path = [[NSBundle mainBundle] pathForResource:name ofType:@"jpg"];
    
    url = [NSURL fileURLWithPath:path];
    
    return url;
}

- (NSString *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager titleForView:(UIView *)view;
{
    NSString *title;
    
    title = [NSString stringWithFormat:@"Image %@", [self mediaFocusManager:mediaFocusManager mediaURLForView:view].lastPathComponent];
    
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
        [self.mediaFocusManager installOnView:cell.imageView];
    }
    
    path = [NSString stringWithFormat:@"%d.jpg", indexPath.row + 1];
    image = [UIImage imageNamed:path];
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
@end
