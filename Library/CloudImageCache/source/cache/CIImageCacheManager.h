//
//  CIImageCacheManager.h
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol CIImageCacheDelegate;

typedef enum
{
    CIImageCachePolicyFrequencyHigh   = 1,
    CIImageCachePolicyFrequencyLow    = 2,
    CIImageCachePolicyOnlyMemory      = 3,
    CIImageCachePolicyNoCache         = 4,
    
} CIImageCachePolicy;

@protocol CIImageCacheDelegate <NSObject>

- (void)searchImageSuccess:(UIImage *)image key:(NSString *)key;
- (void)searchImageFailureKey:(NSString *)key;
- (void)saveImageFinish:(BOOL)success key:(NSString *)key;

@end

@interface CIImageCacheManager : NSObject

@property (nonatomic,weak) id<CIImageCacheDelegate> delegate;

+ (CIImageCacheManager *)shareInstance;

- (void)setImage:(UIImage *)image forKey:(NSString *)key withCachePolicy:(CIImageCachePolicy)policy;
- (void)imageForKey:(NSString *)key;
- (void)clearDiskCache;
- (void)clearAllCache;
- (void)clearAllCacheWithKey:(NSString *)key;

@end
