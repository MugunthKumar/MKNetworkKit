//
//  MKRequest.m
//  MKNetworkKit
//
//  Created by Mugunth on 25/2/11
//  Copyright 2011 Steinlogic. All rights reserved.
//

#import "MKNetworkOperation.h"
#import "NSDictionary+RequestEncoding.h"
#import "NSString+MD5.h"

typedef enum {
    MKRequestOperationStateReady = 1,
    MKRequestOperationStateExecuting = 2,
    MKRequestOperationStateFinished = 3
} MKRequestOperationState;

@interface MKNetworkOperation (/*Private Methods*/)
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableURLRequest *request;
@property (strong, nonatomic) NSMutableDictionary *requestDictionary;
@property (strong, nonatomic) NSHTTPURLResponse *response;

@property (strong, nonatomic) NSMutableDictionary *fieldsToBePosted;
@property (strong, nonatomic) NSMutableArray *filesToBePosted;
@property (strong, nonatomic) NSMutableArray *dataToBePosted;

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;

@property (nonatomic, copy) ResponseBlock responseBlock;
@property (nonatomic, copy) ErrorBlock errorBlock;

@property (nonatomic, assign) MKRequestOperationState state;
@property (nonatomic, assign) BOOL isCancelled;

@property (strong, nonatomic) NSMutableData *mutableData;
@property (nonatomic, copy) NSMutableArray *cacheHandlingBlocks;

- (id)initWithURLString:(NSString *)aURLString
                   body:(NSMutableDictionary *)body
             httpMethod:(NSString *)method;
-(NSData*) bodyData;
@end

@implementation MKNetworkOperation
@synthesize connection = _connection;
@synthesize request = _request;
@synthesize requestDictionary = _requestDictionary;
@synthesize response = _response;
@synthesize fieldsToBePosted = _fieldsToBePosted;
@synthesize filesToBePosted = _filesToBePosted;
@synthesize dataToBePosted = _dataToBePosted;
@synthesize username = _username;
@synthesize password = _password;
@synthesize responseBlock = _responseBlock;
@synthesize errorBlock = _errorBlock;
@synthesize isCancelled = _isCancelled;
@synthesize mutableData = _mutableData;
@synthesize cacheHandlingBlocks = _cacheHandlingBlocks;
@synthesize downloadStream = _downloadStream;

@synthesize uploadProgressChangedHandler = _uploadProgressChangedHandler;
@synthesize downloadProgressChangedHandler = _downloadProgressChangedHandler;

@synthesize stringEncoding = _stringEncoding;


-(void) notifyCache {
    
    NSString *str = [NSString stringWithFormat:@"%@-%@-%@", [self.request.URL absoluteString], 
                     self.username ? self.username : @"",
                     self.password ? self.password : @""];

    if([self.response statusCode] >= 200 && [self.response statusCode] < 300) {
        
        for(CacheBlock cacheHander in self.cacheHandlingBlocks)
            cacheHander([str md5], [self responseData]);
    }        
}

-(MKRequestOperationState) state {
    
    return _state;
}

-(void) setState:(MKRequestOperationState)newState {
    
    switch (newState) {
        case MKRequestOperationStateReady:
            [self willChangeValueForKey:@"isReady"];
            break;
        case MKRequestOperationStateExecuting:
            DLog(@"%@", self);
            [self willChangeValueForKey:@"isReady"];
            [self willChangeValueForKey:@"isExecuting"];
            break;
        case MKRequestOperationStateFinished:
            DLog(@"%@", self);
            [self willChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isFinished"];
            break;
    }
    
    _state = newState;
    
    switch (newState) {
        case MKRequestOperationStateReady:
            [self didChangeValueForKey:@"isReady"];
            break;
        case MKRequestOperationStateExecuting:
            [self didChangeValueForKey:@"isReady"];
            [self didChangeValueForKey:@"isExecuting"];
            break;
        case MKRequestOperationStateFinished:
            [self didChangeValueForKey:@"isExecuting"];
            [self didChangeValueForKey:@"isFinished"];
            break;
    }
}

-(void) dealloc {
    
    [_connection cancel];
    _mutableData = nil;
    _connection = nil;
}

+ (id)operationWithURLString:(NSString *)urlString
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
    if((self = [super init])) {
        
        self.stringEncoding = NSUTF8StringEncoding; // use a delegate to get these values later
        self.requestDictionary = body;
        
        NSURL *finalURL = nil;

        self.filesToBePosted = [NSMutableArray array];
        self.dataToBePosted = [NSMutableArray array];
        self.fieldsToBePosted = body;

        if (([method isEqualToString:@"GET"] ||
             [method isEqualToString:@"DELETE"]) && (body && [body count] > 0)) {
            
            finalURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", aURLString, 
                                             [body urlEncodedKeyValueString]]];
        } else {
            finalURL = [NSURL URLWithString:aURLString];
        }
        
        self.request = [NSMutableURLRequest requestWithURL:finalURL                                                           
                                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData                                            
                                           timeoutInterval:30.0f];
        
        [self.request setHTTPMethod:method];
        
        NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
        
        [self.request addValue:
         [NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset]
            forHTTPHeaderField:@"Content-Type"];
        
        if ([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"]) {
            
            // in case of multi-part form request, 
            // this will be automatically over written later
            self.request.HTTPBody = [[[body urlEncodedKeyValueString] dataUsingEncoding:self.stringEncoding] mutableCopy];
        }
        
        self.state = MKRequestOperationStateReady;
    }
    
	return self;
}

-(void) addHeaders:(NSDictionary*) headersDictionary {
    
    [headersDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self.request addValue:obj forHTTPHeaderField:key];
    }];
}

-(NSString*) description
{
    __block NSMutableString *displayString = [NSMutableString stringWithFormat:@"%@\nRequest\n-------\ncurl -X %@", 
                                              [[NSDate date] descriptionWithLocale:[NSLocale currentLocale]],
                                              self.request.HTTPMethod];
    
    if([self.filesToBePosted count] == 0 && [self.dataToBePosted count] == 0) {
    [[self.request allHTTPHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id val, BOOL *stop)
     {
         [displayString appendFormat:@" -H \"%@: %@\"", key, val];
     }];
    }
    
    [displayString appendFormat:@" \"%@\"",  [self.request.URL absoluteString]];
    
    if ([self.request.HTTPMethod isEqualToString:@"POST"] || [self.request.HTTPMethod isEqualToString:@"PUT"]) {

        NSString *option = [self.filesToBePosted count] == 0 ? @"-d" : @"-F";
        [self.requestDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            [displayString appendFormat:@" %@ \"%@=%@\"", option, key, obj];
        }];
         
        [self.filesToBePosted enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            NSDictionary *thisFile = (NSDictionary*) obj;
            [displayString appendFormat:@" -F \"%@=@%@;type=%@\"", [thisFile objectForKey:@"name"],
             [thisFile objectForKey:@"filepath"], [thisFile objectForKey:@"mimetype"]];
        }];
        
        /* Not sure how to do this via curl
        [self.dataToBePosted enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            NSDictionary *thisData = (NSDictionary*) obj;
            [displayString appendFormat:@" --data-binary \"%@\"", [thisData objectForKey:@"data"]];
        }];*/
    }
    
    if(self.mutableData) {
        [displayString appendFormat:@"\n--------\nResponse\n--------\n%@\n", [self responseString]];
    }
    
    return displayString;
}

-(void) addData:(NSData*) data forKey:(NSString*) key {
    
    [self addData:data forKey:key mimeType:@"application/octet-stream"];
}

-(void) addData:(NSData*) data forKey:(NSString*) key mimeType:(NSString*) mimeType {
    
    [self.request setHTTPMethod:@"POST"];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          data, @"data",
                          key, @"name",
                          mimeType, @"mimetype",     
                          nil];
    
    [self.dataToBePosted addObject:dict];    
}

-(void) addFile:(NSString*) filePath forKey:(NSString*) key {
    
    [self addFile:filePath forKey:key mimeType:@"application/octet-stream"];
}

-(void) addFile:(NSString*) filePath forKey:(NSString*) key mimeType:(NSString*) mimeType {

    [self.request setHTTPMethod:@"POST"];

    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
     filePath, @"filepath",
     key, @"name",
     mimeType, @"mimetype",     
     nil];
    
    [self.filesToBePosted addObject:dict];    
}

-(NSData*) bodyData {

    NSString *boundary = @"0xKhTmLbOuNdArY";
    NSMutableData *body = [NSMutableData data];

    [self.fieldsToBePosted enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSString *thisFieldString = [NSString stringWithFormat:
                                     @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n",
                                     boundary, key, obj];
        
        [body appendData:[thisFieldString dataUsingEncoding:[self stringEncoding]]];        
    }];
     
     
    [self.filesToBePosted enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSDictionary *thisFile = (NSDictionary*) obj;
        NSString *thisFieldString = [NSString stringWithFormat:
                                     @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\nContent-Transfer-Encoding: binary\r\n\r\n",
                                     boundary, 
                                     [thisFile objectForKey:@"name"], 
                                     [[thisFile objectForKey:@"filepath"] lastPathComponent], 
                                     [thisFile objectForKey:@"mimetype"]];
        
        [body appendData:[thisFieldString dataUsingEncoding:[self stringEncoding]]];         
        [body appendData: [NSData dataWithContentsOfFile:[thisFile objectForKey:@"filepath"]]];
    }];
    
    [self.dataToBePosted enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSDictionary *thisDataObject = (NSDictionary*) obj;
        NSString *thisFieldString = [NSString stringWithFormat:
                                     @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\nContent-Transfer-Encoding: binary\r\n\r\n",
                                     boundary, 
                                     [thisDataObject objectForKey:@"name"], 
                                     [thisDataObject objectForKey:@"name"], 
                                     [thisDataObject objectForKey:@"mimetype"]];
        
        [body appendData:[thisFieldString dataUsingEncoding:[self stringEncoding]]];         
        [body appendData:[thisDataObject objectForKey:@"data"]];
    }];
   
    [body appendData: [[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:self.stringEncoding]];

    NSLog(@"%@", [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]);
    
        NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));

    if(([self.filesToBePosted count] > 0) || ([self.dataToBePosted count] > 0))
     [self.request setValue:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, boundary] 
         forHTTPHeaderField:@"Content-Type"];
     
    return body;
}

-(void) addCacheHandler:(CacheBlock) cacheHandler {

    if(!self.cacheHandlingBlocks)
        self.cacheHandlingBlocks = [NSMutableArray array];
    
    [self.cacheHandlingBlocks addObject:cacheHandler];
}

#pragma mark -
#pragma Main method
-(void) main {
    
    @autoreleasepool {
        [self start];
    }
}

- (void) start
{
    if(![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    if(!self.isCancelled) {
        
        if ([self.request.HTTPMethod isEqualToString:@"POST"] || [self.request.HTTPMethod isEqualToString:@"PUT"]) {            
            
            [self.request setHTTPBody:[self bodyData]];
        }

        self.connection = [[NSURLConnection alloc] initWithRequest:self.request 
                                                          delegate:self 
                                                  startImmediately:YES]; 
        self.state = MKRequestOperationStateExecuting;
    }
    else {
        self.state = MKRequestOperationStateFinished;
    }
}

#pragma -
#pragma mark NSOperation stuff

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isReady {
    
    return (self.state == MKRequestOperationStateReady);
}

- (BOOL)isFinished 
{
	return (self.state == MKRequestOperationStateFinished);
}

- (BOOL)isExecuting {
    
	return (self.state == MKRequestOperationStateExecuting);
}

-(void) cancel {
    
    if([self isFinished]) return;
    
    [super cancel];
    [self.connection cancel];
    
    self.mutableData = nil;
    self.isCancelled = YES;
    
    if(self.uploadProgressChangedHandler) {
        self.uploadProgressChangedHandler(0.0f);
    }
    if(self.downloadProgressChangedHandler) {
        self.downloadProgressChangedHandler(0.0f);
    }
}

#pragma mark -
#pragma mark NSURLConnection delegates

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    self.mutableData = nil;
    [self.downloadStream close];
    self.state = MKRequestOperationStateFinished;
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
    
    NSUInteger size = [self.response expectedContentLength] < 0 ? 0 : [self.response expectedContentLength];
    self.response = (NSHTTPURLResponse*) response;
    self.mutableData = [NSMutableData dataWithCapacity:size];
    [self.downloadStream open];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    [self.mutableData appendData:data];
    if (self.downloadStream && [self.downloadStream hasSpaceAvailable]) {
            const uint8_t *dataBuffer = [data bytes];
            [self.downloadStream write:&dataBuffer[0] maxLength:[data length]];
    }
    
    if(self.downloadProgressChangedHandler && [self.response expectedContentLength] > 0) {
        
        double progress = (double)[self.mutableData length] / (double)[self.response expectedContentLength];
        self.downloadProgressChangedHandler(progress);
    }    
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    
    if(self.uploadProgressChangedHandler && totalBytesExpectedToWrite > 0) {
        self.uploadProgressChangedHandler(((double)totalBytesWritten/(double)totalBytesExpectedToWrite));
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    [self.downloadStream close];
    
    self.state = MKRequestOperationStateFinished;
    self.responseBlock(self);
    [self notifyCache];
}

#pragma mark -
#pragma mark Our methods to get data

-(NSData*) responseData {
    
    if([self isFinished])
        return [self.mutableData copy];
    else
        return nil;
}

-(NSString*)responseString {
    
    return [self responseStringWithEncoding:self.stringEncoding];
}

-(NSString*) responseStringWithEncoding:(NSStringEncoding) encoding {
    
    if([self isFinished])
        return [[NSString alloc] initWithData:self.mutableData encoding:encoding];
    else
        return nil;
}

#ifdef __IPHONE_5_0
-(id) responseJSON {
    
    NSError *error = nil;
    id returnValue = [NSJSONSerialization JSONObjectWithData:self.mutableData options:0 error:&error];    
    DLog(@"JSON Parsing Error: %@", error);
    return returnValue;
}
#endif

@end
