//
//  CIImageAsset.h
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CIImageAsset : NSObject <NSCoding>

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) int  policy;
@property (nonatomic, assign) NSUInteger count;

- (id)initWithUIImage:(UIImage *)image cachePolicy:(int)policy;

@end
