//
//  MediaCell.m
//  ASMediaFocusExemple
//
//  Created by Philippe Converset on 31/03/2015.
//  Copyright (c) 2015 AutreSphere. All rights reserved.
//

#import "MediaCell.h"

@implementation MediaCell

+ (MediaCell *)mediaCell
{
    NSArray *objects;
    MediaCell *cell;
    
    objects = [[NSBundle mainBundle] loadNibNamed:@"MediaCell" owner:nil options:nil];
    
    cell = objects[0];
    
    return cell;
}

- (void)layoutSubviews
{
    CGRect frame;
    
    frame = CGRectInset(self.contentView.frame, 10, 0);
    self.thumbnailView.frame = frame;
    [self.thumbnailView addSubview:self.playView];
    self.playView.center = CGPointMake(CGRectGetMidX(self.thumbnailView.bounds), CGRectGetMidY(self.thumbnailView.bounds));
}
@end
