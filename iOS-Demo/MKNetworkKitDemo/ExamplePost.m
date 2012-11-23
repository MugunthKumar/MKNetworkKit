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
    
    MKNetworkOperation *op = [self operationWithPath:@"index.php" 
                                              params:@{@"email": @"stock_user",
                                                      @"password": @"stock_pass",
                              @"where":@"/", @"f":@"signin"}
                                          httpMethod:@"POST"];    
    
    [op addCompletionHandler:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
    } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {

        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
    
    return op;
}

@end
