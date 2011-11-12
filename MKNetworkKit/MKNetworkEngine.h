//
//  MKNetworkEngine.h
//  MKNetworkKit
//
//  Created by Mugunth Kumar on 7/11/11.
//  Copyright 2011 Steinlogic. All rights reserved.

#import <Foundation/Foundation.h>

@class MKNetworkOperation;
@interface MKNetworkEngine : NSObject

- (id) initWithHostName:(NSString*) hostName customHeaderFields:(NSDictionary*) headers;

-(MKNetworkOperation*) requestWithPath:(NSString*) path;

-(MKNetworkOperation*) requestWithPath:(NSString*) path
                         body:(NSMutableDictionary*) body;

-(MKNetworkOperation*) requestWithPath:(NSString*) path
                         body:(NSMutableDictionary*) body
                   httpMethod:(NSString*)method;

-(MKNetworkOperation*) requestWithPath:(NSString*) path
                         body:(NSMutableDictionary*) body
                   httpMethod:(NSString*)method 
                          ssl:(BOOL) useSSL;

-(MKNetworkOperation*) requestWithURLString:(NSString*) urlString
                              body:(NSMutableDictionary*) body
                        httpMethod:(NSString*) method;

-(void) queueRequest:(MKNetworkOperation*) request;
@end
