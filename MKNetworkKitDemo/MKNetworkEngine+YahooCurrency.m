//
//  MKNetworkEngine+YahooCurrency.m
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 7/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "MKNetworkEngine+YahooCurrency.h"

#define YAHOO_URL(__C1__, __C2__) [NSString stringWithFormat:@"d/quotes.csv?e=.csv&f=sl1d1t1&s=%@%@=X", __C1__, __C2__]


@implementation MKNetworkEngine (YahooCurrency)

-(MKRequest*) currencyRateFor:(NSString*) sourceCurrency 
                   inCurrency:(NSString*) targetCurrency 
                 onCompletion:(CurrencyResponseBlock) completion
                      onError:(NSError*) error {
    
    MKRequest *request = [self requestWithPath:YAHOO_URL(sourceCurrency, targetCurrency) 
                                          body:nil 
                                    httpMethod:@"GET"];
    
    [request onCompletion:^(NSString* responseString)
     {
         DLog(@"%@", responseString);
     }onError:^(NSError* error) {
         DLog(@"%@", error);
     }];
    
    [self queueRequest:request];
    
    return request;
}
@end
