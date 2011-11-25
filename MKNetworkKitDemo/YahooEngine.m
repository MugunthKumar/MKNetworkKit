//
//  YahooEngine.m
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 7/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "YahooEngine.h"

#define YAHOO_URL(__C1__, __C2__) [NSString stringWithFormat:@"d/quotes.csv?e=.csv&f=sl1d1t1&s=%@%@=X", __C1__, __C2__]


@implementation YahooEngine

-(MKNetworkOperation*) currencyRateFor:(NSString*) sourceCurrency 
                            inCurrency:(NSString*) targetCurrency 
                          onCompletion:(CurrencyResponseBlock) completionBlock
                               onError:(ErrorBlock) errorBlock {
    
    MKNetworkOperation *op = [self requestWithPath:YAHOO_URL(sourceCurrency, targetCurrency) 
                                                   body:nil 
                                             httpMethod:@"GET"];
    
    [op onCompletion:^(MKNetworkOperation *completedRequest)
     {
         if([completedRequest isCachedResponse]) {
             DLog(@"Data from cache");
         }
         else {
             DLog(@"Data from server");
         }
         
         DLog(@"%@", [completedRequest responseString]);
         completionBlock(5.0f);
     }onError:^(NSError* error) {
         
         errorBlock(error);
     }];
    
    [self enqueueOperation:op];
    
    return op;
}

@end
