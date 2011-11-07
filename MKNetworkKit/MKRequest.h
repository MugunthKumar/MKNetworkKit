//
//  MKRequest.h
//  MKNetworkKit
//
//  Created by Mugunth on 25/2/11.
//  Copyright 2011 Steinlogic. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ResponseBlock)(NSString *responseString);
typedef void (^ErrorBlock)(NSError* requestError);

@interface MKRequest : NSOperation

+ (id)requestWithURLString:(NSString *)urlString
                      body:(NSMutableDictionary *)body
				httpMethod:(NSString *)method;

-(void) onCompletion:(ResponseBlock) response onError:(ErrorBlock) error;
-(void) setUsername:(NSString*) name password:(NSString*) password;
@end
