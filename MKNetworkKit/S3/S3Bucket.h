//
//  S3Bucket.h
//  MKNetworkKit-iOS
//
//  Created by Mugunth on 14/8/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "S3Object.h"

@interface S3Bucket : S3Object

@property (strong, nonatomic) NSString *bucketName;
@property (strong, nonatomic) NSDate *dateCreated;
@end
