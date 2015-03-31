//
//  ASVideoControlView.m
//  ASMediaFocusExemple
//
//  Created by Philippe Converset on 30/03/2015.
//  Copyright (c) 2015 AutreSphere. All rights reserved.
//

#import "ASVideoControlView.h"

@interface ASVideoControlView ()
@property (strong, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet UILabel *remainingTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (strong, nonatomic) IBOutlet UIButton *playPauseButton;

@end

@implementation ASVideoControlView

+ (ASVideoControlView *)videoControlView
{
    NSArray *objects;
    
    objects = [[NSBundle mainBundle] loadNibNamed:@"ASVideoControlView" owner:nil options:nil];
    
    return objects[0];
}

- (void)awakeFromNib
{
    [self.scrubbing addObserver:self forKeyPath:@"player" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)dealloc
{
    [self.scrubbing removeObserver:self forKeyPath:@"player"];
    [self.scrubbing.player removeObserver:self forKeyPath:@"rate"];
}

#pragma mark - Actions
- (IBAction)switchTimeLabel:(id)sender
{
    self.remainingTimeLabel.hidden = !self.remainingTimeLabel.hidden;
    self.durationLabel.hidden = !self.remainingTimeLabel.hidden;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"player"])
    {
        if(self.scrubbing.player != nil)
        {
            [self.scrubbing.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
        }
    }
    else
    {
    AVPlayer *player = object;
    
    self.playPauseButton.selected = (player.rate != 0);
    }
}
@end
