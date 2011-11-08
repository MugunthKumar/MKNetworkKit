//
//  MKNetworkEngine.m
//  MKNetworkKit
//
//  Created by Mugunth Kumar on 7/11/11.
//  Copyright 2011 Steinlogic. All rights reserved.

#import "MKNetworkEngine.h"
#import "Reachability.h"

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
                [_sharedNetworkQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
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
#pragma mark KVO for network Queue

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == _sharedNetworkQueue && [keyPath isEqualToString:@"operations"]) {
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = 
        ([_sharedNetworkQueue.operations count] == 0);        
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object 
                               change:change context:context];
    }
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
    
    [_sharedNetworkQueue removeObserver:self forKeyPath:@"operations"];
}

-(MKRequest*) requestWithPath:(NSString*) path {
    
    return [self requestWithPath:path body:nil];
}

-(MKRequest*) requestWithPath:(NSString*) path
                         body:(NSMutableDictionary*) body {

    return [self requestWithPath:path 
                     body:body 
               httpMethod:@"GET"];
}

-(MKRequest*) requestWithPath:(NSString*) path
                         body:(NSMutableDictionary*) body
                   httpMethod:(NSString*)method  {
    
    return [self requestWithPath:path body:body httpMethod:method ssl:NO];
}

-(MKRequest*) requestWithPath:(NSString*) path
                         body:(NSMutableDictionary*) body
                   httpMethod:(NSString*)method 
                          ssl:(BOOL) useSSL {
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@", useSSL ? @"https" : @"http", self.hostName, path];
    
    return [self requestWithURLString:urlString body:body httpMethod:method];
}

-(MKRequest*) requestWithURLString:(NSString*) urlString
                         body:(NSMutableDictionary*) body
                   httpMethod:(NSString*)method {

    MKRequest *request = [MKRequest requestWithURLString:urlString body:body httpMethod:method];

#warning possibly incomplete
    // add other relevant app specific code here
    
    return request;
}

-(void) queueRequest:(MKRequest*) request {
    
    [_sharedNetworkQueue addOperation:request];
}
@end
