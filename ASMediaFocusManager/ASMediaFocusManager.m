//
//  ASMediaFocusManager.m
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 11/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import "ASMediaFocusManager.h"
#import "ASMediaFocusController.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const kAnimateElasticSizeRatio = 0.03;
static CGFloat const kAnimateElasticDurationRatio = 0.6;
static CGFloat const kAnimateElasticSecondMoveSizeRatio = 0.5;
static CGFloat const kAnimateElasticThirdMoveSizeRatio = 0.2;
static CGFloat const kAnimationDuration = 0.5;

@interface ASMediaFocusManager ()
// The media view being focused.
@property (nonatomic, strong) ASMediaFocusController *focusViewController;
@property (nonatomic, strong) ASMediaFocusController *pendingFocusViewController;
@property (nonatomic) BOOL isZooming;
@end

@implementation ASMediaFocusManager

// Taken from https://github.com/rs/SDWebImage/blob/master/SDWebImage/SDWebImageDecoder.m
- (UIImage *)decodedImageWithImage:(UIImage *)image
{
    if (image.images) {
        // Do not decode animated images
        return image;
    }
    
    CGImageRef imageRef = image.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGRect imageRect = (CGRect){.origin = CGPointZero, .size = imageSize};
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
    
    // CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.
    // https://developer.apple.com/library/mac/#qa/qa1037/_index.html
    if (infoMask == kCGImageAlphaNone && CGColorSpaceGetNumberOfComponents(colorSpace) > 1) {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        
        // Set noneSkipFirst.
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    }
    // Some PNGs tell us they have alpha but only 3 components. Odd.
    else if (!anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3) {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    }
    
    // It calculates the bytes-per-row based on the bitsPerComponent and width arguments.
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 imageSize.width,
                                                 imageSize.height,
                                                 CGImageGetBitsPerComponent(imageRef),
                                                 0,
                                                 colorSpace,
                                                 bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    
    // If failed, return undecompressed image
    if (!context) return image;
    
    CGContextDrawImage(context, imageRect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        self.animationDuration = kAnimationDuration;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        self.elasticAnimation = YES;
        self.zoomEnabled = YES;
        self.isZooming = NO;
        self.gestureDisabledDuringZooming = YES;
        self.isDefocusingWithTap = YES;
    }
    
    return self;
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
    UITapGestureRecognizer *tapGesture;
    
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleFocusGesture:)];
    [view addGestureRecognizer:tapGesture];
    view.userInteractionEnabled = YES;
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
        else
        {
            [self setupAccessoryViewOnFocusViewController:self.focusViewController];
        }
    }
}

- (ASMediaFocusController *)focusViewControllerForView:(UIView *)mediaView
{
    ASMediaFocusController *viewController;
    UIImage *image;
    
    image = [self.delegate mediaFocusManager:self imageForView:mediaView];
    if(image == nil)
        return nil;
    
    viewController = [[ASMediaFocusController alloc] initWithNibName:nil bundle:nil];
    [self installDefocusActionOnFocusViewController:viewController];
    viewController.mediaView = mediaView;
    viewController.titleLabel.text = [self.delegate mediaFocusManager:self titleForView:mediaView];
    viewController.mainImageView.image = image;
    [viewController.mainImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __block UIImage *image;
        if ([self.delegate respondsToSelector:@selector(mediaFocusManager:mediaURLForView:)]) {
            
            NSError *error = nil;
            NSURL *url = [self.delegate mediaFocusManager:self mediaURLForView:mediaView];
            NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
            
            if(error != nil) {
                NSLog(@"Warning: Unable to load image at %@. %@", url, error);
            } else {
                image = [[UIImage alloc] initWithData:data];
            }
            
            image = [self decodedImageWithImage:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                viewController.mainImageView.image = image;
                
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                image = [self.delegate mediaFocusManager:self fullMediaForView:mediaView];
                image = [self decodedImageWithImage:image];
                viewController.mainImageView.image = image;
            });
        }
    });
    
    return viewController;
}

- (CGRect)rectInsetsForRect:(CGRect)frame ratio:(CGFloat)ratio
{
    CGFloat dx;
    CGFloat dy;
    
    dx = frame.size.width*ratio;
    dy = frame.size.height*ratio;
    
    return CGRectInset(frame, dx, dy);
}

- (void)installZoomView
{
    if(self.zoomEnabled)
    {
        [self.focusViewController installZoomView];
    }
}

- (void)uninstallZoomView
{
    if(self.zoomEnabled)
    {
        [self.focusViewController uninstallZoomView];
    }
    [self.focusViewController pinAccessoryView];
}

- (void)setupAccessoryViewOnFocusViewController:(ASMediaFocusController *)focusViewController
{
    UIButton *doneButton;
    
    doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [doneButton setTitle:NSLocalizedString(@"Done", @"Done") forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(handleDefocusGesture:) forControlEvents:UIControlEventTouchUpInside];
    doneButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [doneButton sizeToFit];
    doneButton.frame = CGRectInset(doneButton.frame, -20, -4);
    doneButton.layer.borderWidth = 2;
    doneButton.layer.cornerRadius = 4;
    doneButton.layer.borderColor = [UIColor whiteColor].CGColor;
    doneButton.center = CGPointMake(focusViewController.accessoryView.bounds.size.width - doneButton.bounds.size.width/2 - 10, doneButton.bounds.size.height/2 + 10);
    doneButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.pageViewController.view addSubview:doneButton];
}

- (void)createPageViewControllerForFocusViewController:(ASMediaFocusController *)focusVC
{
    [self cleanPageController];
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
    [self.pageViewController setViewControllers:@[focusVC]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
    
    UIViewController *parentViewController = [self.delegate parentViewControllerForMediaFocusManager:self];
    [parentViewController addChildViewController:self.pageViewController];
    [parentViewController.view addSubview:self.pageViewController.view];
    self.pageViewController.view.frame = parentViewController.view.bounds;
    [self.pageViewController setDelegate:self];
    [self.pageViewController setDataSource:self];
    [self.pageViewController didMoveToParentViewController:parentViewController];
}

- (void)cleanPageController
{
    [self.pageViewController.view removeFromSuperview];
    [self.pageViewController removeFromParentViewController];
    [self.pageViewController setDelegate:nil];
    [self.pageViewController setDataSource:nil];
    self.pageViewController = nil;
}

#pragma mark - Gestures
- (void)handleFocusGesture:(UIGestureRecognizer *)gesture
{
    ASMediaFocusController *focusViewController;
    CGPoint center;
    UIView *mediaView;
    UIView *imageView;
    NSTimeInterval duration;
    
    mediaView = gesture.view;
    focusViewController = [self focusViewControllerForView:mediaView];
    
    if (focusViewController == nil) {
        return;
    }
    [self createPageViewControllerForFocusViewController:focusViewController];
    self.focusViewController = focusViewController;
    
    imageView = focusViewController.mainImageView;
    center = [imageView.superview convertPoint:mediaView.center fromView:mediaView.superview];
    imageView.center = center;
    imageView.transform = mediaView.transform;
    imageView.bounds = mediaView.bounds;
    
    self.isZooming = YES;
    
    duration = (self.elasticAnimation?self.animationDuration*(1-kAnimateElasticDurationRatio):self.animationDuration);
    [UIView animateWithDuration:duration
                     animations:^{
                         CGRect frame;
                         CGRect initialFrame;
                         CGAffineTransform initialTransform;
                         
                         if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerWillAppear:)])
                         {
                             [self.delegate mediaFocusManagerWillAppear:self];
                         }
                         
                         frame = [self.delegate mediaFocusManager:self finalFrameforView:mediaView];
                         frame = (self.elasticAnimation?[self rectInsetsForRect:frame ratio:-kAnimateElasticSizeRatio]:frame);
                         
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
                         [focusViewController updateOrientationAnimated:NO];
                         // This is the final image frame. No transform.
                         frame = imageView.frame;
                         // It must now be animated from its initial frame and transform.
                         imageView.frame = initialFrame;
                         imageView.transform = initialTransform;
                         imageView.transform = CGAffineTransformIdentity;
                         imageView.frame = frame;
                         focusViewController.view.backgroundColor = self.backgroundColor;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                          animations:^{
                                              CGRect frame;
                                              
                                              frame = focusViewController.contentView.bounds;
                                              frame = (self.elasticAnimation?[self rectInsetsForRect:frame ratio:kAnimateElasticSizeRatio*kAnimateElasticSecondMoveSizeRatio]:frame);
                                              imageView.frame = frame;
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                                               animations:^{
                                                                   CGRect frame;
                                                                   
                                                                   frame = focusViewController.contentView.bounds;
                                                                   frame = (self.elasticAnimation?[self rectInsetsForRect:frame ratio:-kAnimateElasticSizeRatio*kAnimateElasticThirdMoveSizeRatio]:frame);
                                                                   imageView.frame = frame;
                                                               }
                                                               completion:^(BOOL finished) {
                                                                   [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                                                                    animations:^{
                                                                                        imageView.frame = focusViewController.contentView.bounds;
                                                                                    }
                                                                                    completion:^(BOOL finished) {
                                                                                        [self installZoomView];
                                                                                        [self.focusViewController showAccessoryView:YES];
                                                                                        
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

- (void)handleDefocusGesture:(UIGestureRecognizer *)gesture
{
    NSTimeInterval duration;
    
    if(self.isZooming && self.gestureDisabledDuringZooming)
        return;
    
    UIView *contentView;
    CGRect __block bounds;
    
    [self uninstallZoomView];
    
    contentView = self.focusViewController.mainImageView;
    duration = (self.elasticAnimation?self.animationDuration*(1-kAnimateElasticDurationRatio):self.animationDuration);
    [UIView animateWithDuration:duration
                     animations:^{
                         if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerWillDisappear:)])
                         {
                             [self.delegate mediaFocusManagerWillDisappear:self];
                         }
                         
                         self.focusViewController.contentView.transform = CGAffineTransformIdentity;
                         contentView.center = [contentView.superview convertPoint:self.focusViewController.mediaView.center fromView:self.focusViewController.mediaView.superview];
                         contentView.transform = self.focusViewController.mediaView.transform;
                         bounds = self.focusViewController.mediaView.bounds;
                         contentView.bounds = (self.elasticAnimation?[self rectInsetsForRect:bounds ratio:kAnimateElasticSizeRatio]:bounds);
                         self.focusViewController.view.backgroundColor = [UIColor clearColor];
                         self.focusViewController.accessoryView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                          animations:^{
                                              CGRect frame;
                                              
                                              frame = bounds;
                                              frame = (self.elasticAnimation?[self rectInsetsForRect:frame ratio:-kAnimateElasticSizeRatio*kAnimateElasticSecondMoveSizeRatio]:frame);
                                              contentView.bounds = frame;
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                                               animations:^{
                                                                   CGRect frame;
                                                                   
                                                                   frame = bounds;
                                                                   frame = (self.elasticAnimation?[self rectInsetsForRect:frame ratio:kAnimateElasticSizeRatio*kAnimateElasticThirdMoveSizeRatio]:frame);
                                                                   contentView.bounds = frame;
                                                               }
                                                               completion:^(BOOL finished) {
                                                                   [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                                                                    animations:^{
                                                                                        contentView.bounds = bounds;
                                                                                    }
                                                                                    completion:^(BOOL finished) {
                                                                                        self.focusViewController.mediaView.hidden = NO;
                                                                                        [self cleanPageController];
                                                                                        
                                                                                        if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerDidDisappear:)])
                                                                                        {
                                                                                            [self.delegate mediaFocusManagerDidDisappear:self];
                                                                                        }
                                                                                    }];
                                                               }];
                                          }];
                     }];
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if ([self.delegate respondsToSelector:@selector(mediaFocusManager:previousViewFromView:)]) {
        UIView *mediaView = ((ASMediaFocusController*) viewController).mediaView;
        UIView *nextMediaView = [self.delegate mediaFocusManager:self previousViewFromView:mediaView];
        if (nextMediaView) {
            ASMediaFocusController *focusViewController = [self focusViewControllerForView:nextMediaView];
            return focusViewController;
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if ([self.delegate respondsToSelector:@selector(mediaFocusManager:nextViewFromView:)]) {
        UIView *mediaView = ((ASMediaFocusController*) viewController).mediaView;
        UIView *nextMediaView = [self.delegate mediaFocusManager:self nextViewFromView:mediaView];
        if (nextMediaView) {
            ASMediaFocusController *focusViewController = [self focusViewControllerForView:nextMediaView];
            return focusViewController;
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    self.pendingFocusViewController = [pendingViewControllers firstObject];
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    if (completed) {
        self.focusViewController = self.pendingFocusViewController;
    }
    
    self.pendingFocusViewController = nil;
}

@end
