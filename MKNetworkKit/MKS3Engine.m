//
//  MKS3Engine.m
//  MKNetworkKit-iOS
//
//  Created by Mugunth Kumar on 15/4/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "MKS3Engine.h"
// Private Methods
// this should be added before implementation 
@interface MKS3Engine (/*Private Methods*/)

@property (strong, nonatomic) NSString *accessId;
@property (strong, nonatomic) NSString *secretKey;
@end

@implementation MKS3Engine
@synthesize accessId = _accessId;
@synthesize secretKey = _secretKey;

-(id) initWithAccessId:(NSString*) accessId 
             secretKey:(NSString*) secretKey {
  
  if((self = [super initWithHostName:@"s3.amazonaws.com" customHeaderFields:nil])) {
    
    self.accessId = accessId;
    self.secretKey = secretKey;
    [self registerOperationSubclass:[MKS3Operation class]];
  }
  
  return self;
}

-(void) prepareHeaders:(MKNetworkOperation *)operation {

  MKS3Operation *op = (MKS3Operation*) operation;
  [op signWithAccessId:self.accessId secretKey:self.secretKey];
  [super prepareHeaders:operation];
}

-(void) enumerateBucketsOnSucceeded:(ArrayBlock) succeededBlock 
                            onError:(ErrorBlock) errorBlock {
  
  MKS3Operation *op = (MKS3Operation*) [self operationWithPath:@""];  
  
  [op onCompletion:^(MKNetworkOperation *completedOperation) {
  
    DLog(@"%@", [completedOperation responseString]);
    
  } onError:^(NSError *error) {
    
  }];
  
  [self enqueueOperation:op];
}

-(void) enumerateItemsInBucket:(NSString*) bucketId 
                   onSucceeded:(ArrayBlock) succeededBlock 
                       onError:(ErrorBlock) errorBlock {
  
}

-(void) uploadFile:(NSString*) filePath 
        toLocation:(NSString*) location 
       onSucceeded:(ArrayBlock) succeededBlock 
           onError:(ErrorBlock) errorBlock {
  
}

@end
