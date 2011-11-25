//
//  UIAlertView+MKNetworkKitAdditions.h
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 12/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (MKNetworkKitAdditions)
+(UIAlertView*) showWithError:(NSError*) networkError;
@end
