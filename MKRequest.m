//
//  MKRequest.m
//  MKNetworkKit
//
//  Created by Mugunth on 25/2/11
//  Copyright 2011 Steinlogic. All rights reserved.
//

#import "MKRequest.h"

// Private Methods
// this should be added before implementation 
@interface MKRequest (/*Private Methods*/)
@property (strong, nonatomic) NSMutableURLRequest *request;
@property (strong, nonatomic) NSURLResponse *response;

- (id)initWithURLString:(NSString *)aURLString
                   body:(NSMutableDictionary *)body
             httpMethod:(NSString *)method;
@end

@implementation MKRequest
@synthesize request = _request;
@synthesize response = _response;

+ (id)requestWithURLString:(NSString *)urlString
                      body:(NSMutableDictionary *)body
				httpMethod:(NSString *)method
{
	return [[self alloc] initWithURLString:urlString
									   body:body 
								 httpMethod:method];
}

- (id)initWithURLString:(NSString *)aURLString
                   body:(NSMutableDictionary *)body
             httpMethod:(NSString *)method

{	
	NSURL *finalURL = nil;
	if (([method isEqualToString:@"GET"] ||
         [method isEqualToString:@"DELETE"]) && (body && [body count] > 0)) {
		NSMutableString *appendedURL = [aURLString mutableCopy];
		
		[appendedURL appendString:@"?"];
		
		for (NSString *key in body) {
			[appendedURL appendFormat:@"%@=%@&", key, [body valueForKey:key]];	
		}
		
		finalURL = [NSURL URLWithString:appendedURL];
	} else {
		finalURL = [NSURL URLWithString:aURLString];
	}
	
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:finalURL 
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData 
                                                       timeoutInterval:30.0f];
    
    [request setHTTPMethod:method];
    if ([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"]) {

        //[request setHTTPBody:];
    }

	return self;
}

-(NSString*) description
{
    __block NSMutableString *displayString = [NSMutableString stringWithFormat:@"%@\nRequest\n-------\ncurl -X %@", 
                                              [[NSDate date] descriptionWithLocale:[NSLocale currentLocale]],
                                              self.request.HTTPMethod];
    
    [[self.request allHTTPHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id val, BOOL *stop)
     {
         [displayString appendFormat:@" -H \"%@: %@\"", key, val];
     }];
    
    [displayString appendFormat:@" \"%@\"",  [self.request.URL absoluteString]];
    
    if ([self.request.HTTPMethod isEqualToString:@"POST"]) {
        NSString *bodyString = [[NSString alloc] initWithData:self.request.HTTPBody 
                                                      encoding:NSUTF8StringEncoding];
        [displayString appendFormat:@" -d \"%@\"", bodyString];        
    }
    
    /*
    if(self.responseString) {
        [displayString appendFormat:@"\n--------\nResponse\n--------\n%@\n", [self.responseString prettyJSON]];
    }*/
    
    return displayString;
}

#pragma mark -
- (void)main 
{
    @autoreleasepool {
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:self.request 
                                                                      delegate:self 
                                                              startImmediately:YES];   
        
    }    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    self.response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
}

- (void)connection:(NSURLConnection *)connection   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
}

@end
