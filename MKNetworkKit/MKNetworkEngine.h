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

-(MKRequest*) requestWithPath:(NSString*) path
                         body:(NSMutableDictionary*) body
                   httpMethod:method;

-(MKRequest*) requestWithPath:(NSString*) path
                         body:(NSMutableDictionary*) body
                   httpMethod:method 
                          ssl:(BOOL) useSSL;

-(void) queueRequest:(MKRequest*) request;
@end
