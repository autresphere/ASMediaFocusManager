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
// Returns the view controller in which the focus controller is going to ba added. This can be any view controller, full screen or not.
- (UIViewController *)parentViewControllerForMediaFocusManager:(ASMediaFocusManager *)mediaFocusManager;
// Returns a local media path, it must be an image path. This path is used to create an image at full screen.
- (NSString *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager mediaPathForView:(UIView *)view;

@end


@interface ASMediaFocusManager : NSObject

@property (nonatomic, assign) id<ASMediasFocusDelegate> delegate;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, strong) UIColor *backgroundColor;

- (void)installOnViews:(NSArray *)views;

@end
