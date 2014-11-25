//
//  MKNetworkHost.m
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

#import "MKNetworkHost.h"

#import "MKCache.h"

#import "NSDate+RFC1123.h"

#import "NSMutableDictionary+MKNKAdditions.h"

#import "NSHTTPURLResponse+MKNKAdditions.h"

NSUInteger const kMKNKDefaultCacheDuration = 60; // 60 seconds
NSUInteger const kMKNKDefaultImageCacheDuration = 3600*24*7; // 7 days
NSString *const kMKCacheDefaultDirectoryName = @"com.mknetworkkit.mkcache";

@interface MKNetworkRequest (/*Private Methods*/)
@property (readwrite) NSHTTPURLResponse *response;
@property (readwrite) NSData *responseData;
@property (readwrite) NSError *error;
@property (readwrite) MKNKRequestState state;
@property (readwrite) NSURLSessionTask *task;
-(void) setProgressValue:(double) updatedValue;
@end

@interface MKNetworkHost (/*Private Methods*/) <NSURLSessionDelegate>
@property NSURLSessionConfiguration *defaultConfiguration;
@property NSURLSessionConfiguration *secureConfiguration;
@property NSURLSessionConfiguration *backgroundConfiguration;

@property NSURLSession *defaultSession;
@property NSURLSession *secureSession;
@property NSURLSession *backgroundSession;

@property MKCache *dataCache;
@property MKCache *responseCache;

@property dispatch_queue_t runningTasksSynchronizingQueue;
@property NSMutableArray *runningDataTasks;
@end

@implementation MKNetworkHost

-(instancetype) init {
  
  if((self = [super init])) {
    
    self.defaultConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.secureConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    self.backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:
                                    [[NSBundle mainBundle] bundleIdentifier]];
    
    self.defaultSession = [NSURLSession sessionWithConfiguration:self.defaultConfiguration
                                                        delegate:self
                                                   delegateQueue:[[NSOperationQueue alloc] init]];
    
    self.secureSession = [NSURLSession sessionWithConfiguration:self.secureConfiguration
                                                       delegate:self
                                                  delegateQueue:[[NSOperationQueue alloc] init]];
    
    self.backgroundSession = [NSURLSession sessionWithConfiguration:self.backgroundConfiguration
                                                           delegate:self
                                                      delegateQueue:[[NSOperationQueue alloc] init]];
    
    self.runningTasksSynchronizingQueue = dispatch_queue_create("com.mknetworkkit.cachequeue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(self.runningTasksSynchronizingQueue, ^{
      self.runningDataTasks = [NSMutableArray array];
    });
  }
  
  return self;
}

- (instancetype) initWithHostName:(NSString*) hostName {
  
  MKNetworkHost *engine = [[MKNetworkHost alloc] init];
  engine.hostName = hostName;
  return engine;
}

-(void) enableCache {
  
  [self enableCacheWithDirectory:kMKCacheDefaultDirectoryName inMemoryCost:0];
}

-(void) enableCacheWithDirectory:(NSString*) cacheDirectoryPath inMemoryCost:(NSUInteger) inMemoryCost {
  
  self.dataCache = [[MKCache alloc] initWithCacheDirectory:[NSString stringWithFormat:@"%@/data", cacheDirectoryPath]
                                              inMemoryCost:inMemoryCost];
  
  self.responseCache = [[MKCache alloc] initWithCacheDirectory:[NSString stringWithFormat:@"%@/responses", cacheDirectoryPath]
                                                  inMemoryCost:inMemoryCost];
}

-(void) startUploadRequest:(MKNetworkRequest*) request {
  
  NSURLSessionUploadTask *uploadTask = [self.defaultSession uploadTaskWithRequest:request.request
                                                                         fromData:request.multipartFormData
                                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                  
                                                                  request.responseData = data;
                                                                  request.response = (NSHTTPURLResponse*) response;
                                                                  request.error = error;
                                                                  request.state = MKNKRequestStateCompleted;
                                                                }];
  
  request.state = MKNKRequestStateStarted;
  request.task = uploadTask;
  [uploadTask resume];
}

-(void) startDownloadRequest:(MKNetworkRequest*) request {
  
}

-(void) startRequest:(MKNetworkRequest*) request forceReload:(BOOL) forceReload ignoreCache:(BOOL) ignoreCache {
  
  NSHTTPURLResponse *cachedResponse = self.responseCache[@(request.hash)];
  NSDate *cacheExpiryDate = cachedResponse.cacheExpiryDate;
  NSTimeInterval expiryTimeFromNow = [cacheExpiryDate timeIntervalSinceNow];
  
  if(cachedResponse.isContentTypeImage && !cacheExpiryDate) {
    
    expiryTimeFromNow =
    cachedResponse.hasRequiredRevalidationHeaders ? kMKNKDefaultCacheDuration : kMKNKDefaultImageCacheDuration;
  }
  
  if(cachedResponse.hasDoNotCacheDirective) {
    
    expiryTimeFromNow = kMKNKDefaultCacheDuration;
  }
  
  if(request.cacheable && !ignoreCache) {
    
    NSData *cachedData = self.dataCache[@(request.hash)];
    
    if(cachedData) {
      request.responseData = cachedData;
      request.response = cachedResponse;
      
      if(expiryTimeFromNow > 0 && !forceReload) {
        
        request.state = MKNKRequestStateResponseAvailableFromCache;
        return; // don't make another request
      } else {
        
        request.state = expiryTimeFromNow > 0 ? MKNKRequestStateResponseAvailableFromCache :
        MKNKRequestStateStaleResponseAvailableFromCache;
      }
    }
  }
  
  NSURLSessionDataTask *task = [self.defaultSession
                                dataTaskWithRequest:request.request
                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                  
                                  if(!response) {
                                    
                                    request.response = (NSHTTPURLResponse*) response;
                                    request.error = error;
                                    request.responseData = data;
                                    request.state = MKNKRequestStateError;
                                    return;
                                  }
                                  
                                  request.response = (NSHTTPURLResponse*) response;
                                  
                                  if(request.response.statusCode >= 200 && request.response.statusCode < 300) {
                                    
                                    request.responseData = data;
                                    request.error = error;
                                  } else {
                                    request.responseData = data;
                                    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                                    if(response) userInfo[@"response"] = response;
                                    if(error) userInfo[@"error"] = error;
                                    
                                    NSError *httpError = [NSError errorWithDomain:@"com.mknetworkkit.httperrordomain"
                                                                             code:request.response.statusCode
                                                                         userInfo:userInfo];
                                    request.error = httpError;
                                    
                                    // if subclass of host overrides errorForRequest: they can provide more insightful error objects by parsing the response body.
                                    // the super class implementation just returns the same error object set in previous line
                                    request.error = [self errorForCompletedRequest:request];
                                  }
                                  
                                  if(!request.error) {
                                    
                                    if(request.cacheable) {
                                      self.dataCache[@(request.hash)] = data;
                                      self.responseCache[@(request.hash)] = response;
                                    }
                                    
                                    dispatch_sync(self.runningTasksSynchronizingQueue, ^{
                                      [self.runningDataTasks removeObject:request];
                                    });
                                    request.state = MKNKRequestStateCompleted;
                                  } else {
                                    
                                    dispatch_sync(self.runningTasksSynchronizingQueue, ^{
                                      [self.runningDataTasks removeObject:request];
                                    });
                                    request.state = MKNKRequestStateError;
                                    NSLog(@"%@", request);
                                  }
                                }];
  
  request.task = task;
  
  dispatch_sync(self.runningTasksSynchronizingQueue, ^{
    [self.runningDataTasks addObject:request];
  });
  
  request.state = MKNKRequestStateStarted;
}

-(MKNetworkRequest*) requestWithURLString:(NSString*) urlString {
  
  return [[MKNetworkRequest alloc] initWithURLString:urlString
                                              params:nil
                                            bodyData:nil
                                          httpMethod:@"GET"];
}

-(MKNetworkRequest*) requestWithPath:(NSString*) path {
  
  return [self requestWithPath:path params:nil httpMethod:@"GET" body:nil ssl:self.secureHost];
}

-(MKNetworkRequest*) requestWithPath:(NSString*) path params:(NSDictionary*) params {
  
  return [self requestWithPath:path params:params httpMethod:@"GET" body:nil ssl:self.secureHost];
}

-(MKNetworkRequest*) requestWithPath:(NSString*) path
                              params:(NSDictionary*) params
                          httpMethod:(NSString*) httpMethod {
  
  return [self requestWithPath:path params:params httpMethod:httpMethod body:nil ssl:self.secureHost];
}

-(MKNetworkRequest*) requestWithPath:(NSString*) path
                              params:(NSDictionary*) params
                          httpMethod:(NSString*) httpMethod
                                body:(NSData*) bodyData
                                 ssl:(BOOL) useSSL {
  
  if(self.hostName == nil) {
    
    NSLog(@"Hostname is nil, use requestWithURLString: method to create absolute URL operations");
    return nil;
  }
  
  NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@://%@",
                                useSSL ? @"https" : @"http",
                                self.hostName];
  
  if(self.portNumber != 0)
    [urlString appendFormat:@":%lu", (unsigned long)self.portNumber];
  
  if(self.path)
    [urlString appendFormat:@"/%@", self.path];
  
  if(![path isEqualToString:@"/"]) { // fetch for root?
    
    if(path.length > 0 && [path characterAtIndex:0] == '/') // if user passes /, don't prefix a slash
      [urlString appendFormat:@"%@", path];
    else if (path != nil)
      [urlString appendFormat:@"/%@", path];
  }
  
  MKNetworkRequest *request = [[MKNetworkRequest alloc] initWithURLString:urlString
                                                                   params:params
                                                                 bodyData:bodyData
                                                               httpMethod:httpMethod.uppercaseString];
  
  request.parameterEncoding = self.defaultParameterEncoding;
  [request addHeaders:self.defaultHeaders];
  [self prepareRequest:request]; // subclasses can over ride and add their own parameters and headers after this
  return request;
}

// You can override this method to tweak request creation
// But ensure that you call super
-(void) prepareRequest: (MKNetworkRequest*) request {
  
  if(!request.cacheable) return;
  NSHTTPURLResponse *cachedResponse = self.responseCache[@(request.hash)];
  
  NSString *lastModified = [cachedResponse.allHeaderFields objectForCaseInsensitiveKey:@"Last-Modified"];
  NSString *eTag = [cachedResponse.allHeaderFields objectForCaseInsensitiveKey:@"ETag"];
  
  if(lastModified) [request addHeaders:@{@"IF-MODIFIED-SINCE" : lastModified}];
  if(eTag) [request addHeaders:@{@"IF-NONE-MATCH" : eTag}];
}

-(NSError*) errorForCompletedRequest: (MKNetworkRequest*) completedRequest {
  
  // to be overridden by subclasses to tweak error objects by parsing the response body
  return completedRequest.error;
}

#pragma mark -
#pragma mark NSURLSession delegates

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{
  if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
    if([challenge.protectionSpace.host isEqualToString:self.hostName]){
      NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
      completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }
  }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
  
  NSLog(@"Upload progress for %lu: %f", (unsigned long)task.taskIdentifier,
        ((double)totalBytesSent/(double)totalBytesExpectedToSend));
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
  
  [self.runningDataTasks enumerateObjectsUsingBlock:^(MKNetworkRequest *request, NSUInteger idx, BOOL *stop) {
    
    if([request.task isEqual:dataTask]) {
      [request setProgressValue:0.0f];
      *stop = YES;
    }
  }];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
  
  float progress = (float)(((float)[data length]) / ((float)dataTask.response.expectedContentLength));
  [self.runningDataTasks enumerateObjectsUsingBlock:^(MKNetworkRequest *request, NSUInteger idx, BOOL *stop) {
    
    if([request.task isEqual:dataTask]) {
      [request setProgressValue:progress];
      *stop = YES;
    }
  }];
}


@end
