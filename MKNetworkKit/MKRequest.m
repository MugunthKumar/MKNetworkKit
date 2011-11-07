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
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableURLRequest *request;
@property (strong, nonatomic) NSURLResponse *response;
@property (strong, nonatomic) NSString *responseString;
@property (strong, nonatomic) NSMutableData *responseData;

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;

@property (nonatomic, copy) ResponseBlock responseBlock;
@property (nonatomic, copy) ErrorBlock errorBlock;

- (id)initWithURLString:(NSString *)aURLString
                   body:(NSMutableDictionary *)body
             httpMethod:(NSString *)method;
@end

@implementation MKRequest
@synthesize connection = _connection;
@synthesize request = _request;
@synthesize response = _response;
@synthesize responseString = _responseString;
@synthesize responseData = _responseData;

@synthesize username = _username;
@synthesize password = _password;

@synthesize responseBlock = _responseBlock;
@synthesize errorBlock = _errorBlock;

-(void) dealloc {
    
    [_connection cancel];
    _connection = nil;
}

+ (id)requestWithURLString:(NSString *)urlString
                      body:(NSMutableDictionary *)body
				httpMethod:(NSString *)method
{
	return [[self alloc] initWithURLString:urlString
                                      body:body 
                                httpMethod:method];
}

-(void) setUsername:(NSString*) username password:(NSString*) password {
    
    self.username = username;
    self.password = password;
}

-(void) onCompletion:(ResponseBlock) response onError:(ErrorBlock) error {
    
    self.responseBlock = response;
    self.errorBlock = error;
}

- (id)initWithURLString:(NSString *)aURLString
                   body:(NSMutableDictionary *)body
             httpMethod:(NSString *)method

{	
	NSURL *finalURL = nil;
    NSMutableString *bodyString = [NSMutableString string];
    
    for (NSString *key in body) {
        [bodyString appendFormat:@"%@=%@&", key, [body valueForKey:key]];	
    }
    
    // knock off the trailing &
    if([bodyString length] > 0)
        [bodyString deleteCharactersInRange:NSMakeRange([bodyString length] - 1, 1)];
    
	if (([method isEqualToString:@"GET"] ||
         [method isEqualToString:@"DELETE"]) && (body && [body count] > 0)) {
        
		finalURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", aURLString, bodyString]];
	} else {
		finalURL = [NSURL URLWithString:aURLString];
	}
	
    self.request = [NSMutableURLRequest requestWithURL:finalURL                                                           
                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData                                            
                                       timeoutInterval:30.0f];
    
    [self.request setHTTPMethod:method];

	[self.request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    if ([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"]) {
        
        [self.request setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
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
    
    if ([self.request.HTTPMethod isEqualToString:@"POST"] || [self.request.HTTPMethod isEqualToString:@"PUT"]) {
        NSString *bodyString = [[NSString alloc] initWithData:self.request.HTTPBody 
                                                     encoding:NSUTF8StringEncoding];
        [displayString appendFormat:@" -d \"%@\"", bodyString];        
    }
    
    
    if(self.responseData) {
        [displayString appendFormat:@"\n--------\nResponse\n--------\n%@\n", 
         [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]];
    }
    
    return displayString;
}

-(void) addFile:(NSString*) filePath forKey:(NSString*) key {
    
}

#pragma mark -
#pragma Main method
- (void)main 
{
    @autoreleasepool {
        
        self.connection = [[NSURLConnection alloc] initWithRequest:self.request 
                                                          delegate:self 
                                                  startImmediately:YES];        
    }    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    self.errorBlock(error);    
}


- (void)connection:(NSURLConnection *)connection 
willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    if(!(self.username && self.password)) {
        [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
    else {
        NSURLCredential *credential = [NSURLCredential credentialWithUser:self.username 
                                                                 password:self.password
                                                              persistence:NSURLCredentialPersistenceForSession];
        
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    self.response = response;
    self.responseData = [NSMutableData dataWithCapacity:[self.response expectedContentLength]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
        
    self.responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    self.responseBlock(self.responseString);
}

@end
