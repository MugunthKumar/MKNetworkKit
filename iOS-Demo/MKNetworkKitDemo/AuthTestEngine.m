//
//  AuthTestEngine.m
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth Kumar on 4/12/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "AuthTestEngine.h"

@implementation AuthTestEngine

-(void) authenticateTest {
    
    MKNetworkOperation *op = [self operationWithPath:@"mknetworkkit/basic_auth.php"
                                              params:nil 
                                          httpMethod:@"GET"];
    
    [op setUsername:@"admin" password:@"password"];
    
    [self enqueueOperation:op];
}
@end
