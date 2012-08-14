//
//  S3Object.h
//  MKNetworkKit-iOS
//
//  Created by Mugunth on 14/8/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDXML.h"

@interface S3Object : NSObject
+(void) registerKnownClass:(Class) class;
-(id) initWithXMLString:(NSString*) xmlString;
-(id) initWithDDXMLElement:(DDXMLElement*) element;

-(DDXMLDocument*) xmlRepresentation;
-(DDXMLDocument*) xmlRepresentationWithName:(NSString*) name;
@end
