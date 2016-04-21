//
//  ASMediaFocusManager.h
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 11/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASMediaInfo.h"

typedef void(^ASMediaLoadCompletion)(id media, NSError *error);

@class ASMediaFocusManager;

@protocol ASMediasFocusDelegate <NSObject>

// Returns the view controller in which the focus controller is going to be added. This can be any view controller, full screen or not.
- (UIViewController *)parentViewControllerForMediaFocusManager:(ASMediaFocusManager *)mediaFocusManager;

// Returns the media info (url & title) for the given view. This is used over mediaURLForView: if it is implemented.
- (ASMediaInfo *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager mediaInfoForView:(UIView *)view;

@optional

// Returns a list of media info objects that can be displayed in a horizontally-paged carousel. If the object returned by mediaInfoForView is in the returned list, it will be the first thing shown, and the user can swipe left or right from it depending on its location in the list. If the object returned by that is not in the returned list, it will be prepended to the beginning, and all items in this list will be accessible by swiping to the right.
- (NSArray *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager mediaInfoListForView:(UIView *)view;

// Returns the final focused frame for this media view. This frame is usually a full screen frame. If not implemented, default is the parent view controller's view frame.
- (CGRect)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager finalFrameForView:(UIView *)view;

// Called when a focus view is about to be shown. For example, you might use this method to hide the status bar.
- (void)mediaFocusManagerWillAppear:(ASMediaFocusManager *)mediaFocusManager;
// Called when a focus view has been shown.
- (void)mediaFocusManagerDidAppear:(ASMediaFocusManager *)mediaFocusManager;
// Called when the view is about to be dismissed by the 'done' button or by gesture. For example, you might use this method to show the status bar (if it was hidden before).
- (void)mediaFocusManagerWillDisappear:(ASMediaFocusManager *)mediaFocusManager;
// Called when the view has be dismissed by the 'done' button or by gesture.
- (void)mediaFocusManagerDidDisappear:(ASMediaFocusManager *)mediaFocusManager;
// called after a swipe shows a new media info item.
- (void)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager didSwipeToMediaInfo:(ASMediaInfo *)info;
// Called before mediaURLForView to check if image is already on memory.
- (UIImage*)mediaFocusManager:(ASMediaFocusManager*)mediaFocusManager cachedImageForView:(UIView*)view;

- (void)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager loadMediaForInfo:(ASMediaInfo *)info completion:(ASMediaLoadCompletion)completion;

@end


@interface ASMediaFocusManager : NSObject

@property (nonatomic, weak) id<ASMediasFocusDelegate> delegate;
// The animation duration. Defaults to 0.5.
@property (nonatomic, assign) NSTimeInterval animationDuration;
// The background color. Defaults to transparent black.
@property (nonatomic, strong) UIColor *backgroundColor;
// Enables defocus on vertical swipe. Defaults to YES.
@property (nonatomic, assign) BOOL defocusOnVerticalSwipe;
// Enables focus on pinch gesture. Defaults to NO.
@property (assign, nonatomic) BOOL focusOnPinch;
// Returns whether the animation has an elastic effect. Defaults to YES.
@property (nonatomic, assign) BOOL elasticAnimation;
// Returns whether zoom is enabled on fullscreen image. Defaults to YES.
@property (nonatomic, assign) BOOL zoomEnabled;
// Returns whether gesture is disabled during zooming. Defaults to YES.
@property (nonatomic, assign) BOOL gestureDisabledDuringZooming;
// Returns whether defocus is enabled with a tap on view. Defaults to NO.
@property (nonatomic, assign) BOOL isDefocusingWithTap;
// Returns wheter a play icon is automatically added to media view which corresponding URL is of video type. Defaults to YES.
@property (nonatomic, assign) BOOL addPlayIconOnVideo;
// Image used to show a play icon on video thumbnails. Defaults to nil (uses internal image).
@property (nonatomic, strong) UIImage *playImage;

@property (nonatomic, assign, readonly) NSUInteger currentlyVisibleMediaIndex;

// Install focusing gesture on the specified array of views.
- (void)installOnViews:(NSArray *)views;
// Install focusing gesture on the specified view.
- (void)installOnView:(UIView *)view;
// Start the focus animation on the specified view. The focusing gesture must have been installed on this view.
- (void)startFocusingView:(UIView *)view;
// Start the close animation on the current focused view.
- (void)endFocusing;

@end
