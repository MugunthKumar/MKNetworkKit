//
//  YahooEngine.h
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 7/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "MKNetworkEngine.h"

@interface YahooEngine : MKNetworkEngine

typedef void (^CurrencyResponseBlock)(double rate);

-(MKRequest*) currencyRateFor:(NSString*) sourceCurrency 
                   inCurrency:(NSString*) targetCurrency 
                 onCompletion:(CurrencyResponseBlock) completion
                      onError:(ErrorBlock) error;

-(MKRequest*) uploadImage;
@end
