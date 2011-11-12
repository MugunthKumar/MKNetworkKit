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
    
    MKNetworkOperation *request = [self requestWithPath:YAHOO_URL(sourceCurrency, targetCurrency) 
                                          body:nil 
                                    httpMethod:@"GET"];
    
    [request onCompletion:^(MKNetworkOperation *completedRequest)
     {
         DLog(@"%@", [completedRequest responseString]);
         completionBlock(5.0f);
     }onError:^(NSError* error) {

         errorBlock(error);
     }];
    
    [self queueRequest:request];
    
    return request;
}

-(MKNetworkOperation*) uploadImageFromFile {
    
    MKNetworkOperation *request = [self requestWithURLString:@"http://twitpic.com/api/upload" 
                                               body:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     @"mksg", @"username",
                                                     @"HelloMKSG", @"password",
                                                     nil]
                                         httpMethod:@"POST"];

    [request addFile:@"/Users/mugunth/Desktop/transit.png" forKey:@"media"];

    //[request addData:[NSData dataWithContentsOfFile:@"/Users/mugunth/Desktop/transit.png"] forKey:@"media" mimeType:@"image/png"];

    request.uploadProgressChangedHandler = ^(double progress) {
    
        DLog(@"%.2f", progress*100.0);
    };
    
    [request onCompletion:^(MKNetworkOperation* completedRequest) {

        DLog(@"%@", completedRequest);        
    }
                  onError:^(NSError* error) {
                     
                      DLog(@"%@", error);
                  }];
    
    [self queueRequest:request];
    return request;
}

-(MKNetworkOperation*) uploadImageFromData {
    
    MKNetworkOperation *request = [self requestWithURLString:@"http://twitpic.com/api/upload" 
                                                        body:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              @"mksg", @"username",
                                                              @"HelloMKSG", @"password",
                                                              nil]
                                                  httpMethod:@"POST"];
    
    [request addData:[NSData dataWithContentsOfFile:@"/Users/mugunth/Desktop/transit.png"] forKey:@"media" mimeType:@"image/png"];
    
    request.uploadProgressChangedHandler = ^(double progress) {
        
        DLog(@"%.2f", progress*100.0);
    };
    
    [request onCompletion:^(MKNetworkOperation* completedRequest) {
        
        DLog(@"%@", completedRequest);        
    }
                  onError:^(NSError* error) {
                      
                      DLog(@"%@", error);
                  }];
    
    [self queueRequest:request];
    return request;
}


-(MKNetworkOperation*) downloadFatAssFile {
    
    MKNetworkOperation *request = [self requestWithURLString:@"http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURLRequest_Class/NSURLRequest_Class.pdf" 
                                                        body:nil
                                                  httpMethod:@"GET"];

    request.downloadProgressChangedHandler = ^(double progress) {
        
        DLog(@"%.2f", progress*100.0);
    };
    
    [request onCompletion:^(MKNetworkOperation* completedRequest) {
        
        DLog(@"%@", completedRequest);        
    }
                  onError:^(NSError* error) {
                      
                      DLog(@"%@", error);
                  }];
    
    request.downloadStream = [NSOutputStream outputStreamToFileAtPath:@"/Users/mugunth/Desktop/file.pdf" append:YES];
    
    [self queueRequest:request];
    return request;
}
@end
