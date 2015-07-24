//
//  ASMediaInfo.m
//  ASMediaFocusExemple
//
//  Created by Kevin Lundberg on 6/5/15.
//  Copyright (c) 2015 AutreSphere. All rights reserved.
//

#import "ASMediaInfo.h"

@implementation ASMediaInfo

- (instancetype)initWithURL:(NSURL *)mediaURL initialImage:(UIImage *)image
{
    return [self initWithURL:mediaURL initialImage:image overlayImage:nil title:nil];
}

- (instancetype)initWithURL:(NSURL *)mediaURL initialImage:(UIImage *)image overlayImage:(UIImage *)overlayImage
{
    return [self initWithURL:mediaURL initialImage:image overlayImage:overlayImage title:nil];
}

- (instancetype)initWithURL:(NSURL *)mediaURL initialImage:(UIImage *)image overlayImage:(UIImage *)overlayImage title:(NSString *)title
{
    self = [super init];
    if (self) {
        _mediaURL = [mediaURL copy];
        _title = [title copy];
        _initialImage = image;
        _overlayImage = overlayImage;
        _contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    ASMediaInfo *info = object;

    return (info.mediaURL == self.mediaURL || [info.mediaURL isEqual:self.mediaURL]);
}

- (NSUInteger)hash
{
    return self.mediaURL.hash ^ self.title.hash ^ self.initialImage.hash ^ self.overlayImage.hash;
}

@end
