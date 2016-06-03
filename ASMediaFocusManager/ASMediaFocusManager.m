//
//  ASMediaFocusManager.m
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 11/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import "ASMediaFocusManager.h"
#import "ASMediaFocusController.h"
#import "ASMediaInfo.h"
#import "ASVideoBehavior.h"
#import "ASMediaRotatingViewController.h"
#import "UIImage+ASMediaFocusManager.h"
#import "NSURL+ASMediaFocusManager.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const kAnimateElasticSizeRatio = 0.03;
static CGFloat const kAnimateElasticDurationRatio = 0.6;
static CGFloat const kAnimateElasticSecondMoveSizeRatio = 0.5;
static CGFloat const kAnimateElasticThirdMoveSizeRatio = 0.2;
static CGFloat const kAnimationDuration = 0.5;
static CGFloat const kSwipeOffset = 100;

@interface ASMediaFocusManager () <UIGestureRecognizerDelegate, UIPageViewControllerDataSource, UIPageViewControllerDelegate, ASMediaFocusControllerDelegate>
// The media view being focused.
@property (nonatomic, strong) UIView *mediaView;
@property (nonatomic, strong, readonly) ASMediaFocusController *focusViewController;
@property (nonatomic, copy) NSArray *mediaInfoItems;

@property (nonatomic, strong) ASMediaRotatingViewController *rotatingViewController;
@property (nonatomic, strong) UIPageViewController *mediaPageViewController;
@property (nonatomic, assign) BOOL isZooming;
@property (nonatomic, strong) ASVideoBehavior *videoBehavior;
@property (nonatomic, strong) UIButton *doneButton;
@end

@implementation ASMediaFocusManager

- (id)init
{
    self = [super init];
    if(self)
    {
        self.animationDuration = kAnimationDuration;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        self.defocusOnVerticalSwipe = YES;
        self.elasticAnimation = YES;
        self.zoomEnabled = YES;
        self.isZooming = NO;
        self.focusOnPinch = NO;
        self.gestureDisabledDuringZooming = YES;
        self.isDefocusingWithTap = NO;
        self.addPlayIconOnVideo = YES;
        self.videoBehavior = [ASVideoBehavior new];
    }
    
    return self;
}

- (ASMediaFocusManager *)focusViewController
{
    return self.mediaPageViewController.viewControllers.firstObject;
}

- (void)installOnViews:(NSArray *)views
{
    for(UIView *view in views)
    {
        [self installOnView:view];
    }
}

- (void)installOnView:(UIView *)view
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleFocusGesture:)];
    [view addGestureRecognizer:tapGesture];
    view.userInteractionEnabled = YES;

    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchFocusGesture:)];
    pinchRecognizer.delegate = self;
    [view addGestureRecognizer:pinchRecognizer];

    ASMediaInfo *info = [self.delegate mediaFocusManager:self mediaInfoForView:view];

    if(self.addPlayIconOnVideo && info.mediaURL.as_isVideoURL)
    {
        [self.videoBehavior addVideoIconToView:view image:self.playImage];
    }
}

- (void)installDefocusActionOnFocusViewController:(ASMediaFocusController *)focusViewController
{
    // We need the view to be loaded.
    if(focusViewController.view)
    {
        if(self.isDefocusingWithTap)
        {
            UITapGestureRecognizer *tapGesture;
            
            tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDefocusGesture:)];
            [tapGesture requireGestureRecognizerToFail:focusViewController.doubleTapGesture];
            [focusViewController.view addGestureRecognizer:tapGesture];
        }
    }
}

- (void)addDoneButton
{
    [self.doneButton removeFromSuperview];

    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.doneButton setTitle:NSLocalizedString(@"Done", @"Done") forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(handleDefocusGesture:) forControlEvents:UIControlEventTouchUpInside];
    self.doneButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self.doneButton sizeToFit];
    self.doneButton.frame = CGRectInset(self.doneButton.frame, -20, -4);
    self.doneButton.layer.borderWidth = 2;
    self.doneButton.layer.cornerRadius = 4;
    self.doneButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.doneButton.center = CGPointMake(self.mediaPageViewController.view.bounds.size.width - self.doneButton.bounds.size.width/2 - 10, self.doneButton.bounds.size.height/2 + 20);
    self.doneButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.mediaPageViewController.view addSubview:self.doneButton];
}

#pragma mark - Utilities

- (CGRect)rectInsetsForRect:(CGRect)frame ratio:(CGFloat)ratio
{
    CGFloat dx;
    CGFloat dy;
    CGRect resultFrame;
    
    dx = frame.size.width*ratio;
    dy = frame.size.height*ratio;
    resultFrame = CGRectInset(frame, dx, dy);
    resultFrame = CGRectMake(round(resultFrame.origin.x), round(resultFrame.origin.y), round(resultFrame.size.width), round(resultFrame.size.height));
    
    return resultFrame;
}

- (CGSize)sizeThatFitsInSize:(CGSize)boundingSize initialSize:(CGSize)initialSize
{
    // Compute the final size that fits in boundingSize in order to keep aspect ratio from initialSize.
    CGSize fittingSize;
    CGFloat widthRatio;
    CGFloat heightRatio;
    
    widthRatio = boundingSize.width / initialSize.width;
    heightRatio = boundingSize.height / initialSize.height;
    
    if (widthRatio < heightRatio)
    {
        fittingSize = CGSizeMake(boundingSize.width, floorf(initialSize.height * widthRatio));
    }
    else
    {
        fittingSize = CGSizeMake(floorf(initialSize.width * heightRatio), boundingSize.height);
    }
    
    return fittingSize;
}

- (ASMediaFocusController *)focusViewControllerForView:(UIView *)mediaView mediaInfo:(ASMediaInfo *)mediaInfo
{
    if(mediaInfo.mediaURL == nil)
    {
        NSLog(@"Warning: url is nil");
        return nil;
    }

    UIImage *cachedImage = nil;
    if ([self.delegate respondsToSelector:@selector(mediaFocusManager:cachedImageForView:)]) {
        cachedImage = [self.delegate mediaFocusManager:self cachedImageForView:mediaView];
    }

    ASMediaFocusController *viewController = [[ASMediaFocusController alloc] initWithNibName:@"ASMediaFocusController" bundle:[NSBundle bundleForClass:[self class]]];
    viewController.delegate = self;
    [viewController setInfo:mediaInfo withCachedImage:cachedImage];

    if (self.defocusOnVerticalSwipe)
    {
        [self installSwipeGestureOnFocusViewController:viewController];
    }

    return viewController;
}

- (NSUInteger)currentlyVisibleMediaIndex
{
    ASMediaInfo *currentInfo = self.focusViewController.info;
    return [self.mediaInfoItems indexOfObject:currentInfo];
}

#pragma mark - Focus/Defocus
- (void)startFocusingView:(UIView *)mediaView
{
    UIViewController *parentViewController;
    ASMediaFocusController *focusViewController;
    CGPoint center;
    UIImageView *imageView;
    NSTimeInterval duration;
    CGRect finalImageFrame;
    __block CGRect untransformedFinalImageFrame;

    self.mediaPageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:@{UIPageViewControllerOptionInterPageSpacingKey: @10}];
    self.mediaPageViewController.dataSource = self;
    self.mediaPageViewController.delegate = self;

    if (!self.isDefocusingWithTap) {
        [self addDoneButton];
    }

    self.rotatingViewController = [[ASMediaRotatingViewController alloc] initWithViewController:self.mediaPageViewController];

    ASMediaInfo *mediaInfo = [self.delegate mediaFocusManager:self mediaInfoForView:mediaView];

    focusViewController = [self focusViewControllerForView:mediaView mediaInfo:mediaInfo];
    if(focusViewController == nil)
        return;

    [self.mediaPageViewController setViewControllers:@[focusViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];

    if ([self.delegate respondsToSelector:@selector(mediaFocusManager:mediaInfoListForView:)]) {
        NSArray *mediaInfoItems = [self.delegate mediaFocusManager:self mediaInfoListForView:mediaView];
        if ([mediaInfoItems indexOfObject:mediaInfo] == NSNotFound) {
            NSMutableArray *mutableItems = [mediaInfoItems mutableCopy];
            [mutableItems insertObject:mediaInfo atIndex:0];
            self.mediaInfoItems = mutableItems;
        } else {
            self.mediaInfoItems = mediaInfoItems;
        }
    } else {
        self.mediaInfoItems = @[mediaInfo];
    }

    // This should be called after swipe gesture is installed to make sure the nav bar doesn't hide before animation begins.
    if(self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerWillAppear:)])
    {
        [self.delegate mediaFocusManagerWillAppear:self];
    }
    
    self.mediaView = mediaView;
    parentViewController = [self.delegate parentViewControllerForMediaFocusManager:self];
    [parentViewController addChildViewController:self.rotatingViewController];
    [parentViewController.view addSubview:self.rotatingViewController.view];
    
    self.rotatingViewController.view.frame = parentViewController.view.bounds;
    mediaView.hidden = YES;
    
    imageView = focusViewController.mainImageView;
    center = [imageView.superview convertPoint:mediaView.center fromView:mediaView.superview];
    imageView.center = center;
    imageView.transform = mediaView.transform;
    imageView.bounds = mediaView.bounds;
    
    self.isZooming = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManager:finalFrameForView:)])
    {
        finalImageFrame = [self.delegate mediaFocusManager:self finalFrameForView:mediaView];
    }
    else
    {
        finalImageFrame = parentViewController.view.bounds;
    }
    
    if(imageView.contentMode == UIViewContentModeScaleAspectFill)
    {
        CGSize size;
        
        size = [self sizeThatFitsInSize:finalImageFrame.size initialSize:imageView.image.size];
        finalImageFrame.size = size;
        finalImageFrame.origin.x = (self.rotatingViewController.view.bounds.size.width - size.width)/2;
        finalImageFrame.origin.y = (self.rotatingViewController.view.bounds.size.height - size.height)/2;
    }
    
    [UIView animateWithDuration:self.animationDuration
                     animations:^{
                         self.rotatingViewController.view.backgroundColor = self.backgroundColor;
                         [focusViewController beginAppearanceTransition:YES animated:YES];
                     }];
    
    duration = (self.elasticAnimation?self.animationDuration*(1-kAnimateElasticDurationRatio):self.animationDuration);
    [UIView animateWithDuration:duration
                     animations:^{
                         CGRect frame;
                         CGRect initialFrame;
                         CGAffineTransform initialTransform;
                         
                         frame = finalImageFrame;
                         
                         // Trick to keep the right animation on the image frame.
                         // The image frame shoud animate from its current frame to a final frame.
                         // The final frame is computed by taking care of a possible rotation regarding the current device orientation, done by calling updateOrientationAnimated.
                         // As this method changes the image frame, it also replaces the current animation on the image view, which is not wanted.
                         // Thus to recreate the right animation, the image frame is set back to its inital frame then to its final frame.
                         // This very last frame operation recreates the right frame animation.
                         initialTransform = imageView.transform;
                         imageView.transform = CGAffineTransformIdentity;
                         initialFrame = imageView.frame;
                         imageView.frame = frame;
                         [self.rotatingViewController updateOrientationAnimated:NO];
                         // This is the final image frame. No transform.
                         untransformedFinalImageFrame = imageView.frame;
                         frame = (self.elasticAnimation?[self rectInsetsForRect:untransformedFinalImageFrame ratio:-kAnimateElasticSizeRatio]:untransformedFinalImageFrame);
                         // It must now be animated from its initial frame and transform.
                         imageView.frame = initialFrame;
                         imageView.transform = initialTransform;
                         [imageView.layer removeAllAnimations];
                         imageView.transform = CGAffineTransformIdentity;
                         imageView.frame = frame;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                          animations:^{
                                              CGRect frame;
                                              
                                              frame = untransformedFinalImageFrame;
                                              frame = (self.elasticAnimation?[self rectInsetsForRect:frame ratio:kAnimateElasticSizeRatio*kAnimateElasticSecondMoveSizeRatio]:frame);
                                              imageView.frame = frame;
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                                               animations:^{
                                                                   CGRect frame;
                                                                   
                                                                   frame = untransformedFinalImageFrame;
                                                                   frame = (self.elasticAnimation?[self rectInsetsForRect:frame ratio:-kAnimateElasticSizeRatio*kAnimateElasticThirdMoveSizeRatio]:frame);
                                                                   imageView.frame = frame;
                                                               }
                                                               completion:^(BOOL finished) {
                                                                   [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                                                                    animations:^{
                                                                                        imageView.frame = untransformedFinalImageFrame;
                                                                                    }
                                                                                    completion:^(BOOL finished) {
                                                                                        [focusViewController focusDidEndWithZoomEnabled:self.zoomEnabled];
                                                                                        [focusViewController playVideo];
                                                                                        self.isZooming = NO;
                                                                                        
                                                                                        if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerDidAppear:)])
                                                                                        {
                                                                                            [self.delegate mediaFocusManagerDidAppear:self];
                                                                                        }
                                                                                    }];
                                                               }];
                                          }];
                     }];
}

- (void)updateAnimatedView:(UIView *)view fromFrame:(CGRect)initialFrame toFrame:(CGRect)finalFrame
{
    // On iOS8 previous animations are not replaced when a new one is defined with the same key.
    // Instead the new animation is added a number suffix on its key.
    // To prevent from having additive animations, previous animations are removed.
    // Note: We don't want to remove all animations as there might be some opacity animation that must remain.
    [view.layer removeAnimationForKey:@"bounds.size"];
    [view.layer removeAnimationForKey:@"bounds.origin"];
    [view.layer removeAnimationForKey:@"position"];
    view.frame = initialFrame;
    [view.layer removeAnimationForKey:@"bounds.size"];
    [view.layer removeAnimationForKey:@"bounds.origin"];
    [view.layer removeAnimationForKey:@"position"];
    view.frame = finalFrame;
}

- (void)updateBoundsDuringAnimationWithElasticRatio:(CGFloat)ratio forFocusController:(ASMediaFocusController *)focusViewController
{
    CGRect frame;
    CGRect initialFrame;
    
    initialFrame = focusViewController.playerView.frame;
    frame = self.mediaView.bounds;
    frame = (self.elasticAnimation?[self rectInsetsForRect:frame ratio:ratio]:frame);
    focusViewController.mainImageView.bounds = frame;
    [self updateAnimatedView:focusViewController.playerView fromFrame:initialFrame toFrame:frame];
}

- (void)endFocusing
{
    NSTimeInterval duration;
    UIView *contentView;
    
    if(self.isZooming && self.gestureDisabledDuringZooming)
        return;
    
    contentView = self.focusViewController.mainImageView;
    if (contentView == nil)
        return;
    
    [self.focusViewController defocusWillStart];
    
    [UIView animateWithDuration:self.animationDuration
                     animations:^{
                         self.rotatingViewController.view.backgroundColor = [UIColor clearColor];
                     }];
    
    [UIView animateWithDuration:self.animationDuration/2
                     animations:^{
                         [self.focusViewController beginAppearanceTransition:NO animated:YES];
                     }];
    
    duration = (self.elasticAnimation?self.animationDuration*(1-kAnimateElasticDurationRatio):self.animationDuration);
    [UIView animateWithDuration:duration
                          delay:0
                        options:0
                     animations:^{

                         if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerWillDisappear:)])
                         {
                             [self.delegate mediaFocusManagerWillDisappear:self];
                         }

                         self.mediaPageViewController.view.transform = CGAffineTransformIdentity;
                         contentView.center = [contentView.superview convertPoint:self.mediaView.center fromView:self.mediaView.superview];
                         contentView.transform = self.mediaView.transform;
                         [self updateBoundsDuringAnimationWithElasticRatio:kAnimateElasticSizeRatio forFocusController:self.focusViewController];
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                          animations:^{
                                              [self updateBoundsDuringAnimationWithElasticRatio:-kAnimateElasticSizeRatio*kAnimateElasticSecondMoveSizeRatio forFocusController:self.focusViewController];
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                                               animations:^{
                                                                   [self updateBoundsDuringAnimationWithElasticRatio:kAnimateElasticSizeRatio*kAnimateElasticThirdMoveSizeRatio forFocusController:self.focusViewController];
                                                               }
                                                               completion:^(BOOL finished) {
                                                                   [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                                                                    animations:^{
                                                                                        [self updateBoundsDuringAnimationWithElasticRatio:0 forFocusController:self.focusViewController];
                                                                                    }
                                                                                    completion:^(BOOL finished) {
                                                                                        [self endFocusingFinished];
                                                                                    }];
                                                               }];
                                          }];
                     }];
}

- (void)endFocusingFinished
{
    self.mediaView.hidden = NO;
    [self.rotatingViewController.view removeFromSuperview];
    [self.rotatingViewController removeFromParentViewController];
    self.rotatingViewController = nil;
    self.mediaPageViewController = nil;

    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerDidDisappear:)])
    {
        [self.delegate mediaFocusManagerDidDisappear:self];
    }
}

#pragma mark - Gestures

- (void)handlePinchFocusGesture:(UIPinchGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan && !self.isZooming && gesture.scale > 1) {
        [self startFocusingView:gesture.view];
    }
}

- (void)handleFocusGesture:(UIGestureRecognizer *)gesture
{
    [self startFocusingView:gesture.view];
}

- (void)handleDefocusGesture:(UIGestureRecognizer *)gesture
{
    [self endFocusing];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        return self.focusOnPinch;
    }
    return YES;
}

#pragma mark - Dismiss on swipe

- (void)installSwipeGestureOnFocusViewController:(ASMediaFocusController *)focusViewController
{
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleDefocusBySwipeGesture:)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [focusViewController.view addGestureRecognizer:swipeGesture];

    swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleDefocusBySwipeGesture:)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
    [focusViewController.view addGestureRecognizer:swipeGesture];

    focusViewController.view.userInteractionEnabled = YES;
}

- (void)handleDefocusBySwipeGesture:(UISwipeGestureRecognizer *)gesture
{
    UIView *contentView;
    CGFloat offset;
    NSTimeInterval duration = self.animationDuration;
    
    [self.focusViewController defocusWillStart];
    offset = (gesture.direction == UISwipeGestureRecognizerDirectionUp?-kSwipeOffset:kSwipeOffset);
    contentView = self.focusViewController.mainImageView;
    
    [UIView animateWithDuration:duration
                     animations:^{
                         self.rotatingViewController.view.backgroundColor = [UIColor clearColor];
                     }];
    
    [UIView animateWithDuration:duration/2
                     animations:^{
                         [self.focusViewController beginAppearanceTransition:NO animated:YES];
                     }];
    
    [UIView animateWithDuration:0.4*duration
                     animations:^{
                         if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerWillDisappear:)])
                         {
                             [self.delegate mediaFocusManagerWillDisappear:self];
                         }
                         self.mediaPageViewController.view.transform = CGAffineTransformIdentity;
                         
                         contentView.center = CGPointMake(self.focusViewController.view.center.x, self.focusViewController.view.center.y + offset);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.6*duration
                                          animations:^{
                                              contentView.center = [contentView.superview convertPoint:self.mediaView.center fromView:self.mediaView.superview];
                                              contentView.transform = self.mediaView.transform;
                                              [self updateBoundsDuringAnimationWithElasticRatio:0 forFocusController:self.focusViewController];
                                           }
                                          completion:^(BOOL finished) {
                                              [self endFocusingFinished];
                                          }];
                     }];
}

#pragma mark - ASMediaFocusControllerDelegate

- (void)focusController:(ASMediaFocusController *)controller accessoryViewShown:(BOOL)visible
{
    CGFloat newAlpha = (visible ? 1 : 0);
    if (self.doneButton.alpha == newAlpha) {
        return;
    }

    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.doneButton.alpha = newAlpha;
                     }
                     completion:nil];
}

- (BOOL)focusController:(ASMediaFocusController *)controller shouldLoadMediaDirectly:(ASMediaInfo *)info
{
    if ([self.delegate respondsToSelector:@selector(mediaFocusManager:loadMediaForInfo:completion:)]) {
        return NO;
    } else {
        return YES;
    }
}

- (void)focusController:(ASMediaFocusController *)controller loadMedia:(ASMediaInfo *)info completion:(ASMediaLoadCompletion)completion
{
    [self.delegate mediaFocusManager:self loadMediaForInfo:info completion:completion];
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    ASMediaInfo *currentInfo = self.focusViewController.info;
    NSUInteger index = [self.mediaInfoItems indexOfObject:currentInfo];

    if (index == 0) {
        return nil;
    }

    ASMediaInfo *newInfo = self.mediaInfoItems[index - 1];

    ASMediaFocusController *controller = [self focusViewControllerForView:self.mediaView mediaInfo:newInfo];
    [controller focusDidEndWithZoomEnabled:self.zoomEnabled]; // sets up view for zooming
    return controller;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    ASMediaInfo *currentInfo = self.focusViewController.info;
    NSUInteger index = [self.mediaInfoItems indexOfObject:currentInfo];

    if (index >= self.mediaInfoItems.count - 1) {
        return nil;
    }

    ASMediaInfo *newInfo = self.mediaInfoItems[index + 1];

    ASMediaFocusController *controller = [self focusViewControllerForView:self.mediaView mediaInfo:newInfo];
    [controller focusDidEndWithZoomEnabled:self.zoomEnabled]; // sets up view for zooming
    return controller;
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    [self.focusViewController pauseVideo]; // pauses the current focus controller before transitioning
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed) {
        // This will hide/show the done button depending on the zoom level of the newly shown view controller.
        [self focusController:self.focusViewController accessoryViewShown:[self.focusViewController accessoryViewCanShow]];
        
        if ([self.delegate respondsToSelector:@selector(mediaFocusManager:didSwipeToMediaInfo:)]) {
            [self.delegate mediaFocusManager:self didSwipeToMediaInfo:self.focusViewController.info];
        }
    }
    [self.focusViewController playVideo]; // plays the current focus controller after transitioning (may be the one we were transitioning from if completed is false).
}

- (NSUInteger)pageViewControllerSupportedInterfaceOrientations:(UIPageViewController *)pageViewController
{
    return UIInterfaceOrientationMaskAll;
}

@end
