//
//  CIImageCacheCleaner.h
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CIImageCacheCleaner : NSObject

- (void)startClearWithHighCache:(NSMutableDictionary *)high lowCache:(NSMutableDictionary *)low;

@end
