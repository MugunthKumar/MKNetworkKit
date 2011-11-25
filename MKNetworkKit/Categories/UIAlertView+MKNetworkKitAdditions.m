//
//  UIAlertView+MKNetworkKitAdditions.m
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 12/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "UIAlertView+MKNetworkKitAdditions.h"

@implementation UIAlertView (MKNetworkKitAdditions)

+(UIAlertView*) showWithError:(NSError*) networkError {

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[networkError localizedFailureReason]
                                                    message:[networkError localizedRecoverySuggestion]
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                          otherButtonTitles:nil];
    [alert show];
    return alert;
}
@end
