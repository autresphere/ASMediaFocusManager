//
//  ASRotatingMediaPageViewController.m
//  ASMediaFocusExemple
//
//  Created by Kevin Lundberg on 6/8/15.
//  Copyright (c) 2015 AutreSphere. All rights reserved.
//

#import "ASMediaRotatingViewController.h"

static NSTimeInterval const kDefaultOrientationAnimationDuration = 0.4;

@interface ASMediaRotatingViewController ()
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, assign) UIDeviceOrientation previousOrientation;
@end

@implementation ASMediaRotatingViewController

- (instancetype)initWithViewController:(UIViewController *)viewController
{
    self = [super init];
    if (self) {
        _viewController = viewController;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self addChildViewController:self.viewController];
    [self.view addSubview:self.viewController.view];
    self.viewController.view.frame = self.view.bounds;
    self.viewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.viewController didMoveToParentViewController:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)orientationDidChangeNotification:(NSNotification *)notification
{
    [self updateOrientationAnimated:YES];
}

- (void)updateOrientationAnimated:(BOOL)animated
{
    CGAffineTransform transform;
    CGRect frame;
    NSTimeInterval duration = kDefaultOrientationAnimationDuration;

    if([UIDevice currentDevice].orientation == self.previousOrientation)
        return;

    if((UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) && UIDeviceOrientationIsLandscape(self.previousOrientation))
       || (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation) && UIDeviceOrientationIsPortrait(self.previousOrientation)))
    {
        duration *= 2;
    }

    if(([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait)
       || [self isParentSupportingInterfaceOrientation:(UIInterfaceOrientation)[UIDevice currentDevice].orientation])
    {
        transform = CGAffineTransformIdentity;
    }
    else
    {
        switch ([UIDevice currentDevice].orientation)
        {
            case UIDeviceOrientationLandscapeRight:
                if(self.parentViewController.interfaceOrientation == UIInterfaceOrientationPortrait)
                {
                    transform = CGAffineTransformMakeRotation(-M_PI_2);
                }
                else
                {
                    transform = CGAffineTransformMakeRotation(M_PI_2);
                }
                break;

            case UIDeviceOrientationLandscapeLeft:
                if(self.parentViewController.interfaceOrientation == UIInterfaceOrientationPortrait)
                {
                    transform = CGAffineTransformMakeRotation(M_PI_2);
                }
                else
                {
                    transform = CGAffineTransformMakeRotation(-M_PI_2);
                }
                break;

            case UIDeviceOrientationPortrait:
                transform = CGAffineTransformIdentity;
                break;

            case UIDeviceOrientationPortraitUpsideDown:
                transform = CGAffineTransformMakeRotation(M_PI);
                break;

            case UIDeviceOrientationFaceDown:
            case UIDeviceOrientationFaceUp:
            case UIDeviceOrientationUnknown:
                return;
        }
    }

    frame = self.viewController.view.frame;
    [UIView animateWithDuration:(animated ? duration : 0)
                     animations:^{
                         self.viewController.view.transform = transform;
                         self.viewController.view.frame = frame;
                     }];

    self.previousOrientation = [UIDevice currentDevice].orientation;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)isParentSupportingInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    switch(toInterfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskPortrait;

        case UIInterfaceOrientationPortraitUpsideDown:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskPortraitUpsideDown;

        case UIInterfaceOrientationLandscapeLeft:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskLandscapeLeft;

        case UIInterfaceOrientationLandscapeRight:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskLandscapeRight;

        case UIInterfaceOrientationUnknown:
            return YES;
    }
}

@end
