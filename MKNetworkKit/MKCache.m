//
//  MKCache.m
//  MKNetworkKit
//
//  Created by Mugunth Kumar (@mugunthkumar) on 23/06/14.
//  Copyright (C) 2011-2020 by Steinlogic Consulting and Training Pte Ltd

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "MKCache.h"

@import UIKit;

NSString *const kMKCacheDefaultPathExtension = @"mkcache";
NSUInteger const kMKCacheDefaultCost = 10;

@interface MKCache (/*Private Methods*/)
@property NSMutableDictionary *inMemoryCache;
@property NSMutableArray *recentlyUsedKeys;
@property dispatch_queue_t queue;
@end

@implementation MKCache

-(void) flush {
  
  [self.inMemoryCache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    
    NSString *stringKey = [NSString stringWithFormat:@"%@", key];
    NSString *filePath = [[self.directoryPath stringByAppendingPathComponent:stringKey]
                          stringByAppendingPathExtension:kMKCacheDefaultPathExtension];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
      
      NSError *error = nil;
      if(![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
        NSLog(@"%@", error);
      }
    }
    
    NSData *dataToBeWritten = nil;
    id objToBeWritten = self.inMemoryCache[key];
    dataToBeWritten = [NSKeyedArchiver archivedDataWithRootObject:objToBeWritten];
    [dataToBeWritten writeToFile:filePath atomically:YES];
  }];
  
  [self.inMemoryCache removeAllObjects];
  [self.recentlyUsedKeys removeAllObjects];
}

-(instancetype) init {
  
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"MKCache should be initialized with the designated initializer initWithCacheDirectory:inMemoryCost:"
                               userInfo:nil];
  return nil;
}

-(instancetype) initWithCacheDirectory:(NSString*) cacheDirectory inMemoryCost:(NSUInteger) inMemoryCost {
  
  NSParameterAssert(cacheDirectory != nil);
  
  if(self = [super init]) {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    self.directoryPath = [paths.firstObject stringByAppendingPathComponent:cacheDirectory];
    self.cacheMemoryCost = inMemoryCost ? inMemoryCost : kMKCacheDefaultCost;
    
    self.inMemoryCache = [NSMutableDictionary dictionaryWithCapacity:self.cacheMemoryCost];
    self.recentlyUsedKeys = [NSMutableArray arrayWithCapacity:self.cacheMemoryCost];
    
    BOOL isDirectory = YES;
    BOOL directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:self.directoryPath isDirectory:&isDirectory];
    
    if(!isDirectory) {
      NSError *error = nil;
      if(![[NSFileManager defaultManager] removeItemAtPath:self.directoryPath error:&error]) {
        NSLog(@"%@", error);
      }
      directoryExists = NO;
    }
    
    if(!directoryExists)
    {
      NSError *error = nil;
      if(![[NSFileManager defaultManager] createDirectoryAtPath:self.directoryPath
                                    withIntermediateDirectories:YES
                                                     attributes:nil
                                                          error:&error]) {
        NSLog(@"%@", error);
      }
    }
    
    self.queue = dispatch_queue_create("com.mknetworkkit.cachequeue", DISPATCH_QUEUE_SERIAL);
    
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flush)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flush)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flush)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
#elif TARGET_OS_MAC
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flush)
                                                 name:NSApplicationWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flush)
                                                 name:NSApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flush)
                                                 name:NSApplicationWillTerminateNotification
                                               object:nil];
    
#endif
  }
  
  return self;
}

-(void) dealloc {
  
#if TARGET_OS_IPHONE
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
#elif TARGET_OS_MAC
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillHideNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillResignActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillTerminateNotification object:nil];
#endif
}

-(id <NSCoding>) objectForKeyedSubscript:(id <NSCopying>) key {
  
  NSData *cachedData = self.inMemoryCache[key];
  if(cachedData) return cachedData;
  
  NSString *stringKey = [NSString stringWithFormat:@"%@", key];
  
  NSString *filePath = [[self.directoryPath stringByAppendingPathComponent:stringKey]
                        stringByAppendingPathExtension:kMKCacheDefaultPathExtension];
  
  if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    
    cachedData = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfFile:filePath]];
    self.inMemoryCache[key] = cachedData;
    return cachedData;
  }
  
  return nil;
}

- (void)setObject:(id <NSCoding>) obj forKeyedSubscript:(id <NSCopying>) key {
  
  dispatch_async(self.queue, ^{
    
    self.inMemoryCache[key] = obj;
    
    // inserts the recently added item's key into the top of the queue.
    NSUInteger index = [self.recentlyUsedKeys indexOfObject:key];
    
    if(index != NSNotFound) {
      [self.recentlyUsedKeys removeObjectAtIndex:index];
    }
    
    [self.recentlyUsedKeys insertObject:key atIndex:0];
    
    if(self.recentlyUsedKeys.count > self.cacheMemoryCost) {
      
      id<NSCopying> lastUsedKey = self.recentlyUsedKeys.lastObject;
      id objectThatNeedsToBeWrittenToDisk = [NSKeyedArchiver archivedDataWithRootObject:self.inMemoryCache[lastUsedKey]];
      [self.inMemoryCache removeObjectForKey:lastUsedKey];
      
      NSString *stringKey = [NSString stringWithFormat:@"%@", lastUsedKey];
      
      NSString *filePath = [[self.directoryPath stringByAppendingPathComponent:stringKey] stringByAppendingPathExtension:kMKCacheDefaultPathExtension];
      
      if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        NSError *error = nil;
        if(![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
          NSLog(@"Cannot remove file: %@", error);
        }
      }
      
      [objectThatNeedsToBeWrittenToDisk writeToFile:filePath atomically:YES];
      [self.recentlyUsedKeys removeLastObject];
    }
  });
}

@end
