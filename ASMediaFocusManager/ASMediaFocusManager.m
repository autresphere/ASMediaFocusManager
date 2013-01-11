//
//  ASMediaFocusManager.m
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 11/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import "ASMediaFocusManager.h"
#import "ASMediaFocusController.h"

@interface ASMediaFocusManager ()
// The media view being focused.
@property (nonatomic, strong) UIView *mediaView;
@property (nonatomic, strong) ASMediaFocusController *focusViewController;
@end

@implementation ASMediaFocusManager

// Taken from https://github.com/rs/SDWebImage/blob/master/SDWebImage/SDWebImageDecoder.m
- (UIImage *)decodedImageWithImage:(UIImage *)image
{
    CGImageRef imageRef = image.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGRect imageRect = (CGRect){.origin = CGPointZero, .size = imageSize};
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpace, CGImageGetBitmapInfo(imageRef));
    CGColorSpaceRelease(colorSpace);
    
    // If failed, return undecompressed image
    if (!context) return image;
    
    CGContextDrawImage(context, imageRect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        self.animationDuration = 0.5;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
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

- (ASMediaFocusController *)focusViewControllerForView:(UIView *)mediaView
{
    ASMediaFocusController *viewController;
    UITapGestureRecognizer *tapGesture;
    UIImage *image;
    
    image = [self.delegate mediaFocusManager:self imageForView:mediaView];
    if(image == nil)
        return nil;

    viewController = [[ASMediaFocusController alloc] initWithNibName:nil bundle:nil];
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDefocusGesture:)];
    [viewController.view addGestureRecognizer:tapGesture];    
    viewController.mainImageView.image = image;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image;
        NSString *path;
        
        path = [self.delegate mediaFocusManager:self mediaPathForView:mediaView];
        image = [[UIImage alloc] initWithContentsOfFile:path];
        image = [self decodedImageWithImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            viewController.mainImageView.image = image;
        });
    });

    return viewController;
}

- (void)handleFocusGesture:(UIGestureRecognizer *)gesture
{
    UIViewController *parentViewController;
    ASMediaFocusController *focusViewController;
    CGRect frame;
    UIView *mediaView;
    
    mediaView = gesture.view;
    focusViewController = [self focusViewControllerForView:mediaView];
    if(focusViewController == nil)
        return;
    
    self.focusViewController = focusViewController;
    self.mediaView = mediaView;
    parentViewController = [self.delegate parentViewControllerForMediaFocusManager:self];
    [parentViewController addChildViewController:focusViewController];
    [parentViewController.view addSubview:focusViewController.view];
    focusViewController.view.frame = parentViewController.view.bounds;
    mediaView.hidden = YES;
    
    frame = mediaView.frame;
    frame = [focusViewController.mainImageView.superview convertRect:frame fromView:mediaView.superview];
    focusViewController.mainImageView.frame = frame;
    
    [UIView animateWithDuration:self.animationDuration
                          delay:0
                        options:0
                     animations:^{
                         CGRect frame;
                         
                         frame = [self.delegate mediaFocusManager:self finalFrameforView:mediaView];
                         [focusViewController setImageFrame:frame];
                         focusViewController.view.backgroundColor = self.backgroundColor;
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (void)handleDefocusGesture:(UIGestureRecognizer *)gesture
{
    UIView *contentView;
    
    contentView = self.focusViewController.mainImageView;
    [UIView animateWithDuration:self.animationDuration
                          delay:0
                        options:0
                     animations:^{
                         CGAffineTransform transform;
                         CGRect frame;
                         
                         transform = self.mediaView.transform;
                         self.focusViewController.contentView.transform = CGAffineTransformIdentity;
                         frame = [contentView.superview convertRect:self.mediaView.frame fromView:self.mediaView.superview];
                         contentView.frame = frame;
                         gesture.view.backgroundColor = [UIColor clearColor];
                     }
                     completion:^(BOOL finished) {
                         self.mediaView.hidden = NO;
                         [self.focusViewController.view removeFromSuperview];
                         [self.focusViewController removeFromParentViewController];
                         self.focusViewController = nil;
                     }];
}
@end
