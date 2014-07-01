//
//  UIImageView+MKNKAdditions.h
//  Tokyo
//
//  Created by Mugunth on 30/6/14.
//  Copyright (c) 2014 LifeOpp Pte Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MKNetworkRequest;

@interface UIImageView (MKNKAdditions)

+(MKNetworkRequest*) cacheImageFromURLString:(NSString*) imageUrlString;
-(MKNetworkRequest*) loadImageFromURLString:(NSString*) imageUrlString;
-(MKNetworkRequest*) loadImageFromURLString:(NSString*) imageUrlString placeHolderImage:(UIImage*) placeHolderImage animated:(BOOL) animated;
@end
