//
//  ASRotatingMediaPageViewController.h
//  ASMediaFocusExemple
//
//  Created by Kevin Lundberg on 6/8/15.
//  Copyright (c) 2015 AutreSphere. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ASMediaRotatingViewController : UIViewController

- (instancetype)initWithViewController:(UIViewController *)viewController;

- (void)updateOrientationAnimated:(BOOL)animated;

@end
