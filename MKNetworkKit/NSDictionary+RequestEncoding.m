//
//  NSDictionary+RequestEncoding.m
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 12/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "NSDictionary+RequestEncoding.h"

@implementation NSDictionary (RequestEncoding)

-(NSString*) urlEncodedKeyValueString {
    
    NSMutableString *string = [NSMutableString string];
    for (NSString *key in self) {

        CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, 
                                                                            (__bridge CFStringRef) [self valueForKey:key], 
                                                                            nil,
                                                                            CFSTR("?!@#$^&%*+,:;='\"`<>()[]{}/\\|~ "), 
                                                                            kCFStringEncodingUTF8);
                                                
        [string appendFormat:@"%@=%@&", key, encodedString];	
    }
    
    if([string length] > 0)
        [string deleteCharactersInRange:NSMakeRange([string length] - 1, 1)];
    
    return string;
    
}
@end
