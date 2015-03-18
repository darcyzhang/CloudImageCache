//
//  CIImageCacheManager.m
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import "CIImageCacheManager.h"
#import "CIImageAsset.h"
#import "CIImagePersistence.h"
#import "CIImageCacheCleaner.h"
#import "CIImageLoaderTool.h"

#define ImageCacheSize 20


@interface CIImageCacheManager()<CIImagePersistenceDelegate>

@property (nonatomic, strong) NSMutableDictionary *highFrequencyList;
@property (nonatomic, strong) NSMutableDictionary *lowFrequencyList;
@property (nonatomic, strong) CIImagePersistence  *imagePersistence;
@property (nonatomic, strong) CIImageCacheCleaner *cleaner;

@end


@implementation CIImageCacheManager

+ (CIImageCacheManager *)shareInstance
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init])
    {
        _highFrequencyList = [[NSMutableDictionary alloc] initWithCapacity:ImageCacheSize];
        _lowFrequencyList = [[NSMutableDictionary alloc] initWithCapacity:ImageCacheSize];
        _imagePersistence = [CIImagePersistence shareInstance];
        _imagePersistence.delegate = self;
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        
        [center addObserver:self selector:@selector(handleMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        _cleaner = [[CIImageCacheCleaner alloc] init];
        [_cleaner startClearWithHighCache:_highFrequencyList lowCache:_lowFrequencyList];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _delegate = nil;
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key withCachePolicy:(CIImageCachePolicy)policy
{
    CIImageAsset *value = [[CIImageAsset alloc] initWithUIImage:image cachePolicy:policy];
    
    switch (policy)
    {
        case CIImageCachePolicyFrequencyHigh:
        {
            [self.highFrequencyList setObject:value forKey:key];
            break;
        }
        case CIImageCachePolicyFrequencyLow:
        {
            [self.highFrequencyList setObject:value forKey:key];
            break;
        }
        default:
        {
            [self.highFrequencyList setObject:value forKey:key];
            break;
        }
    }
    
    if (policy != CIImageCachePolicyOnlyMemory)
    {
        [self.imagePersistence saveImageToDisk:value forKey:key];
    }
}

- (void)imageForKey:(NSString *)key
{

    CIImageAsset *image = [self searchFromMemoryForKey:key];
    
    if (image != nil)
    {
        QVFoundationLog("search image from memory cache success, image key : %@",key);
        image.count++;
        
        [self.delegate searchImageSuccess:image.image key:key];
    }
    else if (image.policy != CIImageCachePolicyOnlyMemory)
    {
        [self.imagePersistence loadImageFromDiskForKey:key];
    }
    else
    {
        [self.delegate searchImageFailureKey:key];
    }
}

- (void)clearDiskCache
{
    [self.imagePersistence clearDiskCache];
}

- (void)clearAllCache
{
    @synchronized(self)
    {
        [self.lowFrequencyList removeAllObjects];
        [self.highFrequencyList removeAllObjects];
    }
    [self clearDiskCache];
        
}

- (void)clearAllCacheWithKey:(NSString *)key
{
    CIImageAsset *image = [self searchFromMemoryForKey:key];
    
    if (image != nil)
    {
        @synchronized(self)
        {
            [self.highFrequencyList removeObjectForKey:key];
            [self.lowFrequencyList removeObjectForKey:key];
        }
    }
    
    [[CIImagePersistence shareInstance] clearDiskCacheWithKey:key];
}

#pragma mark -
#pragma mark QVImagePersistence

- (void)saveImageFinish:(BOOL)success key:(NSString *)key
{
    [self.delegate saveImageFinish:success key:key];
}

- (void)loadImageFinish:(CIImageAsset *)image key:(NSString *)key
{
    if (image.image)
    {
        image.count ++;
        
        @synchronized(self)
        {
            [self.lowFrequencyList setObject:image forKey:key];
        }
        
        [self.delegate searchImageSuccess:image.image key:key];
    }
    else
    {
        [self.delegate searchImageFailureKey:key];
    }

}

#pragma mark -
#pragma mark Private API


- (CIImageAsset *)searchFromMemoryForKey:(NSString *)key
{
    QVFoundationLog("search image from memory cache, image key : %@",key);
    
    CIImageAsset *image = nil;
    
    @synchronized(self)
    {
    
        if ([self.highFrequencyList objectForKey:key])
        {
            image = [self.highFrequencyList objectForKey:key];
        }
        else if ([self.lowFrequencyList objectForKey:key])
        {
            image = [self.lowFrequencyList objectForKey:key];
        }
    }
    
    return image;
}


- (void)handleMemoryWarning
{
    @synchronized(self)
    {
        if ([self.lowFrequencyList count] > 0)
        {
            [self.lowFrequencyList removeAllObjects];
        }
        else if ([self.highFrequencyList  count] > 0)
        {
            [self.highFrequencyList removeAllObjects];
        }
    }
}

@end
