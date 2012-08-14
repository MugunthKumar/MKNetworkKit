//
//  MKS3Engine.m
//  MKNetworkKit-iOS
//
//  Created by Mugunth Kumar on 15/4/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "MKS3Engine.h"
#import "MKS3Operation.h"

#import "S3Bucket.h"
#import "S3Item.h"

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

-(MKS3Operation*) enumerateBucketsOnSucceeded:(ArrayBlock) succeededBlock
                                      onError:(ErrorBlock) errorBlock {
  
  MKS3Operation *op = (MKS3Operation*) [self operationWithPath:@""];
  
  [op onCompletion:^(MKNetworkOperation *completedOperation) {
    
    NSArray *listOfBucketsInXml = [[[[[[DDXMLDocument alloc] initWithXMLString:[completedOperation responseString]
                                                                       options:0 error:nil]
                                      rootElement] elementsForName:@"Buckets"] objectAtIndex:0] children];
    
    NSMutableArray *listOfBuckets = [NSMutableArray arrayWithCapacity:[listOfBucketsInXml count]];
    [listOfBucketsInXml enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      
      S3Bucket *thisBucket = [[S3Bucket alloc] initWithDDXMLElement:obj];
      [listOfBuckets addObject:thisBucket];
    }];
    
    succeededBlock(listOfBuckets);
  } onError:^(NSError *error) {
    
  }];
  
  [self enqueueOperation:op];
  
  return op;
}

-(MKS3Operation*) enumerateItemsInBucket:(NSString*) bucketName
                                    path:(NSString*) path
                             onSucceeded:(ArrayBlock) succeededBlock
                                 onError:(ErrorBlock) errorBlock {
  
  NSString *urlWithBucket = [NSString stringWithFormat:@"http://%@.%@", bucketName, [self readonlyHostName]];
  if(path)
    urlWithBucket = [urlWithBucket stringByAppendingFormat:@"/%@", path];
  
  MKS3Operation *op = (MKS3Operation*) [self operationWithURLString:urlWithBucket];
  
  [op onCompletion:^(MKNetworkOperation *completedOperation) {
    
    NSArray *listOfItemsInXml = [[[[[[DDXMLDocument alloc] initWithXMLString:[completedOperation responseString]
                                                                       options:0 error:nil]
                                      rootElement] elementsForName:@"Contents"] objectAtIndex:0] children];
    
    NSMutableArray *listOfItems = [NSMutableArray arrayWithCapacity:[listOfItemsInXml count]];
    [listOfItemsInXml enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      
      S3Item *thisBucket = [[S3Item alloc] initWithDDXMLElement:obj];
      [listOfItems addObject:thisBucket];
    }];
    
    succeededBlock(listOfItems);
  } onError:errorBlock];
  
  [self enqueueOperation:op];
  
  return op;
}

-(MKS3Operation*) uploadFile:(NSString*) filePath
                  toLocation:(NSString*) location
                 onSucceeded:(ArrayBlock) succeededBlock
                     onError:(ErrorBlock) errorBlock {
  
  return nil;
}

@end
