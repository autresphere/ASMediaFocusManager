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
static CGFloat const kSwipeOffset = 100;

@interface ASMediaFocusManager ()

// The media view being focused.
@property (nonatomic, strong) UIView *mediaReferenceView;
@property (nonatomic, strong) ASMediaFocusController *focusViewController;
@property (nonatomic, assign) BOOL isZooming;
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
        self.gestureDisabledDuringZooming = YES;
        self.isDefocusingWithTap = NO;
    }
    
    return self;
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
            [self setupAccessoryViewOnFocusViewController:focusViewController];
        }
    }
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
    doneButton.center = CGPointMake(focusViewController.accessoryView.bounds.size.width - doneButton.bounds.size.width/2 - 10, doneButton.bounds.size.height/2 + 20);
    doneButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [focusViewController.accessoryView addSubview:doneButton];
}

#pragma mark - Utilities
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

- (CGRect)rectInsetsForRect:(CGRect)frame ratio:(CGFloat)ratio
{
    CGFloat dx;
    CGFloat dy;
    
    dx = frame.size.width*ratio;
    dy = frame.size.height*ratio;
    
    return CGRectIntegral(CGRectInset(frame, dx, dy));
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

- (ASMediaFocusController *)focusViewControllerForIndex:(NSUInteger) index
{
    ASMediaFocusController *viewController;
    UIImage *image;
    UIImageView *imageView;
    
    imageView = [self.delegate mediaFocusManager:self imageViewForIndex:index];
    image = imageView.image;
    if((imageView == nil) || (image == nil))
        return nil;
    
    viewController = [[ASMediaFocusController alloc] initWithNibName:nil bundle:nil];
    [self installDefocusActionOnFocusViewController:viewController];
    
    [viewController setTitleString:[self.delegate mediaFocusManager:self titleForIndex:index]];
    viewController.mainImageView.image = image;
    viewController.mainImageView.contentMode = imageView.contentMode;
    
    if ([self.delegate respondsToSelector:@selector(mediaFocusManager:cachedImageForIndex:)]) {
        UIImage *image = [self.delegate mediaFocusManager:self cachedImageForIndex:index];
        if (image) {
            viewController.mainImageView.image = image;
            return viewController;
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url;
        NSData *data;
        NSError *error = nil;
        UIImage *image;
        
        id media = [self.delegate mediaFocusManager:self mediaForIndex:index];
        
        if (media) {
            if ([media respondsToSelector:@selector(absoluteURL)]) {
                url = media;
                data = [NSData dataWithContentsOfURL:url options:0 error:&error];
                image = [[UIImage alloc] initWithData:data];
                image = [self decodedImageWithImage:image];
            } else if ([media respondsToSelector:@selector(CGImage)]) {
                image = media;
            }
            
            if (!error) {
                
                if (image) {
                
                    dispatch_async(dispatch_get_main_queue(), ^{
                        viewController.mainImageView.image = image;
                    });
                    
                } else {
                    NSLog(@"Warning: Unable to generate image");
                }
                
                
                
            } else {
                NSLog(@"Warning: Unable to load image at %@. %@", url, error);
            }
        } else {
            NSLog(@"Warning: url is nil");
        }
    });
    
    return viewController;
}

#pragma mark - Focus/Defocus
- (void)startFocusingOnIndex:(NSUInteger) index
{
    UIViewController *parentViewController;
    ASMediaFocusController *focusViewController;
    CGPoint center;
    UIImageView *contentImageView;
    NSTimeInterval duration;
    CGRect finalImageFrame;
    __block CGRect untransformedFinalImageFrame;

    UIView *mediaTransitionView = [self.delegate mediaFocusManager:self imageViewForIndex:index];
    
    focusViewController = [self focusViewControllerForIndex:index];
    if(focusViewController == nil)
        return;
    
    self.focusViewController = focusViewController;
    if (self.defocusOnVerticalSwipe) {
        [self installSwipeGestureOnFocusView];
    }
    
    // This should be called after swipe gesture is installed to make sure the nav bar doesn't hide before animation begins.
    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerWillAppear:)])
    {
        [self.delegate mediaFocusManagerWillAppear:self];
    }
    
    self.mediaReferenceView = mediaTransitionView;
    parentViewController = [self.delegate parentViewControllerForMediaFocusManager:self];
    [parentViewController addChildViewController:focusViewController];
    [parentViewController.view addSubview:focusViewController.view];
    
    focusViewController.view.frame = parentViewController.view.bounds;
    mediaTransitionView.hidden = YES;
    
    contentImageView = focusViewController.mainImageView;
    center = [contentImageView.superview convertPoint:mediaTransitionView.center fromView:mediaTransitionView.superview];
    contentImageView.center = center;
    contentImageView.transform = mediaTransitionView.transform;
    contentImageView.bounds = mediaTransitionView.bounds;
    
    self.isZooming = YES;
    
    finalImageFrame = [self.delegate mediaFocusManager:self finalFrameForIndex:index];
    if(contentImageView.contentMode == UIViewContentModeScaleAspectFill)
    {
        CGSize size;
        
        size = [self sizeThatFitsInSize:finalImageFrame.size initialSize:contentImageView.image.size];
        finalImageFrame.size = size;
        finalImageFrame.origin.x = (focusViewController.view.bounds.size.width - size.width)/2;
        finalImageFrame.origin.y = (focusViewController.view.bounds.size.height - size.height)/2;
    }
    
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
                         initialTransform = contentImageView.transform;
                         contentImageView.transform = CGAffineTransformIdentity;
                         initialFrame = contentImageView.frame;
                         contentImageView.frame = frame;
                         [focusViewController updateOrientationAnimated:NO];
                         // This is the final image frame. No transform.
                         untransformedFinalImageFrame = contentImageView.frame;
                         frame = (self.elasticAnimation?[self rectInsetsForRect:untransformedFinalImageFrame ratio:-kAnimateElasticSizeRatio]:untransformedFinalImageFrame);
                         // It must now be animated from its initial frame and transform.
                         contentImageView.frame = initialFrame;
                         contentImageView.transform = initialTransform;
                         contentImageView.transform = CGAffineTransformIdentity;
                         contentImageView.frame = frame;
                         focusViewController.view.backgroundColor = self.backgroundColor;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                          animations:^{
                                              CGRect frame;
                                              
                                              frame = untransformedFinalImageFrame;
                                              frame = (self.elasticAnimation?[self rectInsetsForRect:frame ratio:kAnimateElasticSizeRatio*kAnimateElasticSecondMoveSizeRatio]:frame);
                                              contentImageView.frame = frame;
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                                               animations:^{
                                                                   CGRect frame;
                                                                   
                                                                   frame = untransformedFinalImageFrame;
                                                                   frame = (self.elasticAnimation?[self rectInsetsForRect:frame ratio:-kAnimateElasticSizeRatio*kAnimateElasticThirdMoveSizeRatio]:frame);
                                                                   contentImageView.frame = frame;
                                                               }
                                                               completion:^(BOOL finished) {
                                                                   [UIView animateWithDuration:(self.elasticAnimation?self.animationDuration*kAnimateElasticDurationRatio/3:0)
                                                                                    animations:^{
                                                                                        contentImageView.frame = untransformedFinalImageFrame;
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

- (void)endFocusing
{
    NSTimeInterval duration;
    UIView *contentView;
    CGRect __block bounds;
    
    if(self.isZooming && self.gestureDisabledDuringZooming)
        return;
    
    [self uninstallZoomView];
    
    contentView = self.focusViewController.mainImageView;
    if (contentView == nil)
        return;
    
    duration = (self.elasticAnimation?self.animationDuration*(1-kAnimateElasticDurationRatio):self.animationDuration);
    [UIView animateWithDuration:duration
                     animations:^{
                         if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerWillDisappear:)])
                         {
                             [self.delegate mediaFocusManagerWillDisappear:self];
                         }
                         
                         self.focusViewController.contentView.transform = CGAffineTransformIdentity;
                         contentView.center = [contentView.superview convertPoint:self.mediaReferenceView.center fromView:self.mediaReferenceView.superview];
                         contentView.transform = self.mediaReferenceView.transform;
                         bounds = self.mediaReferenceView.bounds;
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
                                                                                        self.mediaReferenceView.hidden = NO;
                                                                                        [self.focusViewController.view removeFromSuperview];
                                                                                        [self.focusViewController removeFromParentViewController];
                                                                                        self.focusViewController = nil;
                                                                                        
                                                                                        if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerDidDisappear:)])
                                                                                        {
                                                                                            [self.delegate mediaFocusManagerDidDisappear:self];
                                                                                        }
                                                                                    }];
                                                               }];
                                          }];
                     }];
}

#pragma mark - Gestures

- (void)handleDefocusGesture:(UIGestureRecognizer *)gesture
{
    [self endFocusing];
}

#pragma mark - Dismiss on swipe
- (void)installSwipeGestureOnFocusView
{
    UISwipeGestureRecognizer *swipeGesture;
    
    swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleDefocusBySwipeGesture:)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self.focusViewController.view addGestureRecognizer:swipeGesture];
    
    swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleDefocusBySwipeGesture:)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
    [self.focusViewController.view addGestureRecognizer:swipeGesture];
    self.focusViewController.view.userInteractionEnabled = YES;
}

- (void)handleDefocusBySwipeGesture:(UISwipeGestureRecognizer *)gesture
{
    UIView *contentView;
    CGFloat offset;
    
    [self uninstallZoomView];
    
    offset = (gesture.direction == UISwipeGestureRecognizerDirectionUp?-kSwipeOffset:kSwipeOffset);
    contentView = self.focusViewController.mainImageView;
    [UIView animateWithDuration:0.2
                     animations:^{
                         if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerWillDisappear:)])
                         {
                             [self.delegate mediaFocusManagerWillDisappear:self];
                         }
                         self.focusViewController.contentView.transform = CGAffineTransformIdentity;
                         
                         self.focusViewController.view.backgroundColor = [UIColor clearColor];
                         self.focusViewController.accessoryView.alpha = 0;
                         contentView.center = CGPointMake(self.focusViewController.view.center.x, self.focusViewController.view.center.y + offset);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.3
                                          animations:^{
                                              contentView.center = [contentView.superview convertPoint:self.mediaReferenceView.center fromView:self.mediaReferenceView.superview];
                                              contentView.transform = self.mediaReferenceView.transform;
                                              contentView.bounds  = self.mediaReferenceView.bounds;
                                          }
                                          completion:^(BOOL finished) {
                                              self.mediaReferenceView.hidden = NO;
                                              [self.focusViewController.view removeFromSuperview];
                                              [self.focusViewController removeFromParentViewController];
                                              self.focusViewController = nil;
                                              
                                              if (self.delegate && [self.delegate respondsToSelector:@selector(mediaFocusManagerDidDisappear:)])
                                              {
                                                  [self.delegate mediaFocusManagerDidDisappear:self];
                                              }
                                          }];
                     }];
}

@end
