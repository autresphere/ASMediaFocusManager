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
    
    if(self.scrollView)
    {
        self.scrollView.contentSize = self.contentView.bounds.size;
    }

    self.mediaFocusManager = [[ASMediaFocusManager alloc] init];
    self.mediaFocusManager.delegate = self;
    // Tells which views need to be focusable. You can put your image views in an array and give it to the focus manager.
    [self.mediaFocusManager installOnViews:self.imageViews];
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
    
    // Here, images are accessed through their name "1f.jpg", "2f.jpg", …
    name = [NSString stringWithFormat:@"%df", ([self.imageViews indexOfObject:view] + 1)];
    path = [[NSBundle mainBundle] pathForResource:name ofType:@"jpg"];
    
    return path;
}

@end
