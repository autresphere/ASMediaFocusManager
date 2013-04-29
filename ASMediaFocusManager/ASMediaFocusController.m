//
//  ASMediaFocusViewController.m
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 21/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import "ASMediaFocusController.h"
#import <QuartzCore/QuartzCore.h>

static NSTimeInterval const kDefaultOrientationAnimationDuration = 0.4;

@interface ASMediaFocusController ()

@property (nonatomic, assign) UIDeviceOrientation previousOrientation;

@end

@implementation ASMediaFocusController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleLabel.layer.shadowOpacity = 1;
    self.titleLabel.layer.shadowOffset = CGSizeZero;
    self.titleLabel.layer.shadowRadius = 1;
}

- (void)viewDidUnload
{
    [self setMainImageView:nil];
    [self setContentView:nil];
    [super viewDidUnload];
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.titleLabel.alpha = 0;
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.titleLabel.alpha = 1;
                     }];
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
    }
}

#pragma mark - Public
- (void)updateOrientationAnimated:(BOOL)animated
{
    CGAffineTransform transform;
    CGRect frame;
    NSTimeInterval duration = kDefaultOrientationAnimationDuration;
    
    if([UIDevice currentDevice].orientation == self.previousOrientation)
        return;
    
    if((UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation) && UIInterfaceOrientationIsLandscape(self.previousOrientation))
       || (UIInterfaceOrientationIsPortrait([UIDevice currentDevice].orientation) && UIInterfaceOrientationIsPortrait(self.previousOrientation)))
    {
        duration *= 2;
    }
    
    if(([UIDevice currentDevice].orientation == UIInterfaceOrientationPortrait)
       || [self isParentSupportingInterfaceOrientation:[UIDevice currentDevice].orientation])
    {
        transform = CGAffineTransformIdentity;
    }
    else
    {
        switch ([UIDevice currentDevice].orientation)
        {
            case UIInterfaceOrientationLandscapeLeft:
                if(self.parentViewController.interfaceOrientation == UIInterfaceOrientationPortrait)
                {
                    transform = CGAffineTransformMakeRotation(-M_PI_2);
                }
                else
                {
                    transform = CGAffineTransformMakeRotation(M_PI_2);
                }
                break;
                
            case UIInterfaceOrientationLandscapeRight:
                if(self.parentViewController.interfaceOrientation == UIInterfaceOrientationPortrait)
                {
                    transform = CGAffineTransformMakeRotation(M_PI_2);
                }
                else
                {
                    transform = CGAffineTransformMakeRotation(-M_PI_2);
                }
                break;
                
            case UIInterfaceOrientationPortrait:
                transform = CGAffineTransformIdentity;
                break;
                
            case UIInterfaceOrientationPortraitUpsideDown:
                transform = CGAffineTransformMakeRotation(M_PI);
                break;
                
            case UIDeviceOrientationFaceDown:
            case UIDeviceOrientationFaceUp:
            case UIDeviceOrientationUnknown:
                return;
        }
    }
    
    if(animated)
    {
        frame = self.contentView.frame;
        [UIView animateWithDuration:duration
                         animations:^{
                             self.contentView.transform = transform;
                             self.contentView.frame = frame;
                         }];
    }
    else
    {
        frame = self.contentView.frame;
        self.contentView.transform = transform;
        self.contentView.frame = frame;
    }
    self.previousOrientation = [UIDevice currentDevice].orientation;
}

- (void)installZoomView
{
    ASImageScrollView *scrollView;
    
    scrollView = [[ASImageScrollView alloc] initWithFrame:self.contentView.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.scrollView = scrollView;
    [self.contentView insertSubview:scrollView atIndex:0];
    [scrollView displayImage:self.mainImageView.image];
    self.mainImageView.hidden = YES;
}

- (void)uninstallZoomView
{
    CGRect frame;
    
    frame = [self.contentView convertRect:self.scrollView.zoomImageView.frame fromView:self.scrollView];
    self.scrollView.hidden = YES;
    self.mainImageView.hidden = NO;
    self.mainImageView.frame = frame;
}

- (void)pinAccessoryView:(UIView *)view
{
    CGRect frame;
    
    frame = [self.view convertRect:view.frame fromView:view.superview];
    view.transform = view.superview.transform;
    [self.view addSubview:view];
    view.frame = frame;
}

- (void)pinAccessoryViews
{
    // Move the accessory views to the main view in order not to be rotated along with the media.
    [self pinAccessoryView:self.accessoryView];
    [self pinAccessoryView:self.titleLabel];
}

#pragma mark - Notifications
- (void)orientationDidChangeNotification:(NSNotification *)notification
{
    [self updateOrientationAnimated:YES];
}
@end
