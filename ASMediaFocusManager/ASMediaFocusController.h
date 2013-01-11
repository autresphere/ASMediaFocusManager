//
//  ASMediaFocusViewController.h
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 21/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ASMediaFocusController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *mainImageView;
@property (strong, nonatomic) IBOutlet UIView *contentView;

- (void)setImageFrame:(CGRect)frame;

@end
