//
//  ASMediaFocusViewController.h
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 21/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ASMediaFocusController : UIViewController

@property (strong, nonatomic) UIImageView *mainImageView;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIView *accessoryView;

@property (strong, nonatomic) UITapGestureRecognizer *doubleTapGesture;

- (void)updateOrientationAnimated:(BOOL)animated;
- (void)installZoomView;
- (void)uninstallZoomView;
- (void)pinAccessoryView;
- (void)showAccessoryView:(BOOL)visible;
- (void)setTitleString:(NSString*) titleString;

@end
