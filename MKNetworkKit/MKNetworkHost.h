//
//  MKNetworkHost.h
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

#import <Foundation/Foundation.h>

#import "MKNetworkRequest.h"

#import "NSString+MKNKAdditions.h"

@class MKNetworkHost;

@protocol MKNetworkHostDelegate <NSObject>

@optional

-(void) networkHost:(MKNetworkHost*) networkHost didCreateDefaultSessionConfiguration:(NSURLSessionConfiguration*) configuration;
-(void) networkHost:(MKNetworkHost*) networkHost didCreateEphemeralSessionConfiguration:(NSURLSessionConfiguration*) configuration;
-(void) networkHost:(MKNetworkHost*) networkHost didCreateBackgroundSessionConfiguration:(NSURLSessionConfiguration*) configuration;

@end
@interface MKNetworkHost : NSObject

/*!
 *  @abstract Initializes your network engine with a hostname
 *
 *  @discussion
 *	Creates an engine for a given host name
 *  The hostname parameter is optional
 *  The hostname, if not null, initializes a Reachability notifier.
 *  Network reachability notifications are automatically taken care of by MKNetworkEngine
 *
 */
- (id) initWithHostName:(NSString*) hostName;

-(void) enableCache;
-(void) enableCacheWithDirectory:(NSString*) cacheDirectoryPath inMemoryCost:(NSUInteger) inMemoryCost;

@property NSString *hostName;
@property NSString *path;
@property NSUInteger portNumber;
@property NSDictionary *defaultHeaders;
@property BOOL secureHost;
@property MKNKParameterEncoding defaultParameterEncoding;

@property (weak) id <MKNetworkHostDelegate> delegate;
@property (copy) void (^backgroundSessionCompletionHandler)(void);

// You can override this method to tweak request creation
// But ensure that you call super
-(void) prepareRequest: (MKNetworkRequest*) networkRequest;
-(NSError*) errorForCompletedRequest: (MKNetworkRequest*) completedRequest;

-(MKNetworkRequest*) requestWithURLString:(NSString*) urlString;

-(MKNetworkRequest*) requestWithPath:(NSString*) path;

-(MKNetworkRequest*) requestWithPath:(NSString*) path
                              params:(NSDictionary*) params;

-(MKNetworkRequest*) requestWithPath:(NSString*) path
                              params:(NSDictionary*) params
                          httpMethod:(NSString*) httpMethod;
/*!
 *  @abstract Creates a simple GET Operation with a request URL, parameters, HTTP Method and the SSL switch
 *
 *  @discussion
 *	Creates an operation with the given URL path.
 *  The ssl option when true changes the URL to https.
 *  The ssl option when false changes the URL to http.
 *  The default headers you specified in your MKNetworkEngine subclass gets added to the headers
 *  The params dictionary in this method gets attached to the URL as query parameters if the HTTP Method is GET/DELETE
 *  The params dictionary is attached to the body if the HTTP Method is POST/PUT
 *  The body data is attached to the request body
 *  If the body data is present and the para
 *  This method calls operationsWithPath:body:httpMethod:ssl: eventually to construct the operation
 */
-(MKNetworkRequest*) requestWithPath:(NSString*) path
                              params:(NSDictionary*) params
                          httpMethod:(NSString*)method
                                body:(NSData*) bodyData
                                 ssl:(BOOL) useSSL;

/*
 * Use protocol cache policy
 * Reload ignoring cache
 * Reload with cache even if cache is not stale
 */

-(void) startRequest:(MKNetworkRequest*) request;
-(void) startUploadRequest:(MKNetworkRequest*) request;
-(void) startDownloadRequest:(MKNetworkRequest*) request;

@end
