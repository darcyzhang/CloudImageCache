//
//  CIImageLoaderTool.m
//  CloudImageCache
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//




#import "CIImageLoaderTool.h"

#import<CommonCrypto/CommonDigest.h>

@implementation CIImageLoaderTool


+ (NSString *)md5:(NSString *)str
{ 
	const char *cStr = [str UTF8String]; 
	unsigned char result[32]; 
	CC_MD5( cStr, strlen(cStr), result ); 
	return [NSString stringWithFormat: 
			@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7], 
			result[8], result[9], result[10], result[11], 
			result[12], result[13], result[14], result[15] 
			]; 
}

@end
