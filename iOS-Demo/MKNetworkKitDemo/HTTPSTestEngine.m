//
//  AuthTestEngine.m
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth Kumar on 4/12/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "HTTPSTestEngine.h"

@implementation HTTPSTestEngine

-(id) initWithDefaultSettings {
  
  if(self = [super initWithHostName:@"testbed1.mknetworkkit.com" customHeaderFields:@{@"x-client-identifier" : @"iOS"}]) {
    
  }  
  return self;
}

-(void) serverTrustTest {
  
  MKNetworkOperation *op = [self operationWithPath:@"/" params:nil httpMethod:nil ssl:YES];
  
  [op addCompletionHandler:^(MKNetworkOperation *operation) {
    
    DLog(@"%@", [operation responseString]); 
  } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
    
    DLog(@"%@", [error localizedDescription]);         
  }];
  [self enqueueOperation:op];
}

-(void) clientCertTest {
  
  MKNetworkOperation *op = [self operationWithPath:@"/" params:nil httpMethod:nil ssl:YES];
  op.clientCertificate = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"client.p12"];
  op.clientCertificatePassword = @"test";
  
  [op addCompletionHandler:^(MKNetworkOperation *operation) {
    
    DLog(@"%@", [operation responseString]);
  } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
    
    DLog(@"%@", [error localizedDescription]);
  }];
  [self enqueueOperation:op];
}

@end
