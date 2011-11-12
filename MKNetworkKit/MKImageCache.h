//
//  ImageCache.h
//  Mugunth
//
//  Created by Mugunth on 2/25/11.
//  Copyright 2011 Steinlogic. All rights reserved.

#import <Foundation/Foundation.h>
#import "ImageFetchOperation.h"

#define MEMORY_CACHE_SIZE 100
#define CACHE_FOLDER_NAME @"ImageCache"

// 1 day in seconds
#define IMAGE_FILE_LIFETIME 86400.0

@interface MKImageCache : NSObject

+ (MKImageCache*) sharedImageCache;

-(void) imageAtURL:(NSURL*) url onCompletion:(void(^)(UIImage* image, NSURL* url)) imageFetchedBlock;

@property (nonatomic, strong) NSOperationQueue *imageFetchQueue;
@property (nonatomic, strong) NSMutableDictionary *runningOperations;

@property (nonatomic, strong) NSMutableDictionary *memoryCache;
@property (nonatomic, strong) NSMutableArray *memoryCacheKeys;

@end
