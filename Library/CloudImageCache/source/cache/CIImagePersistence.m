//
//  CIImagePersistence.m
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import "CIImagePersistence.h"
#import "CIImageAsset.h"
#import "CIImageLoaderTool.h"

#define FolderName @"imageCache"
#define ConfigFile @"configFile"
#define kFolderCreateTime @"folderCreateTime"

@interface CIImagePersistence()

@property (nonatomic, assign)int currentSubFolder;

@end

@implementation CIImagePersistence

+ (CIImagePersistence *)shareInstance
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
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDate *now = [NSDate date];
        NSDateComponents *comps = [calendar components:NSWeekdayCalendarUnit fromDate:now];
        int week = [comps weekday];
        _currentSubFolder = week;
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self clearExpiredImage];
        });
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _delegate = nil;
}

- (void)saveImageToDisk:(CIImageAsset *)image forKey:(NSString *)key
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        image.count = 0;   //图片持久化计数器归零
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:image];
        
        [data writeToFile:[self saveImagePath:key] atomically:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.delegate saveImageFinish:YES key:key];
        });
    });
}

- (void)loadImageFromDiskForKey:(NSString *)key
{
    QVFoundationLog("search image from disk, image key : %@",key);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSString *filePath = [self searchImagePathWithKey:key];
        
        if (filePath != nil)
        {
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            CIImageAsset *image = nil;
            
            if (data != nil)
            {
                image = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
            
            if (image.image)
            {
                QVFoundationLog("search image from disk success, image key : %@",key);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate loadImageFinish:image key:key];
                });
            }
            else
            {
                QVFoundationLog("search image from disk fail, image key : %@",key);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate loadImageFinish:nil key:key];
                });
            }
            
        }
        else
        {
            QVFoundationLog("search image from disk fail, image key : %@",key);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate loadImageFinish:nil key:key];
            });
        }
    });
}

- (void)clearDiskCache
{
    @synchronized(self)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:[self cacheFolderPath] error:nil];
        
        int64_t interval = [NSDate timeIntervalSinceReferenceDate];
        
        NSDictionary *config = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithLongLong:interval], kFolderCreateTime,nil];
        [config writeToFile:[self saveImagePath:ConfigFile] atomically:YES];
    }
}

- (void)clearDiskCacheWithKey:(NSString *)key
{
    NSString *filePath = [self searchImagePathWithKey:key];
    
    if (filePath != nil)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        @synchronized(self)
        {
            [fileManager removeItemAtPath:filePath error:nil];
        }
    }
}

- (NSString *)searchImagePathWithKey:(NSString *)key
{
    NSString *resultPath = nil;
    
    for (int i = 1; i <= 7; i++)
    {
        NSString *filePath = [self loadPathWithString:[NSString stringWithFormat:@"%@/%d/%@",FolderName, i, key]];
        
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        
        if (data != nil)
        {
            if (i != self.currentSubFolder)
            {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                [fileManager moveItemAtPath:filePath toPath:[self saveImagePath:key] error:nil];
            }
            
            resultPath = [self saveImagePath:key];
            break;
        }
    }
    
    return resultPath;
}

- (NSString *)cacheFolderPath
{
    return [self loadPathWithString:[NSString stringWithFormat:@"%@",FolderName]];
}

- (NSString *)subFolderPath:(int)subFolder
{
    return [self loadPathWithString:[NSString stringWithFormat:@"%@/%d",FolderName, subFolder]];
}

- (NSString *)saveImagePath:(NSString *)key
{
    return [self savePathWithString:[NSString stringWithFormat:@"%@/%d",FolderName, self.currentSubFolder] forKey:key];
}

//通过fileDir获取保存路径
- (NSString *)savePathWithString:(NSString *)dir forKey:(NSString *)key
{
    NSArray *cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [cache objectAtIndex:0];
    
    NSString *fileDir = [NSString stringWithFormat:@"%@/%@", cachePath, dir];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:fileDir isDirectory:&isDir];
    
    if (isDir != YES || existed != YES)
    {
        [fileManager createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *path = [fileDir stringByAppendingPathComponent:key];
    
    return path;
}

//通过fileDir获取读取路径
- (NSString *)loadPathWithString:(NSString *)dir
{
    NSArray *cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [cache objectAtIndex:0];
    
    NSString *fileDir = [NSString stringWithFormat:@"%@/%@", cachePath, dir];
    
    return fileDir;
}

- (void)clearExpiredImage
{
    //对过期的图片文件进行清理
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized(self)
        {
            int64_t interval = [NSDate timeIntervalSinceReferenceDate];
            
            NSString *filePath = [self loadPathWithString:[NSString stringWithFormat:@"%@/%d/%@",FolderName, self.currentSubFolder, ConfigFile]];
            
            NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:filePath];
            
            if (config != nil)
            {
                int64_t createTime = [[config objectForKey:kFolderCreateTime] longLongValue];
                
                if((interval - createTime) > 24 * 3600)//说明是7天前的，需要清理
                {
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    //删除文件夹
                    [fileManager removeItemAtPath:[self subFolderPath:self.currentSubFolder] error:nil];
                }
            }
            else
            {
                config = [[NSMutableDictionary alloc] initWithCapacity:0];
                
            }
            
            //保存配置文件
            [config setValue:[NSNumber numberWithLongLong:interval] forKey:kFolderCreateTime];
            [config writeToFile:[self saveImagePath:ConfigFile] atomically:YES];
        }
        
    });
}


@end
