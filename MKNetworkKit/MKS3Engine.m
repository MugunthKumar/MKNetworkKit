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
  }
  
  return self;
}

-(void) enumerateBucketsOnSucceeded:(ArrayBlock) succeededBlock 
                            onError:(ErrorBlock) errorBlock {
  
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
