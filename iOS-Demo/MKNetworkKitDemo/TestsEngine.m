//
//  TestsEngine.m
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth on 31/12/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "TestsEngine.h"

@implementation TestsEngine

-(id) initWithDefaultSettings {
  
  if(self = [super initWithHostName:@"testbed2.mknetworkkit.com" customHeaderFields:@{@"x-client-identifier" : @"iOS"}]) {
    
  }
  
  return self;
}

-(void) basicAuthTest {
  
  MKNetworkOperation *op = [self operationWithPath:@"basic_auth.php"
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
  
  MKNetworkOperation *op = [self operationWithPath:@"digest_auth.php"
                                            params:nil
                                        httpMethod:@"GET"];
  
  [op setUsername:@"admin" password:@"password"];
  [op setCredentialPersistence:NSURLCredentialPersistenceNone];
  
  [op addCompletionHandler:^(MKNetworkOperation *operation) {
    
    DLog(@"%@", [operation responseString]);
  } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
    
    DLog(@"%@", [error localizedDescription]);
  }];
  [self enqueueOperation:op];
}

-(MKNetworkOperation*) downloadFatAssFileFrom:(NSString*) remoteURL toFile:(NSString*) filePath {
  
  MKNetworkOperation *op = [self operationWithURLString:remoteURL];
  
  [op addDownloadStream:[NSOutputStream outputStreamToFileAtPath:filePath
                                                          append:YES]];
  
  [self enqueueOperation:op];
  return op;
}

-(MKNetworkOperation*) uploadImageFromFile:(NSString*) file
                         completionHandler:(IDBlock) completionBlock
                              errorHandler:(MKNKErrorBlock) errorBlock {
  
  MKNetworkOperation *op = [self operationWithPath:@"upload.php"
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
@end
