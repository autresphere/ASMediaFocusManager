//
//  NSURL+ASMediaFocusManager.m
//  ASMediaFocusExemple
//
//  Created by Kevin Lundberg on 6/8/15.
//  Copyright (c) 2015 AutreSphere. All rights reserved.
//

#import "NSURL+ASMediaFocusManager.h"

@implementation NSURL (ASMediaFocusManager)

- (BOOL)as_isVideoURL
{
    NSString *extension = self.pathExtension.lowercaseString;
    return ([extension isEqualToString:@"mp4"] || [extension isEqualToString:@"mov"]);
}

@end
