//
//  MKS3Operation.m
//  MKNetworkKit-iOS
//
//  Created by Mugunth Kumar on 15/4/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "MKS3Operation.h"

@implementation MKS3Operation

/*
 Authorization = "AWS" + " " + AWSAccessKeyId + ":" + Signature;
 
 Signature = Base64( HMAC-SHA1( UTF-8-Encoding-Of( YourSecretAccessKeyID, StringToSign ) ) );
 
 StringToSign = HTTP-Verb + "\n" +
 Content-MD5 + "\n" +
 Content-Type + "\n" +
 Date + "\n" +
 CanonicalizedAmzHeaders +
 CanonicalizedResource;
 
 CanonicalizedResource = [ "/" + Bucket ] +
 <HTTP-Request-URI, from the protocol name up to the query string> +
 [ sub-resource, if present. For example "?acl", "?location", "?logging", or "?torrent"];
 
 CanonicalizedAmzHeaders = <described below>
 */

-(void) signWithAccessId:(NSString*) accessId secretKey:(NSString*) password {
  
  NSMutableString *stringToSign = [NSMutableString string];
  [stringToSign appendFormat:@"%@\n", self.readonlyRequest.HTTPMethod];
  
  NSString *bodyString = [[NSString alloc] initWithData:[self bodyData] encoding:NSUTF8StringEncoding];
  NSString *bodyMD5Hash = nil;
  if([bodyString length] == 0) bodyMD5Hash = @""; else bodyMD5Hash = [bodyString md5];
  
  [stringToSign appendFormat:@"%@\n", bodyMD5Hash];
  
  NSString *contentTypeMD5Hash = [[self.readonlyRequest valueForHTTPHeaderField:@"Content-Type"] md5];
  if(!contentTypeMD5Hash) contentTypeMD5Hash = @"";
  [stringToSign appendFormat:@"%@\n", contentTypeMD5Hash];

  NSString *canonicalizedAmazonHeaders = @"";
  [stringToSign appendFormat:@"%@\n", canonicalizedAmazonHeaders];

  NSString *dateString = [[NSDate date] amazonDateFormatString];  
  [stringToSign appendFormat:@"x-amz-date:%@\n", dateString];
    
  NSString *pathToResource = [self.readonlyRequest.URL path];
  [stringToSign appendString:pathToResource];
  
  DLog(@"String to sign: \n--\n%@\n--\n", stringToSign);
  NSString *signature = [[stringToSign dataByEncryptingWithPassword:password] base64EncodedString];
  
  NSString *awsAuthHeaderValue = [NSString stringWithFormat:@"AWS %@:%@", accessId, signature];
  [self addHeaders:[NSDictionary dictionaryWithObjectsAndKeys:
                    awsAuthHeaderValue, @"Authorization",
                    dateString, @"x-amz-date", nil]];
}
@end
