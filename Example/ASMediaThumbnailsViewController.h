//
//  ASMediaThumbnailsViewController.h
//  ASMediaFocusExample
//
//  Created by Philippe Converset on 21/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASMediaFocusManager.h"

@interface ASMediaThumbnailsViewController : UIViewController <ASMediasFocusDelegate>

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *imageViews;
@property (strong, nonatomic) ASMediaFocusManager *mediaFocusManager;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *contentView;

@end
