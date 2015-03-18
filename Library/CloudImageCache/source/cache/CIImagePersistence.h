//
//  CIImagePersistence.h
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CIImageAsset;

@protocol CIImagePersistenceDelegate <NSObject>

- (void)saveImageFinish:(BOOL)success key:(NSString *)key;
- (void)loadImageFinish:(CIImageAsset *)image key:(NSString *)key;

@end




@interface CIImagePersistence : NSObject

@property (nonatomic,weak) id<CIImagePersistenceDelegate> delegate;

+ (CIImagePersistence *)shareInstance;

- (void)loadImageFromDiskForKey:(NSString *)key;
- (void)saveImageToDisk:(CIImageAsset *)image forKey:(NSString *)key;
- (void)clearDiskCache;
- (void)clearDiskCacheWithKey:(NSString *)key;

@end
