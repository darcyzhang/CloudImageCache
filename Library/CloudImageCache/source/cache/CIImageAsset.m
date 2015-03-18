//
//  CIImageAsset.m
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import "CIImageAsset.h"

#define kContent    @"content"
#define kPolicy     @"policy"
#define kCount      @"count"

@implementation CIImageAsset

- (id)initWithUIImage:(UIImage *)image cachePolicy:(int)policy
{
    if (self = [super init])
    {
        _image = image;
        _policy = policy;
        _count = 0;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        _image  = [aDecoder decodeObjectForKey:kContent];
        _policy = [aDecoder decodeIntForKey:kPolicy];
        _count  = [aDecoder decodeIntegerForKey:kCount];
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_image  forKey:kContent];
    [aCoder encodeInt:_policy    forKey:kPolicy];
    [aCoder encodeInteger:_count forKey:kCount];
}

@end
