//
//  ExampleDownloader.h
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 25/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "MKNetworkEngine.h"

@interface ExampleDownloader : MKNetworkEngine

-(MKNetworkOperation*) downloadFatAssFileFrom:(NSString*) remoteURL toFile:(NSString*) fileName;
@end
