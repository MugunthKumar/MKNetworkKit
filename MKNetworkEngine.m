//
//  MKNetworkEngine.m
//  MKNetworkKit
//
//  Created by Mugunth Kumar on 7/11/11.
//  Copyright 2011 Steinlogic. All rights reserved.
//	File created using Singleton XCode Template by Mugunth Kumar (http://blog.mugunthkumar.com)
//  More information about this template on the post http://mk.sg/89	
//  Permission granted to do anything, commercial/non-commercial with this file apart from removing the line/URL above

#import "MKNetworkEngine.h"
#import "Reachability.h"

// Private Methods
// this should be added before implementation 
@interface MKNetworkEngine (/*Private Methods*/)

@property (strong, nonatomic) NSOperationQueue *networkQueue;
@property (strong, nonatomic) NSString *hostName;
@property (strong, nonatomic) Reachability *reachability;

@end


@implementation MKNetworkEngine
@synthesize networkQueue = _networkQueue;
@synthesize hostName = _hostName;
@synthesize reachability = _reachability;

#pragma mark -
#pragma mark Singleton Methods

+ (MKNetworkEngine*)sharedEngine {
    
	static MKNetworkEngine *_sharedInstance;
	if(!_sharedInstance) {
		static dispatch_once_t oncePredicate;
		dispatch_once(&oncePredicate, ^{
			_sharedInstance = [[self alloc] init];
        });
    }
    
    _sharedInstance.networkQueue = [[NSOperationQueue alloc] init];
    [_sharedInstance.networkQueue setMaxConcurrentOperationCount:6];
    [[NSNotificationCenter defaultCenter] addObserver:_sharedInstance 
                                             selector:@selector(reachabilityChanged:) 
                                                 name:kReachabilityChangedNotification 
                                               object:nil];
    
    _sharedInstance.reachability = [Reachability reachabilityWithHostName:[_sharedInstance hostName]];
    [_sharedInstance.reachability startNotifier];

    return _sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {	
    
	return [self sharedEngine];
}


- (id)copyWithZone:(NSZone *)zone {
	return self;	
}

#if (!__has_feature(objc_arc))

- (id)retain {	
    
	return self;	
}

- (unsigned)retainCount {
	return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release {
	//do nothing
}

- (id)autorelease {
    
	return self;	
}
#endif


#pragma mark -
#pragma mark Reachability related methods

-(void) reachabilityChanged:(NSNotification*) notification
{
    if([self.reachability currentReachabilityStatus] == ReachableViaWiFi)
    {
        DLog(@"Reachable via WiFi");
        [self.networkQueue setMaxConcurrentOperationCount:6];
    }
    else if([self.reachability currentReachabilityStatus] == kReachableViaWWAN)
    {
        DLog(@"Reachable via 3G");
        [self.networkQueue setMaxConcurrentOperationCount:2];
    }
    else if([self.reachability currentReachabilityStatus] == kNotReachable)
    {
        DLog(@"Server not reachable");
        [self.networkQueue setMaxConcurrentOperationCount:0];
    }        
}

-(BOOL) isReachable {
    
    return ([self.reachability currentReachabilityStatus] != kNotReachable);
}

@end
