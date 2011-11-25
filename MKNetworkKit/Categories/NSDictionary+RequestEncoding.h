//
//  NSDictionary+RequestEncoding.h
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 12/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (RequestEncoding)

-(NSString*) urlEncodedKeyValueString;
@end
