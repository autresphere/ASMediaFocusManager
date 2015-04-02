//
//  ASMediaFocusViewController.m
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 21/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import "ASMediaFocusController.h"
#import "ASVideoControlView.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

static NSTimeInterval const kDefaultOrientationAnimationDuration = 0.4;
static CGFloat const kDefaultControlMargin = 5;

@interface PlayerView : UIView

@end

@implementation PlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}
- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}
- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end

@interface ASMediaFocusController () <UIScrollViewDelegate>

@property (nonatomic, assign) UIDeviceOrientation previousOrientation;
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation ASMediaFocusController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        self.doubleTapGesture.numberOfTapsRequired = 2;
        self.controlMargin = kDefaultControlMargin;
        
        self.tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
        [self.tapGesture requireGestureRecognizerToFail:self.doubleTapGesture];
        [self.view addGestureRecognizer:self.tapGesture];
    }

    return self;
}

- (void)dealloc
{
    if(self.player != nil)
    {
        [self.player.currentItem removeObserver:self forKeyPath:@"presentationSize"];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleLabel.layer.shadowOpacity = 1;
    self.titleLabel.layer.shadowOffset = CGSizeZero;
    self.titleLabel.layer.shadowRadius = 1;
    self.accessoryView.alpha = 0;
}

- (void)viewDidUnload
{
    [self setMainImageView:nil];
    [self setContentView:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)isParentSupportingInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    switch(toInterfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskPortrait;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskPortraitUpsideDown;
            
        case UIInterfaceOrientationLandscapeLeft:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskLandscapeLeft;
            
        case UIInterfaceOrientationLandscapeRight:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskLandscapeRight;
            
        case UIInterfaceOrientationUnknown:
            return YES;
    }
}

- (void)beginAppearanceTransition:(BOOL)isAppearing animated:(BOOL)animated
{
    if(!isAppearing)
    {
        self.accessoryView.alpha = 0;
        self.playerView.alpha = 0;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if(self.playerView != nil)
    {
        self.playerView.frame = self.mainImageView.bounds;
        [self layoutControlView];
    }
}

#pragma mark - Public
- (void)updateOrientationAnimated:(BOOL)animated
{
    CGAffineTransform transform;
    CGRect frame;
    NSTimeInterval duration = kDefaultOrientationAnimationDuration;
    
    if([UIDevice currentDevice].orientation == self.previousOrientation)
        return;
    
    if((UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) && UIDeviceOrientationIsLandscape(self.previousOrientation))
       || (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation) && UIDeviceOrientationIsPortrait(self.previousOrientation)))
    {
        duration *= 2;
    }
    
    if(([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait)
       || [self isParentSupportingInterfaceOrientation:(UIInterfaceOrientation)[UIDevice currentDevice].orientation])
    {
        transform = CGAffineTransformIdentity;
    }
    else
    {
        switch ([UIDevice currentDevice].orientation)
        {
            case UIDeviceOrientationLandscapeRight:
                if(self.parentViewController.interfaceOrientation == UIInterfaceOrientationPortrait)
                {
                    transform = CGAffineTransformMakeRotation(-M_PI_2);
                }
                else
                {
                    transform = CGAffineTransformMakeRotation(M_PI_2);
                }
                break;
                
            case UIDeviceOrientationLandscapeLeft:
                if(self.parentViewController.interfaceOrientation == UIInterfaceOrientationPortrait)
                {
                    transform = CGAffineTransformMakeRotation(M_PI_2);
                }
                else
                {
                    transform = CGAffineTransformMakeRotation(-M_PI_2);
                }
                break;
                
            case UIDeviceOrientationPortrait:
                transform = CGAffineTransformIdentity;
                break;
                
            case UIDeviceOrientationPortraitUpsideDown:
                transform = CGAffineTransformMakeRotation(M_PI);
                break;
                
            case UIDeviceOrientationFaceDown:
            case UIDeviceOrientationFaceUp:
            case UIDeviceOrientationUnknown:
                return;
        }
    }
    
    if(animated)
    {
        frame = self.contentView.frame;
        [UIView animateWithDuration:duration
                         animations:^{
                             self.contentView.transform = transform;
                             self.contentView.frame = frame;
                         }];
    }
    else
    {
        frame = self.contentView.frame;
        self.contentView.transform = transform;
        self.contentView.frame = frame;
    }
    self.previousOrientation = [UIDevice currentDevice].orientation;
}

- (void)showPlayerWithURL:(NSURL *)url
{
    self.playerView = [[PlayerView alloc] initWithFrame:self.mainImageView.bounds];
    [self.mainImageView addSubview:self.playerView];
    self.playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.playerView.hidden = YES;
    self.player = [[AVPlayer alloc] initWithURL:url];
    
    ((PlayerView *)self.playerView).player = self.player;
    [self.player.currentItem addObserver:self forKeyPath:@"presentationSize" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)focusDidEndWithZoomEnabled:(BOOL)zoomEnabled
{
    if(zoomEnabled && (self.playerView == nil))
    {
        [self installZoomView];
    }
    [self.view setNeedsLayout];
    [self showAccessoryView:YES];
    self.playerView.hidden = NO;
    [self.player play];
}

- (void)defocusWillStart
{
    [self uninstallZoomView];
    [self pinAccessoryView];
    [self.player pause];
}

#pragma mark - Private
- (void)installZoomView
{
    ASImageScrollView *scrollView;
    
    scrollView = [[ASImageScrollView alloc] initWithFrame:self.contentView.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    scrollView.delegate = self;
    self.scrollView = scrollView;
    [self.contentView insertSubview:scrollView atIndex:0];
    [scrollView displayImage:self.mainImageView.image];
    self.mainImageView.hidden = YES;
    
    [self.scrollView addGestureRecognizer:self.doubleTapGesture];
}

- (void)uninstallZoomView
{
    CGRect frame;
    
    if(self.scrollView == nil)
        return;
    
    frame = [self.contentView convertRect:self.scrollView.zoomImageView.frame fromView:self.scrollView];
    self.scrollView.hidden = YES;
    self.mainImageView.hidden = NO;
    self.mainImageView.frame = frame;
}

- (BOOL)isAccessoryViewPinned
{
    return (self.accessoryView.superview == self.view);
}

- (void)pinView:(UIView *)view
{
    CGRect frame;
    
    frame = [self.view convertRect:view.frame fromView:view.superview];
    view.transform = view.superview.transform;
    [self.view addSubview:view];
    view.frame = frame;
}

- (void)pinAccessoryView
{
    // Move the accessory views to the main view in order not to be rotated along with the media.
    [self pinView:self.accessoryView];
}

- (void)showAccessoryView:(BOOL)visible
{
    if(visible == [self accessoryViewsVisible])
        return;
    
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.accessoryView.alpha = (visible?1:0);
                     }
                     completion:nil];
}

- (BOOL)accessoryViewsVisible
{
    return (self.accessoryView.alpha == 1);
}

- (void)layoutControlView
{
    CGRect frame;
    CGRect videoFrame;
    CGRect titleFrame;
    
    if([self isAccessoryViewPinned])
        return;
    
    if(self.controlView == nil)
    {
        ASVideoControlView *controlView;
        
        controlView = [ASVideoControlView videoControlView];
        controlView.translatesAutoresizingMaskIntoConstraints = NO;
        controlView.scrubbing.player = self.player;
        self.controlView = controlView;
        [self.accessoryView addSubview:self.controlView];
    }
    
    videoFrame = [self videoFrame];
    frame = self.controlView.frame;
    frame.size.width = self.view.bounds.size.width - self.controlMargin*2;
    frame.origin.x = self.controlMargin;
    titleFrame = [self.controlView.superview convertRect:self.titleLabel.frame fromView:self.titleLabel.superview];
    frame.origin.y =  titleFrame.origin.y - frame.size.height - self.controlMargin;
    if(videoFrame.size.width > 0)
    {
        frame.origin.y = MIN(frame.origin.y, CGRectGetMaxY(videoFrame) - frame.size.height - self.controlMargin);
    }
    self.controlView.frame = frame;
}

- (CGRect)videoFrame
{
    CGRect frame;
    
    if(CGSizeEqualToSize(self.player.currentItem.presentationSize, CGSizeZero))
        return CGRectZero;
    
    frame = AVMakeRectWithAspectRatioInsideRect(self.player.currentItem.presentationSize, self.playerView.bounds);
    frame = CGRectIntegral(frame);
    
    return frame;
}

#pragma mark - Actions
- (void)handleTap:(UITapGestureRecognizer*)gesture
{
    if(self.scrollView.zoomScale == self.scrollView.minimumZoomScale)
    {
        [self showAccessoryView:![self accessoryViewsVisible]];
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer*)gesture
{
    CGRect frame = CGRectZero;
    CGPoint location;
    UIView *contentView;
    CGFloat scale;
    
    if(self.scrollView.zoomScale == self.scrollView.minimumZoomScale)
    {
        scale = self.scrollView.maximumZoomScale;
        contentView = [self.scrollView.delegate viewForZoomingInScrollView:self.scrollView];
        location = [gesture locationInView:contentView];
        frame = CGRectMake(location.x*self.scrollView.maximumZoomScale - self.scrollView.bounds.size.width/2, location.y*self.scrollView.maximumZoomScale - self.scrollView.bounds.size.height/2, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    }
    else
    {
        scale = self.scrollView.minimumZoomScale;
    }
    
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^(void) {
                         self.scrollView.zoomScale = scale;
                         [self.scrollView layoutIfNeeded];
                         if(scale == self.scrollView.maximumZoomScale)
                         {
                             [self.scrollView scrollRectToVisible:frame animated:NO];
                         }
                     }
                     completion:nil];
    
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.scrollView.zoomImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self showAccessoryView:(self.scrollView.zoomScale == self.scrollView.minimumZoomScale)];
}

#pragma mark - Notifications
- (void)orientationDidChangeNotification:(NSNotification *)notification
{
    [self updateOrientationAnimated:YES];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self.view setNeedsLayout];
}
@end
