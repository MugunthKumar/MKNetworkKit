//
//  MKS3Operation.h
//  MKNetworkKit-iOS
//
//  Created by Mugunth Kumar on 15/4/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "MKNetworkOperation.h"

@interface MKS3Operation : MKNetworkOperation
-(void) signWithAccessId:(NSString*) accessId secretKey:(NSString*) password;
@end
