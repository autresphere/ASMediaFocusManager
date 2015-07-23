//
//  MainViewController.m
//  ASMediaFocusExample
//
//  Created by Philippe Converset on 21/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import "MainViewController.h"
#import "MediaCell.h"
#import "NSURL+ASMediaFocusManager.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const kMaxAngle = 0.1;
static CGFloat const kMaxOffset = 20;

@interface MainViewController ()
@property (nonatomic, assign) BOOL statusBarHidden;
@property (nonatomic, strong) NSArray *mediaInfoItems;
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

    self.mediaInfoItems = @[[self mediaInfoForName:@"1f.jpg" image:[UIImage imageNamed:@"1.jpg"]],
                            [self mediaInfoForName:@"2f.jpg" image:[UIImage imageNamed:@"2.jpg"]],
                            [self mediaInfoForName:@"3f.mp4" image:[UIImage imageNamed:@"3.jpg"]],
                            [self mediaInfoForName:@"4f.jpg" image:[UIImage imageNamed:@"4.jpg"]],
                            ];
    self.mediaFocusManager = [[ASMediaFocusManager alloc] init];
    self.mediaFocusManager.delegate = self;
    self.mediaFocusManager.elasticAnimation = YES;
    self.mediaFocusManager.focusOnPinch = YES;

    // Tells which views need to be focusable. You can put your image views in an array and give it to the focus manager.
    [self.mediaFocusManager installOnViews:self.imageViews];
    
    [self addSomeRandomTransformOnThumbnailViews];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;// | UIInterfaceOrientationMaskPortraitUpsideDown;
//     return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

#pragma mark - ASMediaFocusDelegate

- (UIViewController *)parentViewControllerForMediaFocusManager:(ASMediaFocusManager *)mediaFocusManager
{
    return self;
}

- (ASMediaInfo *)mediaInfoForName:(NSString *)name image:(UIImage *)image
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:[name stringByDeletingPathExtension] withExtension:name.pathExtension];

    NSString *title = (url.as_isVideoURL ? @"Videos are also supported." : @"Of course, you can zoom in and out on the image.");

    ASMediaInfo *info = [[ASMediaInfo alloc] initWithURL:url initialImage:image title:title];

    return info;
}

- (ASMediaInfo *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager mediaInfoForView:(UIView *)view
{
    NSInteger index;

    if(self.tableView == nil)
    {
        index = ([self.imageViews indexOfObject:view]);
    }
    else
    {
        index = view.tag - 1;
    }

    return self.mediaInfoItems[index];
}

- (NSArray *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager mediaInfoListForView:(UIView *)view
{
    return self.mediaInfoItems;
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

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"MediaCell";
    MediaCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if(cell == nil)
    {
        cell = [MediaCell mediaCell];
        cell.thumbnailView.tag = indexPath.row + 1;
        [self.mediaFocusManager installOnView:cell.thumbnailView];
    }

    ASMediaInfo *info = self.mediaInfoItems[indexPath.row];

    cell.playView.hidden = !info.mediaURL.as_isVideoURL;
    cell.thumbnailView.image = info.initialImage;
    cell.thumbnailView.tag = indexPath.row + 1;
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.mediaInfoItems.count;
}
@end
