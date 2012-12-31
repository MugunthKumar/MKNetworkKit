//
//  TestsEngine.h
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth on 31/12/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

typedef void (^IDBlock)(id object);

@interface TestsEngine : MKNetworkEngine

-(id) initWithDefaultSettings;
-(void) basicAuthTest;
-(void) digestAuthTest;

-(MKNetworkOperation*) downloadFatAssFileFrom:(NSString*) remoteURL toFile:(NSString*) filePath;

-(MKNetworkOperation*) uploadImageFromFile:(NSString*) file
                         completionHandler:(IDBlock) completionBlock
                              errorHandler:(MKNKErrorBlock) errorBlock;

@end
