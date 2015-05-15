//
//  NSHTTPURLResponse+MKNKAdditions.h
//  Tokyo
//
//  Created by Mugunth on 30/7/14.
//  Copyright (c) 2014 LifeOpp Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSHTTPURLResponse (MKNKAdditions)
@property (readonly) BOOL isContentTypeImage;
@property (readonly) BOOL hasDoNotCacheDirective;
@property (readonly) BOOL hasRequiredRevalidationHeaders;
@property (readonly) BOOL hasHTTPCacheHeaders;
@property (readonly) NSDate* cacheExpiryDate;
@end
