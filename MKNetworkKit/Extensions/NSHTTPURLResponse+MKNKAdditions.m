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

@implementation NSHTTPURLResponse (MKNKAdditions)

-(BOOL) isContentTypeImage {
  
  NSString *contentType = [self.allHeaderFields objectForCaseInsensitiveKey:@"Content-Type"];
  return ([contentType.lowercaseString rangeOfString:@"image"].location != NSNotFound);
}

-(BOOL) hasDoNotCacheDirective {
  
  NSString *cacheControl = [self.allHeaderFields objectForCaseInsensitiveKey:@"Cache-Control"];
  if(!cacheControl) return NO;
  if(([cacheControl.lowercaseString rangeOfString:@"no-cache"].location != NSNotFound)) return YES;
  if(self.maxAge == 0) return YES;
  return NO;
}

-(BOOL) hasHTTPCacheHeaders {
  
  NSString *cacheControl = [self.allHeaderFields objectForCaseInsensitiveKey:@"Cache-Control"];
  NSString *eTag = [self.allHeaderFields objectForCaseInsensitiveKey:@"ETag"];
  NSString *lastModified = [self.allHeaderFields objectForCaseInsensitiveKey:@"Last-Modified"];
  
  return (cacheControl || eTag || lastModified);
}


-(NSInteger) maxAge {
  
  __block NSInteger maxAge = 0;
  NSString *cacheControl = [self.allHeaderFields objectForCaseInsensitiveKey:@"Cache-Control"];
  NSArray *cacheControlEntities = [cacheControl componentsSeparatedByString:@","]; // max-age, must-revalidate, no-cache
  [cacheControlEntities enumerateObjectsUsingBlock:^(NSString *substring, NSUInteger idx, BOOL *stop) {
    
    if([substring.lowercaseString rangeOfString:@"max-age"].location != NSNotFound) {
      
      // do some processing to calculate expiresOn
      NSString *maxAge = nil;
      NSArray *array = [substring componentsSeparatedByString:@"="];
      if(array.count > 1) {
        maxAge = array[1];
        *stop = YES;
      }
    }
  }];
  
  return maxAge;
}

-(BOOL) hasRequiredRevalidationHeaders {
  
  NSString *lastModified = [self.allHeaderFields objectForCaseInsensitiveKey:@"Last-Modified"];
  NSString *eTag = [self.allHeaderFields objectForCaseInsensitiveKey:@"ETag"];

  return (eTag || lastModified);
}

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
      
      // Don't cache this request. It expires NOW
      expiresOnDate = [NSDate date];
    }
    
    // You can ignore must-revalidate
  }];
  
  return expiresOnDate;
}
@end
