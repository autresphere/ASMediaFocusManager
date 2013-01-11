//
//  ASMediaThumbnailsViewController.m
//  ASMediaFocusExample
//
//  Created by Philippe Converset on 21/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import "ASMediaThumbnailsViewController.h"

@interface ASMediaThumbnailsViewController ()

@end

@implementation ASMediaThumbnailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.mediaFocusManager = [[ASMediaFocusManager alloc] init];
    self.mediaFocusManager.delegate = self;
    [self.mediaFocusManager installOnViews:self.imageViews];
    if(self.scrollView)
    {
        self.scrollView.contentSize = self.contentView.bounds.size;
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - ASMediaFocusDelegate
- (UIImage *)mediaFocusManager:(ASMediaFocusManager *)mediafocus imageForView:(UIView *)view
{
    return ((UIImageView *)view).image;
}

- (CGRect)mediaFocusManager:(ASMediaFocusManager *)mediafocus finalFrameforView:(UIView *)view
{
    return self.parentViewController.view.bounds;
}

- (UIViewController *)parentViewControllerForMediaFocusManager:(ASMediaFocusManager *)mediafocus
{
    return self.parentViewController;
}

- (NSString *)mediaFocusManager:(ASMediaFocusManager *)mediafocus mediaPathForView:(UIView *)view
{
    NSString *path;
    NSString *name;
    
    name = [NSString stringWithFormat:@"%df", ([self.imageViews indexOfObject:view] + 1)];
    path = [[NSBundle mainBundle] pathForResource:name ofType:@"jpg"];
    
    return path;
}

@end
