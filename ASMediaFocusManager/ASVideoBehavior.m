//
//  ASVideoBehavior.m
//  ASMediaFocusExemple
//
//  Created by Philippe Converset on 02/04/2015.
//  Copyright (c) 2015 AutreSphere. All rights reserved.
//

#import "ASVideoBehavior.h"

static NSInteger const kPlayIconTag = 50001;

@implementation ASVideoBehavior

- (void)addVideoIconToView:(UIView *)view image:(UIImage *)image
{
    UIImageView *imageView;
    
    if((image == nil) || CGSizeEqualToSize(image.size, CGSizeZero))
    {
        image = [UIImage imageNamed:@"asmedia_playbig"];
    }
    imageView = [[UIImageView alloc] initWithImage:image];
    imageView.tag = kPlayIconTag;
    imageView.contentMode = UIViewContentModeCenter;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.frame = view.bounds;
    [view addSubview:imageView];
}

@end
