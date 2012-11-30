//
//  MKNetworkKit_Tests.m
//  MKNetworkKit-Tests
//
//  Created by Victor Ilyukevich on 30.11.12.
//
//

#import "MKNetworkKit_Tests.h"

@implementation MKNetworkKit_Tests

- (void)testExample {
    MKNetworkEngine *engine = [[MKNetworkEngine alloc] init];
    STAssertNotNil(engine, @"Network engine should be initialized");
}

@end
