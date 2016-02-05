//
//  ASMediaFocusBasicToolbarController.m
//  ASMediaFocusExemple
//
//  Created by Philippe Converset on 05/02/2016.
//  Copyright © 2016 AutreSphere. All rights reserved.
//

#import "ASMediaFocusBasicToolbarController.h"

@interface ASMediaFocusBasicToolbarController ()

@end

@implementation ASMediaFocusBasicToolbarController

- (void)viewDidLoad
{
    [self.doneButton setTitle:NSLocalizedString(@"Done", @"Done") forState:UIControlStateNormal];
    self.doneButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self.doneButton sizeToFit];
    self.doneButton.frame = CGRectInset(self.doneButton.frame, -20, -4);
    self.doneButton.layer.borderWidth = 2;
    self.doneButton.layer.cornerRadius = 4;
    self.doneButton.layer.borderColor = [UIColor whiteColor].CGColor;
}

@end
