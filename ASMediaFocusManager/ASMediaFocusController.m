//
//  ASMediaFocusViewController.m
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 21/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import "ASMediaFocusController.h"
#import "ASVideoControlView.h"
#import "NSURL+ASMediaFocusManager.h"
#import "UIImage+ASMediaFocusManager.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>


static CGFloat const kDefaultControlMargin = 5;
static char const kPlayerPresentationSizeContext;

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

- (id)init
{
    if ((self = [super init])) {
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.player play];
}

#pragma mark - Public

- (void)setInfo:(ASMediaInfo *)info withCachedImage:(UIImage *)cachedImage
{
    if (_info != info) {
        _info = info;

        self.titleLabel.text = info.title;
        if (cachedImage) {
            self.mainImageView.image = cachedImage;
        } else {
            self.mainImageView.image = info.initialImage;
        }
        self.mainImageView.contentMode = info.contentMode;

        if(info.mediaURL.as_isVideoURL)
        {
            [self showPlayerWithURL:info.mediaURL];
        }
        else
        {
            __weak __typeof(self) weakSelf = self;
            if ([self.delegate focusController:self shouldLoadMediaDirectly:info]) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [weakSelf loadImageFromURL:info.mediaURL];
                });
            } else {
                [self.delegate focusController:self loadMedia:info completion:^(UIImage *result, NSError *error) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [weakSelf decodeAndDisplayImage:result];
                    });
                }];
            }
        }
    }
}

- (void)showPlayerWithURL:(NSURL *)url
{
    self.playerView = [[PlayerView alloc] initWithFrame:self.mainImageView.bounds];
    [self.mainImageView addSubview:self.playerView];
    self.playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.playerView.hidden = YES;
    self.player = [[AVPlayer alloc] initWithURL:url];
    
    ((PlayerView *)self.playerView).player = self.player;
    [self.player.currentItem addObserver:self forKeyPath:@"presentationSize" options:NSKeyValueObservingOptionNew context:(void*)&kPlayerPresentationSizeContext];
}

- (void)loadImageFromURL:(NSURL *)url
{
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];;

    if(error != nil)
    {
        NSLog(@"Warning: Unable to load image at %@. %@", url, error);
    }
    else
    {
        UIImage *image = [[UIImage alloc] initWithData:data];
        [self decodeAndDisplayImage:image];
    }
}

- (void)decodeAndDisplayImage:(UIImage *)image
{
    image = [image as_decodedImage];
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.mainImageView.image = image;
        [weakSelf.scrollView displayImage:image];
    });
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
    // player will play when instructed to by the media focus manager.
}

- (void)defocusWillStart
{
    [self uninstallZoomView];
    [self pinAccessoryView];
    [self.player pause];
}

- (void)pauseVideo
{
    [self.player pause];
}

- (void)playVideo
{
    [self.player play];
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

    [self.delegate focusController:self accessoryViewShown:visible];
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
    if ([self accessoryViewCanShow])
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

- (BOOL)accessoryViewCanShow
{
    return (self.scrollView.zoomScale == self.scrollView.minimumZoomScale);
}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.scrollView.zoomImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self showAccessoryView:[self accessoryViewCanShow]];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kPlayerPresentationSizeContext) {
        [self.view setNeedsLayout];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end
