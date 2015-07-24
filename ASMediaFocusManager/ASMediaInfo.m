//
//  ASMediaInfo.m
//  ASMediaFocusExemple
//
//  Created by Kevin Lundberg on 6/5/15.
//  Copyright (c) 2015 AutreSphere. All rights reserved.
//

#import "ASMediaInfo.h"

@implementation ASMediaInfo


- (instancetype)initWithURL:(NSURL *)URL initialImage:(UIImage *)image
{
    return [self initWithURL:URL initialImage:image externalURL:nil overlayImage:nil title:nil];
}

- (instancetype)initWithURL:(NSURL *)URL initialImage:(UIImage *)image externalURL:(NSURL *)externalURL;
{
    return [self initWithURL:URL initialImage:image externalURL:externalURL overlayImage:nil title:nil];
}

- (instancetype)initWithURL:(NSURL *)URL initialImage:(UIImage *)image externalURL:(NSURL *)externalURL title:(NSString *)title;
{
    return [self initWithURL:URL initialImage:image externalURL:externalURL overlayImage:nil title:title];
}

- (instancetype)initWithURL:(NSURL *)URL initialImage:(UIImage *)image externalURL:(NSURL *)externalURL overlayImage:(UIImage *)overlayImage
{
    return [self initWithURL:URL initialImage:image externalURL:externalURL overlayImage:overlayImage title:nil];
}

- (instancetype)initWithURL:(NSURL *)URL initialImage:(UIImage *)image externalURL:(NSURL *)externalURL overlayImage:(UIImage *)overlayImage title:(NSString *)title
{
    self = [super init];
    if (self) {
        _mediaURL = [URL copy];
        _externalURL = [externalURL copy];
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
    
    return (info.mediaURL == self.mediaURL || [info.mediaURL isEqual:self.mediaURL])
    && (info.externalURL == self.externalURL || [info.externalURL isEqual:self.externalURL]);
}

- (NSUInteger)hash
{
    return self.mediaURL.hash ^ self.externalURL.hash ^ self.title.hash ^ self.initialImage.hash ^ self.overlayImage.hash;
}

@end
