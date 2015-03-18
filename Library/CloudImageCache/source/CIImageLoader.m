//
//  CIImageLoader.m
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import "CIImageLoader.h"


#import <ImageIO/ImageIO.h>

#import "QVImageLoaderTool.h"
#import "QVDataLoaderModel.h"
#import "CIImagePersistence.h"

#define kImageURL @"imageurl"
#define kPolicy   @"policy"
#define kBlock    @"userblock"
#define kIncrementally @"incrementally"

@interface CIImageLoader()<CIImageCacheDelegate>

@property (nonatomic, weak)CIImageCacheManager *imageCache;
@property (nonatomic, strong) NSMutableDictionary *taskList;
@property (nonatomic) CGImageSourceRef incrementallyImgSource;
@property (nonatomic) BOOL isImageLoadFinished;

@end

@implementation CIImageLoader

#pragma mark init & dealloc
+ (CIImageLoader *)shareInstance
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
        _imageCache = [CIImageCacheManager shareInstance];
        _imageCache.delegate = self;
        _taskList = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    return self;
}

- (void)dealloc
{
    
}

#pragma mark -
#pragma mark Public API

+ (void)imageURL:(NSString *)URL completed:(void(^)(UIImage *))block policy:(CIImageCachePolicy)policy incrementally:(BOOL)incrementally
{
    
    NSString *key = [[CIImageLoader shareInstance] encode:URL];
    
    void (^userBlock)(UIImage *) = block;
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:URL, kImageURL, userBlock, kBlock, [NSNumber numberWithInt:policy], kPolicy, [NSNumber numberWithBool:incrementally], kIncrementally,nil];
    
    [[CIImageLoader shareInstance].taskList setObject:object forKey:key];
    
    [[CIImageLoader shareInstance].imageCache imageForKey:key];
    
}

+ (void)imageURL:(NSString *)URL completed:(void(^)(UIImage *))block
{
    [self imageURL:URL completed:block policy:CIImageCachePolicyFrequencyLow incrementally:NO];
}

+ (void)imageURL:(NSString *)URL completed:(void(^)(UIImage *))block incrementally:(BOOL)incrementally
{
    [self imageURL:URL completed:block policy:CIImageCachePolicyFrequencyLow incrementally:incrementally];
}

+ (void)imageURL:(NSString *)URL completed:(void(^)(UIImage *))block policy:(CIImageCachePolicy)policy
{
    [self imageURL:URL completed:block policy:policy incrementally:NO];
}

+ (void)clearDiskCache
{
    [[CIImageCacheManager shareInstance] clearDiskCache];
}

+ (void)clearAllCache
{
    [[CIImageCacheManager shareInstance] clearAllCache];
}

+ (void)clearAllCacheWithURL:(NSString *)URL
{
    NSString *key = [[CIImageLoader shareInstance] encode:URL];
    [[CIImageCacheManager shareInstance] clearAllCacheWithKey:key];
}


- (void)imageURL:(NSString *)URL callBack:(void(^)(UIImage *))block policy:(CIImageCachePolicy)policy incrementally:(BOOL)incrementally
{
    
    NSString *key = [self encode:URL];

    NSDictionary *object = @{kImageURL:URL, kBlock:[block copy], kPolicy:@(policy),  kIncrementally:@(incrementally)};
    
    [self.taskList setObject:object forKey:key];
    
    [self.imageCache imageForKey:key];

}

- (void)imageURL:(NSString *)URL callBack:(void(^)(UIImage *))block
{
    [self imageURL:URL callBack:block policy:CIImageCachePolicyFrequencyLow incrementally:NO];
}

- (void)imageURL:(NSString *)URL callBack:(void(^)(UIImage *))block incrementally:(BOOL)incrementally
{
    [self imageURL:URL callBack:block policy:CIImageCachePolicyFrequencyLow incrementally:incrementally];
}

- (void)imageURL:(NSString *)URL callBack:(void(^)(UIImage *))block policy:(CIImageCachePolicy)policy
{
    [self imageURL:URL callBack:block policy:policy incrementally:NO];
}

- (void)clearDiskCache
{
    [[CIImageCacheManager shareInstance] clearDiskCache];
}

- (void)clearAllCache
{
    [[CIImageCacheManager shareInstance] clearAllCache];
}

#pragma mark -
#pragma mark Private API

- (NSString *)encode:(NSString *)str
{
    return [QVImageLoaderTool md5:str];
}

- (void)requestImageWithKey:(NSString *)key
{
    QVFoundationLog("request network image , image key : %@",key);
    
    NSString *URL = [[self.taskList objectForKey:key] objectForKey:kImageURL];
    
    QVDataLoaderModel *loader = [[QVDataLoaderModel alloc] init];
    [loader insertRequest:URL];
    [loader.delegates addObject:self];
    
    [loader load:QVDataLoadCachePolicyNone more:NO];
}

#pragma mark -
#pragma mark QVImageCacheDelegate

- (void)searchImageSuccess:(UIImage *)image key:(NSString *)key
{
    void (^userBlock)(UIImage *)= [[self.taskList objectForKey:key] objectForKey:kBlock];
    if (userBlock != nil)
    {
        userBlock(image);
    }
}

- (void)searchImageFailureKey:(NSString *)key
{
    [self requestImageWithKey:key];
}

- (void)saveImageFinish:(BOOL)success key:(NSString *)key
{
    QVFoundationLog("image save finish key %@",key);
}


#pragma mark -
#pragma mark QVModelDelegate

- (void)modelDidStartLoad:(id<QVModel>)model
{
    _incrementallyImgSource = CGImageSourceCreateIncremental(NULL);
}

- (void)modelDidChangeProgress:(id<QVModel>)model progress:(id)progress
{
    QVDataLoaderModel *loader = (QVDataLoaderModel *)model;
    NSString *key = [self encode:loader.requestURL];
    BOOL incrementally = [[[self.taskList objectForKey:key] objectForKey:kIncrementally] boolValue];
    if (incrementally)
    {
        self.isImageLoadFinished = NO;
        
        if (loader.expectedLeght == loader.receiveData.length)
        {
            self.isImageLoadFinished = YES;
        }
        
        NSMutableData *data = loader.receiveData;
        
        CGImageSourceUpdateData(_incrementallyImgSource, (__bridge CFDataRef)data, _isImageLoadFinished);
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_incrementallyImgSource, 0, NULL);
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        
        if (image != nil)
        {
            
            void (^userBlock)(UIImage *) = [[self.taskList objectForKey:key] objectForKey:kBlock];
            userBlock(image);
            
        }
    }
}

- (void)modelDidFinishLoad:(id<QVModel>)model object:(id)object
{
    QVDataLoaderModel *loader = (QVDataLoaderModel *)model;
    [loader.delegates removeObject:self];
    
    NSString *key = [self encode:loader.requestURL];
    
    void (^userBlock)(UIImage *) = [[self.taskList objectForKey:key] objectForKey:kBlock];
    
    CIImageCachePolicy policy = [[[self.taskList objectForKey:key] objectForKey:kPolicy] integerValue];
    
    if (object != nil)
    {
        if (policy != CIImageCachePolicyNoCache)
        {
            [[CIImageCacheManager shareInstance] setImage:[UIImage imageWithData:object] forKey:key withCachePolicy:policy];
        }
        userBlock([UIImage imageWithData:object]);
    }

}

- (void)model:(id<QVModel>)model didFailWithError:(NSError*)error
{
    QVDataLoaderModel *loader = (QVDataLoaderModel *)model;
    NSString *key = [self encode:loader.requestURL];
    void (^userBlock)(UIImage *) = [[self.taskList objectForKey:key] objectForKey:kBlock];
    userBlock(nil);
}

@end
