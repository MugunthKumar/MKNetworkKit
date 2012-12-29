//
//  AuthTestEngine.m
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth Kumar on 4/12/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "AuthTestEngine.h"

@implementation AuthTestEngine

-(void) basicAuthTest {
  
  MKNetworkOperation *op = [self operationWithPath:@"mknetworkkit/basic_auth.php"
                                            params:nil 
                                        httpMethod:@"GET"];
  
  [op setUsername:@"admin" password:@"password" basicAuth:YES];
  
  [op addCompletionHandler:^(MKNetworkOperation *operation) {
    
    DLog(@"%@", [operation responseString]); 
  } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
    
    DLog(@"%@", [error localizedDescription]);         
  }];
  [self enqueueOperation:op];
}


-(void) digestAuthTest {
  
  MKNetworkOperation *op = [self operationWithPath:@"mknetworkkit/digest_auth.php"
                                            params:nil 
                                        httpMethod:@"GET"];
  
  [op setUsername:@"admin" password:@"password"];
  
  [op addCompletionHandler:^(MKNetworkOperation *operation) {
    
    DLog(@"%@", [operation responseString]); 
  } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
    
    DLog(@"%@", [error localizedDescription]);         
  }];
  [self enqueueOperation:op];
}

-(void)digestAuthTestWithUser:(NSString*)username password:(NSString*)password {
  MKNetworkOperation *op = [self operationWithPath:@"mknetworkkit/digest_auth.php"
                                            params:nil 
                                        httpMethod:@"GET"];
  
  [op setUsername:username password:password];
  [op setCredentialPersistence:NSURLCredentialPersistenceNone];
  
  [op addCompletionHandler:^(MKNetworkOperation *operation) {
    
    DLog(@"%@", [operation responseString]); 
  } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
    
    DLog(@"%@", [error localizedDescription]);         
  }];
  [self enqueueOperation:op];
}


-(void) serverTrustTest {
  
  MKNetworkOperation *op = [self operationWithURLString:@"https://testbed.mknetworkkit.com"];  
  
  [op addCompletionHandler:^(MKNetworkOperation *operation) {
    
    DLog(@"%@", [operation responseString]); 
  } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
    
    DLog(@"%@", [error localizedDescription]);         
  }];
  [self enqueueOperation:op];
}

-(void) clientCertTest {
  
  MKNetworkOperation *op = [self operationWithURLString:@"https://testbed.mknetworkkit.com"];
  op.clientCertificate = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"client.p12"];
  op.clientCertificatePassword = @"test";
  
  [op addCompletionHandler:^(MKNetworkOperation *operation) {
    
    DLog(@"%@", [operation responseString]);
  } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
    
    DLog(@"%@", [error localizedDescription]);
  }];
  [self enqueueOperation:op];
}

-(MKNetworkOperation*) uploadImageFromFile:(NSString*) file 
                              completionHandler:(TwitPicBlock) completionBlock
                                   errorHandler:(MKNKErrorBlock) errorBlock {
  
  MKNetworkOperation *op = [self operationWithPath:@"mknetworkkit/upload.php" 
                                            params:@{@"Submit": @"YES"}
                                        httpMethod:@"POST"];
  
  [op addFile:file forKey:@"image"];
  
  // setFreezable uploads your images after connection is restored!
  [op setFreezable:YES];
  
  [op addCompletionHandler:^(MKNetworkOperation* completedOperation) {
    
    NSString *xmlString = [completedOperation responseString];
    
    DLog(@"%@", xmlString);
    completionBlock(xmlString);
  }
           errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
             
             errorBlock(error);
           }];
  
  [self enqueueOperation:op];
  
  
  return op;
}

-(int) cacheMemoryCost {
  return 0;
}

@end
