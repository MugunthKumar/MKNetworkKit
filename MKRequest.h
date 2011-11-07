//
//  MKRequest.h
//  MKNetworkKit
//
//  Created by Mugunth on 25/2/11.
//  Copyright 2011 Steinlogic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MKRequest : NSOperation

+ (id)requestWithURLString:(NSString *)urlString
                      body:(NSMutableDictionary *)body
				httpMethod:(NSString *)method;

@end
