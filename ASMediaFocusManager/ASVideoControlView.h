//
//  ASVideoControlView.h
//  ASMediaFocusExemple
//
//  Created by Philippe Converset on 30/03/2015.
//  Copyright (c) 2015 AutreSphere. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ASBPlayerScrubbing/ASBPlayerScrubbing.h>

@interface ASVideoControlView : UIView

@property (strong, nonatomic) IBOutlet ASBPlayerScrubbing *scrubbing;

+ (ASVideoControlView *)videoControlView;

@end
