//
//  S3Bucket.m
//  MKNetworkKit-iOS
//
//  Created by Mugunth on 14/8/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "S3Bucket.h"
@interface S3Bucket (/*Private Methods*/)
@property (strong, nonatomic) NSString *Name;
@property (strong, nonatomic) NSString *CreationDate;
@end

@implementation S3Bucket

-(void) setValue:(id)value forKey:(NSString *)key {
  
  if([key isEqualToString:@"Name"]) {
    self.bucketName = value;
    self.Name = value;
  }
  else if([key isEqualToString:@"CreationDate"]) {
    self.CreationDate = value;
    self.dateCreated = [NSDate dateFromTZString:value];
  }
  else [super setValue:value forKey:key];
}

@end
