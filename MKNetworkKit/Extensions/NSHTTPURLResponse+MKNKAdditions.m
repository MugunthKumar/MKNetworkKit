//
//  NSHTTPURLResponse+MKNKAdditions.m
//  Tokyo
//
//  Created by Mugunth on 30/7/14.
//  Copyright (c) 2014 LifeOpp Pte Ltd. All rights reserved.
//

#import "NSHTTPURLResponse+MKNKAdditions.h"

#import "NSDictionary+MKNKAdditions.h"

#import "NSDate+RFC1123.h"

NSUInteger const kMKNKDefaultCacheDuration = 60;

@implementation NSHTTPURLResponse (MKNKAdditions)

-(NSDate*) cacheExpiryDate {
  
  NSString *expiresOn = [self.allHeaderFields objectForCaseInsensitiveKey:@"Expires"];
  __block NSDate *expiresOnDate = [NSDate dateFromRFC1123:expiresOn];
  if(expiresOnDate) return expiresOnDate;
  
  NSString *cacheControl = [self.allHeaderFields objectForCaseInsensitiveKey:@"Cache-Control"];
  NSArray *cacheControlEntities = [cacheControl componentsSeparatedByString:@","]; // max-age, must-revalidate, no-cache
  
  [cacheControlEntities enumerateObjectsUsingBlock:^(NSString *substring, NSUInteger idx, BOOL *stop) {

    if([substring.lowercaseString rangeOfString:@"max-age"].location != NSNotFound) {
      
      // do some processing to calculate expiresOn
      NSString *maxAge = nil;
      NSArray *array = [substring componentsSeparatedByString:@"="];
      if(array.count > 1) {
        maxAge = array[1];
        expiresOnDate = [[NSDate date] dateByAddingTimeInterval:[maxAge intValue]];
      }
    }
    if([substring.lowercaseString rangeOfString:@"no-cache"].location != NSNotFound) {
      
      // Don't cache this request
      expiresOnDate = [[NSDate date] dateByAddingTimeInterval:kMKNKDefaultCacheDuration];
    }
    
    // You can ignore must-revalidate
  }];
  
  return expiresOnDate;
}
@end
