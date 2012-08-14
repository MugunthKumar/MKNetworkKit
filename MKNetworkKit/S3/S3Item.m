//
//  S3Item.m
//  MKNetworkKit-iOS
//
//  Created by Mugunth on 14/8/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "S3Item.h"

/*
 <Key>
 index.html
 </Key>
 <LastModified>
 2011-07-14T06:37:23.000Z
 </LastModified>
 <ETag>
 "c94e626aed05532367aa220bed617f18"
 </ETag>
 <Size>
 19
 </Size>
 <StorageClass>
 REDUCED_REDUNDANCY
 </StorageClass>
 */
@interface S3Item (/*Private Methods*/)
@property (strong, nonatomic) NSString *Key;
@property (strong, nonatomic) NSString *LastModified;
@property (strong, nonatomic) NSString *ETag;
@property (strong, nonatomic) NSString *Size;
@property (strong, nonatomic) NSString *StorageClass;
@end

@implementation S3Item

@end
