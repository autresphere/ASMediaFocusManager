//
//  ASTransparentView.m
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 05/03/14.
//  Copyright (c) 2014 AutreSphere. All rights reserved.
//

#import "ASTransparentView.h"

@implementation ASTransparentView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view;
    
    view = [super hitTest:point withEvent:event];
    
    if(view == self)
        view = nil;
    
    return view;
}

@end
