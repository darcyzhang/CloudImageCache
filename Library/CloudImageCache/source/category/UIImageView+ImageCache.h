//
//  CIImageAsset.h
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CIImageCacheManager.h"

@interface UIImageView (ImageCache)

- (void)setImageWithURL:(NSString *)URL;


- (void)setImageWithURL:(NSString *)URL  policy:(CIImageCachePolicy)policy incrementally:(BOOL)incrementally;

- (void)setImageWithURL:(NSString *)URL  policy:(CIImageCachePolicy)policy;

- (void)setImageWithURL:(NSString *)URL  incrementally:(BOOL)incrementally;

@end
