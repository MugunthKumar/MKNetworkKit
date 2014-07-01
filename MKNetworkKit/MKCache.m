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

@interface MKCache (/*Private Methods*/)
@property NSMutableDictionary *inMemoryCache;
@property NSMutableArray *recentlyUsedKeys;
@property dispatch_queue_t queue;
@end

@implementation MKCache

-(void) flush {
  
  [self.inMemoryCache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {

    NSString *filePath = [[self.directoryPath stringByAppendingPathComponent:key]
                          stringByAppendingPathExtension:MKCACHE_DEFAULT_PATH_EXTENSION];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
      
      NSError *error = nil;
      if([[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
        NSLog(@"%@", error);
      }
    }
    
    NSData *dataToBeWritten = self.inMemoryCache[key];
    [dataToBeWritten writeToFile:filePath atomically:YES];
  }];
  
  [self.inMemoryCache removeAllObjects];
  [self.recentlyUsedKeys removeAllObjects];
}

-(NSString*) defaultCacheDirectoryPath {
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  return [paths.firstObject stringByAppendingPathComponent:MKCACHE_DEFAULT_DIRNAME];
}

-(instancetype) init {
  
  return [self initWithCacheDirectory:[self defaultCacheDirectoryPath] inMemoryCost:MKCACHE_DEFAULT_COST];
}

-(instancetype) initWithCacheDirectory:(NSString*) cacheDirectory inMemoryCost:(NSUInteger) inMemoryCost {
  
  if(self = [super init]) {
    
    self.directoryPath = cacheDirectory ? cacheDirectory : [self defaultCacheDirectoryPath];
    self.cacheMemoryCost = inMemoryCost ? inMemoryCost : MKCACHE_DEFAULT_COST;
    
    self.inMemoryCache = [NSMutableDictionary dictionaryWithCapacity:self.cacheMemoryCost];
    self.recentlyUsedKeys = [NSMutableArray arrayWithCapacity:self.cacheMemoryCost];
    
    BOOL isDirectory = YES;
    BOOL directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:self.directoryPath isDirectory:&isDirectory];
    
    if(!isDirectory) {
      NSError *error = nil;
      if([[NSFileManager defaultManager] removeItemAtPath:self.directoryPath error:&error]) {
        NSLog(@"%@", error);
      }
      directoryExists = NO;
    }
    
    if(!directoryExists)
    {
      NSError *error = nil;
      if([[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory
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

-(id) objectForKeyedSubscript:(NSString*) key {
  
  NSData *cachedData = self.inMemoryCache[key];
  if(cachedData) return cachedData;
  
  NSString *filePath = [[self.directoryPath stringByAppendingPathComponent:key] stringByAppendingPathExtension:MKCACHE_DEFAULT_PATH_EXTENSION];
  
  if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    
    cachedData = [NSData dataWithContentsOfFile:filePath];
    self.inMemoryCache[key] = cachedData;
    return cachedData;
  }
  
  return nil;
}

- (void)setObject:(id) obj forKeyedSubscript:(NSString*) key {
  
  dispatch_async(self.queue, ^{
    
    self.inMemoryCache[key] = obj;
    
    // inserts the recently added item's key into the top of the queue.
    NSUInteger index = [self.recentlyUsedKeys indexOfObject:key];
    
    if(index != NSNotFound) {
      [self.recentlyUsedKeys removeObjectAtIndex:index];
    }
    
    [self.recentlyUsedKeys insertObject:key atIndex:0];
    
    if(self.recentlyUsedKeys.count > self.cacheMemoryCost) {
      
      NSString* lastUsedKey = self.recentlyUsedKeys.lastObject;
      id objectThatNeedsToBeWrittenToDisk = self.inMemoryCache[lastUsedKey];
      [self.inMemoryCache removeObjectForKey:lastUsedKey];
      NSString *filePath = [[self.directoryPath stringByAppendingPathComponent:lastUsedKey] stringByAppendingPathExtension:MKCACHE_DEFAULT_PATH_EXTENSION];
      
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
