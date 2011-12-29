//
//  AuthTestEngine.h
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth Kumar on 4/12/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

@interface AuthTestEngine : MKNetworkEngine

-(void) basicAuthTest;
-(void) digestAuthTest;
-(void) clientCertTest;
@end
