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

@interface MKNetworkRequest (/*Private Methods*/)
@property (readwrite) NSHTTPURLResponse *response;
@property (readwrite) NSData *responseData;
@property (readwrite) NSError *error;
@property (readwrite) MKNKRequestState state;
@property (readwrite) NSURLSessionTask *task;
-(void) setAsError;
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
    
  }
  
  return self;
}

- (instancetype) initWithHostName:(NSString*) hostName {
  
  MKNetworkHost *engine = [[MKNetworkHost alloc] init];
  engine.hostName = hostName;
  return engine;
}

-(void) enableCache {
  
  [self enableCacheWithDirectory:nil inMemoryCost:0];
}

-(void) enableCacheWithDirectory:(NSString*) cacheDirectoryPath inMemoryCost:(NSUInteger) inMemoryCost {
  
  self.dataCache = [[MKCache alloc] initWithCacheDirectory:cacheDirectoryPath inMemoryCost:inMemoryCost];
  self.responseCache = [[MKCache alloc] initWithCacheDirectory:cacheDirectoryPath inMemoryCost:inMemoryCost];
}

-(void) startRequest:(MKNetworkRequest*) request forceReload:(BOOL) forceReload ignoreCache:(BOOL) ignoreCache {
  
  NSURLSessionDataTask *task = [self.defaultSession
                                dataTaskWithRequest:request.request
                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                  
                                  if(!response) return; // cancelled operation
                                  
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
                                    request.error = [self errorForRequest:request];
                                  }
                                  
                                  if(!request.error) {
                                    
                                    if(request.cacheable) {
                                      self.dataCache[request.uniqueIdentifier] = data;
                                      self.responseCache[request.uniqueIdentifier] = [NSKeyedArchiver archivedDataWithRootObject:response];
                                    }
                                    
                                    request.state = MKNKRequestStateCompleted;
                                  } else {
                                    request.state = MKNKRequestStateError;
                                  }
                                }];
  
  request.task = task;
  request.state = MKNKRequestStateStarted;
  
  if(request.cacheable) {
    NSHTTPURLResponse *cachedResponse = self.responseCache[request.uniqueIdentifier];
    NSData *cachedData = self.dataCache[request.uniqueIdentifier];
    
    if(cachedData) {
      request.responseData = cachedData;
      request.response = cachedResponse;
      request.state = MKNKRequestStateResponseAvailableFromCache;
    }
  }  
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

-(void) prepareRequest: (MKNetworkRequest*) request {
  
  // to be overridden by subclasses to tweak request creation
}

-(NSError*) errorForRequest: (MKNetworkRequest*) request {
  
  return request.error;
}
@end
