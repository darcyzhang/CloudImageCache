//
//  CIImageLoader.h
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CIImageCacheManager.h"

@interface CIImageLoader : NSObject

+ (CIImageLoader *)shareInstance;

/*
 @brief 查找图片，先从memory中查找，查找不到从disk中查找，再查找不到用NSURLConnection获取。
 @查找到的图片由block返回，查找不到返回nil
 @param URL : 图片的地址，需要http头在内完整地址
        callBack : 自定义block，接收返回的UIImage图片
        policy : 缓存策略
        incrementally : 是否渐进加载，YES渐进加载，默认为NO
 @note  网络图片请求支持并发。系统限制incrementally加载图片不支持并发
 */
- (void)imageURL:(NSString *)URL callBack:(void(^)(UIImage *))block policy:(CIImageCachePolicy)policy incrementally:(BOOL)incrementally;

- (void)imageURL:(NSString *)URL callBack:(void(^)(UIImage *))block policy:(CIImageCachePolicy)policy;

- (void)imageURL:(NSString *)URL callBack:(void(^)(UIImage *))block incrementally:(BOOL)incrementally;

- (void)imageURL:(NSString *)URL callBack:(void(^)(UIImage *))block;


//清除闪存缓存
- (void)clearDiskCache;

//清除所有缓存
- (void)clearAllCache;

//finish  static
+ (void)imageURL:(NSString *)URL completed:(void(^)(UIImage *))block policy:(CIImageCachePolicy)policy incrementally:(BOOL)incrementally;

+ (void)imageURL:(NSString *)URL completed:(void(^)(UIImage *))block policy:(CIImageCachePolicy)policy;

+ (void)imageURL:(NSString *)URL completed:(void(^)(UIImage *))block incrementally:(BOOL)incrementally;

+ (void)imageURL:(NSString *)URL completed:(void(^)(UIImage *))block;


//清除闪存缓存
+ (void)clearDiskCache;

//清除所有缓存
+ (void)clearAllCache;

//删除指定URL的缓存图片
+ (void)clearAllCacheWithURL:(NSString *)URL;

@end
