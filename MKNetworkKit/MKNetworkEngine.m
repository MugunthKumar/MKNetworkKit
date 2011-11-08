//
//  MKNetworkEngine.m
//  MKNetworkKit
//
//  Created by Mugunth Kumar on 7/11/11.
//  Copyright 2011 Steinlogic. All rights reserved.

#import "MKNetworkEngine.h"
#import "Reachability.h"

// Private Methods
// this should be added before implementation 
@interface MKNetworkEngine (/*Private Methods*/)

@property (strong, nonatomic) NSString *hostName;
@property (strong, nonatomic) Reachability *reachability;

@end

static NSOperationQueue *_sharedNetworkQueue;

@implementation MKNetworkEngine
@synthesize hostName = _hostName;
@synthesize reachability = _reachability;

// Network Queue is a shared singleton object.
// no matter how many instances of MKNetworkEngine is created, there is one and only one network queue
// In theory any app contains as many network engines as domains

- (id) initWithHostName:(NSString*) hostName customHeaderFields:(NSDictionary*) headers {
    
    if((self = [super init])) {
        
        if(!_sharedNetworkQueue) {
            static dispatch_once_t oncePredicate;
            dispatch_once(&oncePredicate, ^{
                _sharedNetworkQueue = [[NSOperationQueue alloc] init];
                [_sharedNetworkQueue setMaxConcurrentOperationCount:6];

            });
        }        
    }
    
    self.hostName = hostName;
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(reachabilityChanged:) 
                                                 name:kReachabilityChangedNotification 
                                               object:nil];
    
    self.reachability = [Reachability reachabilityWithHostName:self.hostName];
    [self.reachability startNotifier];

    return self;
}


#pragma mark -
#pragma mark Reachability related methods

-(void) reachabilityChanged:(NSNotification*) notification
{
    if([self.reachability currentReachabilityStatus] == ReachableViaWiFi)
    {
        DLog(@"Server [%@] is reachable via Wifi", self.hostName);
        [_sharedNetworkQueue setMaxConcurrentOperationCount:6];
    }
    else if([self.reachability currentReachabilityStatus] == ReachableViaWWAN)
    {
        DLog(@"Server [%@] is reachable only via cellular data", self.hostName);
        [_sharedNetworkQueue setMaxConcurrentOperationCount:2];
    }
    else if([self.reachability currentReachabilityStatus] == NotReachable)
    {
        DLog(@"Server [%@] is not reachable", self.hostName);
        [_sharedNetworkQueue setMaxConcurrentOperationCount:0];
    }        
}

-(BOOL) isReachable {
    
    return ([self.reachability currentReachabilityStatus] != NotReachable);
}
    
-(void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

-(MKRequest*) requestWithPath:(NSString*) path
                         body:(NSMutableDictionary*) body
                   httpMethod:method  {
    
    return [self requestWithPath:path body:body httpMethod:method ssl:NO];
}

-(MKRequest*) requestWithPath:(NSString*) path
                              body:(NSMutableDictionary*) body
                        httpMethod:method 
                          ssl:(BOOL) useSSL {
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@", useSSL ? @"https" : @"http", self.hostName, path];
    MKRequest *request = [MKRequest requestWithURLString:urlString body:body httpMethod:method];
    // add other relevant app specific code here
    
    [request onCompletion:^(NSString* responseString) {
        
    }
                  onError:^(NSError* error) {
                      
                  }];
    return request;
}

-(void) queueRequest:(MKRequest*) request {
    
    DLog(@"%@", request);
    [_sharedNetworkQueue addOperation:request];
}
@end
