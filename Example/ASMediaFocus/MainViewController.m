//
//  ViewController.m
//  ASMediaFocusExample
//
//  Created by Philippe Converset on 11/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import "MainViewController.h"
#import "ASMediaThumbnailsViewController.h"

@interface MainViewController ()
@property (nonatomic, strong) ASMediaThumbnailsViewController *thumbnailsViewController;
@end

@implementation MainViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.thumbnailsViewController = [[ASMediaThumbnailsViewController alloc] initWithNibName:nil bundle:nil];
    [self addChildViewController:self.thumbnailsViewController];
    [self.contentView addSubview:self.thumbnailsViewController.view];
    self.thumbnailsViewController.view.frame = self.contentView.bounds;
    self.view.clipsToBounds = NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    // return UIInterfaceOrientationMaskAll;
}
@end
