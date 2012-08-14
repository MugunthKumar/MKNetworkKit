//
//  MKS3Engine.h
//  MKNetworkKit-iOS
//
//  Created by Mugunth Kumar on 15/4/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "../MKNetworkEngine.h"

@class MKS3Operation;

typedef void (^ArrayBlock)(NSMutableArray* listOfModelBaseObjects);
typedef void (^ErrorBlock)(NSError* engineError);
typedef void (^StatusBlock)(int statusCode);

@interface MKS3Engine : MKNetworkEngine

-(id) initWithAccessId:(NSString*) accessId
             secretKey:(NSString*) secretKey;

-(MKS3Operation*) enumerateBucketsOnSucceeded:(ArrayBlock) succeededBlock
                                      onError:(ErrorBlock) errorBlock;

-(MKS3Operation*) enumerateItemsInBucket:(NSString*) bucketName
                                    path:(NSString*) path
                             onSucceeded:(ArrayBlock) succeededBlock
                                 onError:(ErrorBlock) errorBlock;

-(MKS3Operation*) uploadFile:(NSString*) filePath
                  toLocation:(NSString*) location
                 onSucceeded:(ArrayBlock) succeededBlock
                     onError:(ErrorBlock) errorBlock;
@end
