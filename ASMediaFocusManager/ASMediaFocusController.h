//
//  ASMediaFocusViewController.h
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 21/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASImageScrollView.h"

@interface ASMediaFocusController : UIViewController

@property (strong, nonatomic) ASImageScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIImageView *mainImageView;
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIView *accessoryView;
@property (strong, nonatomic) UITapGestureRecognizer *doubleTapGesture;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) UIView *playerView;
@property (strong, nonatomic) UIView *controlView;
@property (assign, nonatomic) CGFloat controlMargin;

- (void)updateOrientationAnimated:(BOOL)animated;
- (void)showPlayerWithURL:(NSURL *)url;

- (void)focusDidEndWithZoomEnabled:(BOOL)zoomEnabled;
- (void)defocusWillStart;

@end
