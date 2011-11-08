//
//  MKNetworkEngine.h
//  MKNetworkKit
//
//  Created by Mugunth Kumar on 7/11/11.
//  Copyright 2011 Steinlogic. All rights reserved.

#import <Foundation/Foundation.h>

@class MKRequest;
@interface MKNetworkEngine : NSObject

- (id) initWithHostName:(NSString*) hostName customHeaderFields:(NSDictionary*) headers;

-(MKRequest*) requestWithPath:(NSString*) path;

-(MKRequest*) requestWithPath:(NSString*) path
                         body:(NSMutableDictionary*) body;

-(MKRequest*) requestWithPath:(NSString*) path
                         body:(NSMutableDictionary*) body
                   httpMethod:(NSString*)method;

-(MKRequest*) requestWithPath:(NSString*) path
                         body:(NSMutableDictionary*) body
                   httpMethod:(NSString*)method 
                          ssl:(BOOL) useSSL;

-(MKRequest*) requestWithURLString:(NSString*) urlString
                              body:(NSMutableDictionary*) body
                        httpMethod:(NSString*) method;

-(void) queueRequest:(MKRequest*) request;
@end
