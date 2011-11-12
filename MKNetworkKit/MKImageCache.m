//
//  ImageCache.m
//  ImageCache
//
//  Created by Mugunth on 2/25/11.
//  Copyright 2011 Steinlogic. All rights reserved.

#import "MKImageCache.h"

static MKImageCache *_instance;

@interface MKImageCache (PrivateMethods)

- (NSString *)cacheDirectoryName;
- (NSString *)fileNameForKey:(NSString *)key;
- (BOOL) isImageFresh:(NSString*) imagePath;
- (void) cacheImage: (UIImage*) image forKey:(NSString*) urlString;
- (void) saveState;

@end


@implementation MKImageCache
@synthesize imageFetchQueue = _imageFetchQueue;
@synthesize runningOperations = _runningOperations;

@synthesize memoryCache = _memoryCache;
@synthesize memoryCacheKeys = _memoryCacheKeys;

+ (MKImageCache*)sharedImageCache
{
	@synchronized(self) {
		
    if (_instance == nil) {
			
      _instance = [[super allocWithZone:NULL] init];
      

      _instance.imageFetchQueue = [[NSOperationQueue alloc] init];
      
      [_instance.imageFetchQueue setMaxConcurrentOperationCount:6]; //MKTODO
      
      _instance.runningOperations = [NSMutableDictionary dictionary];
      
      _instance.memoryCache = [NSMutableDictionary dictionaryWithCapacity:MEMORY_CACHE_SIZE];
      _instance.memoryCacheKeys = [NSMutableArray arrayWithCapacity:MEMORY_CACHE_SIZE];
      
      
      NSString *cacheDirectory = [_instance cacheDirectoryName];
      BOOL isDirectory = NO;
      BOOL folderExists = [[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory isDirectory:&isDirectory] && isDirectory;
      
      if (!folderExists)
      {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:&error];
      }
      
      [[NSNotificationCenter defaultCenter] addObserver:_instance selector:@selector(didReceiveMemoryWarning)
                                                   name:UIApplicationDidReceiveMemoryWarningNotification
                                                 object:nil];
      
    }
  }
  return _instance;
}

+(void) dealloc
{  
  _instance.imageFetchQueue = nil;  
  _instance.memoryCache = nil;
  _instance.memoryCacheKeys = nil;
  _instance.runningOperations = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:_instance name:UIApplicationDidReceiveMemoryWarningNotification object:nil];  
}


-(void) saveState
{
  for(NSString *urlString in [self.memoryCache allKeys])
  {
    NSString *filePath = [self fileNameForKey:urlString];
    UIImage *image = [self.memoryCache objectForKey:urlString];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath] || ![self isImageFresh:filePath])
      [UIImageJPEGRepresentation(image, 0.8) writeToFile:filePath atomically:YES];
    
  }
}

-(void) imageAtURL:(NSURL*) url onCompletion:(void(^)(UIImage* image, NSURL* url)) imageFetchedBlock
{
  if(url == nil) return;
  
  NSString *urlString = [url absoluteString];
  UIImage *imageInCache = [self.memoryCache objectForKey:urlString];
  if(imageInCache)
  {
    imageFetchedBlock(imageInCache, url);        
    return;
  }
  
  NSString* filename = [self fileNameForKey:urlString];
  if([[NSFileManager defaultManager] fileExistsAtPath:filename])
  {
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:filename];
    [self cacheImage:image forKey:urlString];
    imageFetchedBlock(image, url);
    
    if([self isImageFresh:filename]) return;
  }
  
  ImageFetchOperation *existingOperation = [self.runningOperations objectForKey:urlString];
  
  if(existingOperation)
  {
    [existingOperation addImageFetchObserverBlock:imageFetchedBlock];
  }
  else 
  {
    ImageFetchOperation *newOperation = [[ImageFetchOperation alloc] initWithURL:url onCompletion:^
                                          {
                                            [self.runningOperations removeObjectForKey:urlString];                                         
                                          }];
    
    
    [newOperation addImageFetchObserverBlock:^(UIImage* fetchedImage, NSURL* url)
     {
       [self cacheImage:fetchedImage forKey:urlString];
       imageFetchedBlock(fetchedImage, url);
     }
     ];
    [self.runningOperations setObject:newOperation forKey:urlString];
    [self.imageFetchQueue addOperation:newOperation];
  }
  
}

-(void) cacheImage:(UIImage*) image forKey:(NSString*) urlString
{    
  [self.memoryCache setObject:image forKey:urlString];
  
  NSUInteger index = [self.memoryCacheKeys indexOfObject:urlString];
  if(index != NSNotFound)
    [self.memoryCacheKeys removeObjectAtIndex:index];    
  [self.memoryCacheKeys insertObject:urlString atIndex:0]; // remove it and insert it at start
  
  if([self.memoryCacheKeys count] > MEMORY_CACHE_SIZE)
  {
    NSString *lastKey = [self.memoryCacheKeys lastObject];        
    UIImage *image = [self.memoryCache objectForKey:lastKey];        
    NSString *filePath = [self fileNameForKey:lastKey];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath] || ![self isImageFresh:filePath])
      [UIImageJPEGRepresentation(image, 0.8) writeToFile:filePath atomically:YES];
    
    [self.memoryCacheKeys removeLastObject];
    [self.memoryCache removeObjectForKey:lastKey];        
  }
}

#pragma mark -
#pragma mark Private

- (void) didReceiveMemoryWarning
{
  [self saveState];
  [self.memoryCache removeAllObjects];
  [self.memoryCacheKeys removeAllObjects];
}

- (NSString *)cacheDirectoryName
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *cacheDirectoryName = [documentsDirectory stringByAppendingPathComponent:CACHE_FOLDER_NAME];
  return cacheDirectoryName;
}

- (NSString *)fileNameForKey:(NSString *)key
{
  NSString *cacheDirectoryName = [self cacheDirectoryName];
	key = [key stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	key = [key stringByReplacingOccurrencesOfString:@"www." withString:@""];
	key = [key stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
  
  NSString *fileName = [cacheDirectoryName stringByAppendingPathComponent:key];
  return fileName;
}


- (BOOL) isImageFresh:(NSString*) imagePath
{
  NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:imagePath error:nil];
  NSDate *creationDate = [attributes valueForKey:NSFileCreationDate];
  
  return (abs([creationDate timeIntervalSinceNow]) < IMAGE_FILE_LIFETIME);
}
@end
