//
//  ExamplePost.m
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 1/12/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "ExamplePost.h"

@implementation ExamplePost

-(MKNetworkOperation*) postDataToServer {
    
    MKNetworkOperation *op = [self operationWithPath:@"Versions/1.5/login.php" 
                                              params:@{@"email": @"bobs@thga.me",
                                                      @"password": @"12345678"}
                                          httpMethod:@"POST"];    
    
    //[op setUsername:@"bobs@thga.me" password:@"12345678"];

    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
    } onError:^(NSError *error) {

        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
    
    return op;
}

@end
