//
//  CIImageAsset.h
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import "UIImageView+ImageCache.h"
#import "CIImageLoader.h"

@implementation UIImageView (ImageCache)

- (void)setImageWithURL:(NSString *)URL
{
    [self setImageWithURL:URL policy:CIImageCachePolicyFrequencyLow incrementally:NO];
}

- (void)setImageWithURL:(NSString *)URL  policy:(CIImageCachePolicy)policy
{
    [self setImageWithURL:URL policy:policy incrementally:NO];
}

- (void)setImageWithURL:(NSString *)URL  incrementally:(BOOL)incrementally
{
    [self setImageWithURL:URL policy:CIImageCachePolicyFrequencyLow incrementally:incrementally];
}

- (void)setImageWithURL:(NSString *)URL  policy:(CIImageCachePolicy)policy incrementally:(BOOL)incrementally
{
    __weak UIImageView *wself = self;
    [CIImageLoader imageURL:URL completed:^(UIImage *image)
     {
         if (!wself || !image)
         {
             return ;
         }
         
         wself.image = image;
     } policy:policy incrementally:incrementally];
}

@end
