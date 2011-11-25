//
//  ExampleDownloader.m
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 25/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "ExampleDownloader.h"

@implementation ExampleDownloader


-(MKNetworkOperation*) downloadFatAssFileFrom:(NSString*) remoteURL toFile:(NSString*) filePath {
    
    MKNetworkOperation *op = [self requestWithURLString:remoteURL 
                                                        body:nil
                                                  httpMethod:@"GET"];
    
    [op setDownloadStream:[NSOutputStream outputStreamToFileAtPath:filePath
                                                                 append:YES]];
    
    [self enqueueOperation:op];
    return op;
}
@end
