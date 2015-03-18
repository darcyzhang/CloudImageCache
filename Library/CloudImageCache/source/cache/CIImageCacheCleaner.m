//
//  CIImageCacheCleaner.m
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import "CIImageCacheCleaner.h"
#import "CIImageAsset.h"
#import "CIImageLoaderTool.h"

#define OperationInterval 60 * 60   //轮询间隔1小时
#define Leeway            60        //精度1分钟

#define ThresholdValue    3         //周期内使用次数超过3次则升级到高优先级队列

@interface CIImageCacheCleaner ()
{
    dispatch_source_t _timer; 
}

@end

@implementation CIImageCacheCleaner

- (void)startClearWithHighCache:(NSMutableDictionary *)high lowCache:(NSMutableDictionary *)low
{
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), OperationInterval * NSEC_PER_SEC, Leeway * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_timer, ^()
    {
        [self repeatedMethod:high lowCache:low];
    });
    
    dispatch_resume(_timer);
}

- (void)repeatedMethod:(NSMutableDictionary *)high lowCache:(NSMutableDictionary *)low
{
    for (NSString *key in [low allKeys])
    {
        @synchronized(self)
        {
            CIImageAsset *image = [low objectForKey:key];

            if (image.count > ThresholdValue) //升级到高优先级队列
            {
                [low removeObjectForKey:key];
                [high setObject:image forKey:key];
                
                QVFoundationLog("image add to high queue key : %@",key);
            }
            else if (image.count <= 0) //移出内存
            {
                [low removeObjectForKey:key];
                
                QVFoundationLog("image remove from memory key : %@",key);
            }
            else
            {
                image.count--;
            }
        }
    }
    
    for (NSString *key in [high allKeys])
    {
        @synchronized(self)
        {
            CIImageAsset *image = [high objectForKey:key];
            image.count--;
            if (image.count < ThresholdValue) //降级到底优先级队列
            {
                [high removeObjectForKey:key];
                [low setObject:image forKey:key];
                
                QVFoundationLog("image remove from high queue key : %@",key);
            }
            
        }
    }
}

- (void)dealloc
{
    dispatch_source_cancel(_timer);
}

@end
