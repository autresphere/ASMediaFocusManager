//
//  ASMediaFocusViewController.h
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 21/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASImageScrollView.h"
#import "ASMediaInfo.h"
#import "ASMediaFocusManager.h"

@class ASMediaFocusController;

@protocol ASMediaFocusControllerDelegate <NSObject>
- (void)focusController:(ASMediaFocusController *)controller accessoryViewShown:(BOOL)visible;
- (BOOL)focusController:(ASMediaFocusController *)controller shouldLoadMediaDirectly:(ASMediaInfo *)info;
- (void)focusController:(ASMediaFocusController *)controller loadMedia:(ASMediaInfo *)info completion:(ASMediaLoadCompletion)completion;
@end

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
@property (strong, nonatomic) ASMediaInfo *info;
@property (weak, nonatomic) id<ASMediaFocusControllerDelegate> delegate;

- (void)showPlayerWithURL:(NSURL *)url;
- (void)setInfo:(ASMediaInfo *)info withCachedImage:(UIImage *)cachedImage;
- (void)focusDidEndWithZoomEnabled:(BOOL)zoomEnabled;
- (void)defocusWillStart;
- (BOOL)accessoryViewCanShow;

- (void)pauseVideo;
- (void)playVideo;

@end
