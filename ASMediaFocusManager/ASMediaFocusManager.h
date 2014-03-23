//
//  ASMediaFocusManager.h
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 11/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASMediaFocusManager;

@protocol ASMediasFocusDelegate <NSObject>

// Returns an image that represents the media view. This image is used in the focusing animation view. It is usually a small image.
- (UIImage *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager imageForView:(UIView *)view;
// Returns the final focused frame for this media view. This frame is usually a full screen frame.
- (CGRect)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager finalFrameforView:(UIView *)view;
// Returns the view controller in which the focus controller is going to be added. This can be any view controller, full screen or not.
- (UIViewController *)parentViewControllerForMediaFocusManager:(ASMediaFocusManager *)mediaFocusManager;
// Returns the title for this media view. Return nil if you don't want any title to appear.
- (NSString *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager titleForView:(UIView *)view;

@optional
// Called when a focus view is about to be shown. For example, you might use this method to hide the status bar.
- (void)mediaFocusManagerWillAppear:(ASMediaFocusManager *)mediaFocusManager;
// Called when a focus view has been shown.
- (void)mediaFocusManagerDidAppear:(ASMediaFocusManager *)mediaFocusManager;
// Called when the view is about to be dismissed by the 'done' button or by gesture. For example, you might use this method to show the status bar (if it was hidden before).
- (void)mediaFocusManagerWillDisappear:(ASMediaFocusManager *)mediaFocusManager;
// Called when the view has be dismissed by the 'done' button or by gesture.
- (void)mediaFocusManagerDidDisappear:(ASMediaFocusManager *)mediaFocusManager;

@optional
// Implement one of the following two URLs. The first is if you're handling image storage to file manually, the second is if you're allowing Core Data to manage your image storage and so don't have a URL.

// Returns an URL where the image is stored. This URL is used to create an image at full screen. The URL may be local (file://) or distant (http://).
- (NSURL *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager mediaURLForView:(UIView *)view;
//Added callback for images stored in Core Data
- (UIImage *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager fullMediaForView:(UIView *)view;

@end


@interface ASMediaFocusManager : NSObject

@property (nonatomic, assign) id<ASMediasFocusDelegate> delegate;
// The animation duration. Defaults to 0.5.
@property (nonatomic, assign) NSTimeInterval animationDuration;
// The background color. Defaults to transparent black.
@property (nonatomic, strong) UIColor *backgroundColor;
// Returns whether the animation has an elastic effect. Defaults to YES.
@property (assign, nonatomic) BOOL elasticAnimation;
// Returns whether zoom is enabled on fullscreen image. Defaults to YES.
@property (nonatomic, assign) BOOL zoomEnabled;
// Returns whether gesture is disabled during zooming. Defaults to YES.
@property (nonatomic, assign) BOOL gestureDisabledDuringZooming;
// Returns whether defocuses with tap. Defaults to NO.
@property (nonatomic) BOOL isDefocusingWithTap;

- (void)installOnViews:(NSArray *)views;
- (void)installOnView:(UIView *)view;

@end
