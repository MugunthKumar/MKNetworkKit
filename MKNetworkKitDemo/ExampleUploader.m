//
//  ExampleUploader.m
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 25/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "ExampleUploader.h"

@implementation ExampleUploader

-(MKNetworkOperation*) uploadImageFromFile:(NSString*) file {
    
    MKNetworkOperation *op = [self requestWithPath:@"upload" 
                                              body:nil
                                        httpMethod:@"POST"];
    
    [op addFile:file forKey:@"media"];
    
    [self enqueueOperation:op];
    return op;
}

@end
