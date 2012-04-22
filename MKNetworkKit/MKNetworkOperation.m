//
//  MKNetworkOperation.m
//  MKNetworkKit
//
//  Created by Mugunth Kumar (@mugunthkumar) on 11/11/11.
//  Copyright (C) 2011-2020 by Steinlogic

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "MKNetworkKit.h"

#ifdef __OBJC_GC__
#error MKNetworkKit does not support Objective-C Garbage Collection
#endif

#if ! __has_feature(objc_arc)
#error MKNetworkKit is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

@interface MKNetworkOperation (/*Private Methods*/)
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSString *uniqueId;
@property (strong, nonatomic) NSMutableURLRequest *request;
@property (strong, nonatomic) NSHTTPURLResponse *response;

@property (strong, nonatomic) NSMutableDictionary *fieldsToBePosted;
@property (strong, nonatomic) NSMutableArray *filesToBePosted;
@property (strong, nonatomic) NSMutableArray *dataToBePosted;

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;

@property (nonatomic, strong) NSMutableArray *responseBlocks;
@property (nonatomic, strong) NSMutableArray *errorBlocks;

@property (nonatomic, assign) MKNetworkOperationState state;
@property (nonatomic, assign) BOOL isCancelled;

@property (strong, nonatomic) NSMutableData *mutableData;
@property (assign, nonatomic) NSUInteger downloadedDataSize;

@property (nonatomic, strong) NSMutableArray *uploadProgressChangedHandlers;
@property (nonatomic, strong) NSMutableArray *downloadProgressChangedHandlers;
@property (nonatomic, copy) MKNKEncodingBlock postDataEncodingHandler;

@property (nonatomic, assign) NSInteger startPosition;

@property (nonatomic, strong) NSMutableArray *downloadStreams;
@property (nonatomic, strong) NSData *cachedResponse;
@property (nonatomic, copy) MKNKResponseBlock cacheHandlingBlock;

#if TARGET_OS_IPHONE    
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskId;
#endif

@property (strong, nonatomic) NSError *error;

- (id)initWithURLString:(NSString *)aURLString
                 params:(NSMutableDictionary *)body
             httpMethod:(NSString *)method;

-(NSData*) bodyData;

-(NSString*) encodedPostDataString;
- (void) showLocalNotification;
- (void) endBackgroundTask;

@end

@implementation MKNetworkOperation
@synthesize postDataEncodingHandler = _postDataEncodingHandler;

@synthesize stringEncoding = _stringEncoding;
@dynamic freezable;
@synthesize uniqueId = _uniqueId; // freezable operations have a unique id

@synthesize connection = _connection;

@synthesize request = _request;
@synthesize response = _response;

@synthesize fieldsToBePosted = _fieldsToBePosted;
@synthesize filesToBePosted = _filesToBePosted;
@synthesize dataToBePosted = _dataToBePosted;

@synthesize username = _username;
@synthesize password = _password;
@synthesize clientCertificate = _clientCertificate;
@synthesize authHandler = _authHandler;
@synthesize operationStateChangedHandler = _operationStateChangedHandler;

@synthesize responseBlocks = _responseBlocks;
@synthesize errorBlocks = _errorBlocks;

@synthesize isCancelled = _isCancelled;
@synthesize mutableData = _mutableData;
@synthesize downloadedDataSize = _downloadedDataSize;

@synthesize uploadProgressChangedHandlers = _uploadProgressChangedHandlers;
@synthesize downloadProgressChangedHandlers = _downloadProgressChangedHandlers;

@synthesize downloadStreams = _downloadStreams;

@synthesize cachedResponse = _cachedResponse;
@synthesize cacheHandlingBlock = _cacheHandlingBlock;
@synthesize credentialPersistence = _credentialPersistence;

@synthesize startPosition = _startPosition;

#if TARGET_OS_IPHONE    
@synthesize backgroundTaskId = _backgroundTaskId;
@synthesize localNotification = localNotification_;
@synthesize shouldShowLocalNotificationOnError = shouldShowLocalNotificationOnError_;
#endif

@synthesize cacheHeaders = _cacheHeaders;
@synthesize error = _error;


// A RESTful service should always return the same response for a given URL and it's parameters.
// this means if these values are correct, you can cache the responses
// This is another reason why we check only GET methods.
// even if URL and others are same, POST, DELETE, PUT methods should not be cached and should not be treated equal.

-(BOOL) isCacheable {
  
  return [self.request.HTTPMethod isEqualToString:@"GET"];
}


//=========================================================== 
// + (BOOL)automaticallyNotifiesObserversForKey:
//
//=========================================================== 
+ (BOOL)automaticallyNotifiesObserversForKey: (NSString *)theKey 
{
  BOOL automatic;
  
  if ([theKey isEqualToString:@"postDataEncoding"]) {
    automatic = NO;
  } else {
    automatic = [super automaticallyNotifiesObserversForKey:theKey];
  }
  
  return automatic;
}

//=========================================================== 
//  postDataEncoding 
//=========================================================== 
- (MKNKPostDataEncodingType)postDataEncoding
{
  return _postDataEncoding;
}
- (void)setPostDataEncoding:(MKNKPostDataEncodingType)aPostDataEncoding
{
  if (_postDataEncoding != aPostDataEncoding) {
    [self willChangeValueForKey:@"postDataEncoding"];
    _postDataEncoding = aPostDataEncoding;
    
    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
    
    switch (self.postDataEncoding) {
        
      case MKNKPostDataEncodingTypeURL: {
        [self.request setValue:
         [NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset]
            forHTTPHeaderField:@"Content-Type"];
      }
        break;
      case MKNKPostDataEncodingTypeJSON: {
        if([NSJSONSerialization class]) {
          [self.request setValue:
           [NSString stringWithFormat:@"application/json; charset=%@", charset]
              forHTTPHeaderField:@"Content-Type"];
        } else {
          [self.request setValue:
           [NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset]
              forHTTPHeaderField:@"Content-Type"];
        }
      }
        break;
      case MKNKPostDataEncodingTypePlist: {
        [self.request setValue:
         [NSString stringWithFormat:@"application/x-plist; charset=%@", charset]
            forHTTPHeaderField:@"Content-Type"];
      }
        
      default:
        break;
    }
    [self didChangeValueForKey:@"postDataEncoding"];
  }
}

-(NSString*) encodedPostDataString {
  
  NSString *returnValue = @"";
  if(self.postDataEncodingHandler)
    returnValue = self.postDataEncodingHandler(self.fieldsToBePosted);    
  else if(self.postDataEncoding == MKNKPostDataEncodingTypeURL)
    returnValue = [self.fieldsToBePosted urlEncodedKeyValueString];    
  else if(self.postDataEncoding == MKNKPostDataEncodingTypeJSON)
    returnValue = [self.fieldsToBePosted jsonEncodedKeyValueString];
  else if(self.postDataEncoding == MKNKPostDataEncodingTypePlist)
    returnValue = [self.fieldsToBePosted plistEncodedKeyValueString];
  return returnValue;
}

-(void) setCustomPostDataEncodingHandler:(MKNKEncodingBlock) postDataEncodingHandler forType:(NSString*) contentType {
  
  NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
  self.postDataEncoding = MKNKPostDataEncodingTypeCustom;
  self.postDataEncodingHandler = postDataEncodingHandler;
  [self.request setValue:
   [NSString stringWithFormat:@"%@; charset=%@", contentType, charset]
      forHTTPHeaderField:@"Content-Type"];
}
//=========================================================== 
//  freezable 
//=========================================================== 
- (BOOL)freezable
{
  return _freezable;
}

-(NSString*) url {
  
  return [[self.request URL] absoluteString];
}

-(NSURLRequest*) readonlyRequest {
  
  return [self.request copy];
}

-(NSHTTPURLResponse*) readonlyResponse {
  
  return [self.response copy];
}

- (NSDictionary *) readonlyPostDictionary {
  
  return [self.fieldsToBePosted copy];
}

-(NSString*) HTTPMethod {
  
  return self.request.HTTPMethod;
}

-(NSInteger) HTTPStatusCode {
  
  if(self.response)
    return self.response.statusCode;
  else
    return 0;
}

- (void)setFreezable:(BOOL)flag
{
  // get method cannot be frozen. 
  // No point in freezing a method that doesn't change server state.
  if([self.request.HTTPMethod isEqualToString:@"GET"] && flag) return;
  _freezable = flag;
  
  if(_freezable && self.uniqueId == nil)
    self.uniqueId = [NSString uniqueString];
}


-(BOOL) isEqual:(id)object {
  
  if([self.request.HTTPMethod isEqualToString:@"GET"] || [self.request.HTTPMethod isEqualToString:@"HEAD"]) {
    
    MKNetworkOperation *anotherObject = (MKNetworkOperation*) object;
    return ([[self uniqueIdentifier] isEqualToString:[anotherObject uniqueIdentifier]]);
  }
  
  return NO;
}


-(NSString*) uniqueIdentifier {
  
  NSMutableString *str = [NSMutableString stringWithFormat:@"%@ %@", self.request.HTTPMethod, self.url];
  
  if(self.username || self.password) {
    
    [str appendFormat:@" [%@:%@]",
     self.username ? self.username : @"",
     self.password ? self.password : @""];
  }
  
  if(self.freezable) {
    
    [str appendString:self.uniqueId];
  }
  return [str md5];
}

-(BOOL) isCachedResponse {
  
  return self.cachedResponse != nil;
}

-(void) notifyCache {
  
  if(![self isCacheable]) return;
  if(!([self.response statusCode] >= 200 && [self.response statusCode] < 300)) return;
  
  if(![self isCancelled])   
    self.cacheHandlingBlock(self);
}

-(MKNetworkOperationState) state {
  
  return _state;
}

-(void) setState:(MKNetworkOperationState)newState {
  
  switch (newState) {
    case MKNetworkOperationStateReady:
      [self willChangeValueForKey:@"isReady"];
      break;
    case MKNetworkOperationStateExecuting:
      [self willChangeValueForKey:@"isReady"];
      [self willChangeValueForKey:@"isExecuting"];
      break;
    case MKNetworkOperationStateFinished:
      [self willChangeValueForKey:@"isExecuting"];
      [self willChangeValueForKey:@"isFinished"];
      break;
  }
  
  _state = newState;
  
  switch (newState) {
    case MKNetworkOperationStateReady:
      [self didChangeValueForKey:@"isReady"];
      break;
    case MKNetworkOperationStateExecuting:
      [self didChangeValueForKey:@"isReady"];
      [self didChangeValueForKey:@"isExecuting"];
      break;
    case MKNetworkOperationStateFinished:
      [self didChangeValueForKey:@"isExecuting"];
      [self didChangeValueForKey:@"isFinished"];
      break;
  }
  
  if(self.operationStateChangedHandler) {
    self.operationStateChangedHandler(newState);
  }
}

- (void)encodeWithCoder:(NSCoder *)encoder 
{
  [encoder encodeInteger:self.stringEncoding forKey:@"stringEncoding"];
  [encoder encodeObject:self.uniqueId forKey:@"uniqueId"];
  [encoder encodeObject:self.request forKey:@"request"];
  [encoder encodeObject:self.response forKey:@"response"];
  [encoder encodeObject:self.fieldsToBePosted forKey:@"fieldsToBePosted"];
  [encoder encodeObject:self.filesToBePosted forKey:@"filesToBePosted"];
  [encoder encodeObject:self.dataToBePosted forKey:@"dataToBePosted"];
  [encoder encodeObject:self.username forKey:@"username"];
  [encoder encodeObject:self.password forKey:@"password"];
  [encoder encodeObject:self.clientCertificate forKey:@"clientCertificate"];
  
  self.state = MKNetworkOperationStateReady;
  [encoder encodeInt32:_state forKey:@"state"];
  [encoder encodeBool:self.isCancelled forKey:@"isCancelled"];
  [encoder encodeObject:self.mutableData forKey:@"mutableData"];
  [encoder encodeInteger:self.downloadedDataSize forKey:@"downloadedDataSize"];
  [encoder encodeObject:self.downloadStreams forKey:@"downloadStreams"];
  [encoder encodeInteger:self.startPosition forKey:@"startPosition"];
  [encoder encodeInteger:self.credentialPersistence forKey:@"credentialPersistence"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
  self = [super init];
  if (self) {
    [self setStringEncoding:[decoder decodeIntegerForKey:@"stringEncoding"]];
    self.request = [decoder decodeObjectForKey:@"request"];
    self.uniqueId = [decoder decodeObjectForKey:@"uniqueId"];
    
    self.response = [decoder decodeObjectForKey:@"response"];
    self.fieldsToBePosted = [decoder decodeObjectForKey:@"fieldsToBePosted"];
    self.filesToBePosted = [decoder decodeObjectForKey:@"filesToBePosted"];
    self.dataToBePosted = [decoder decodeObjectForKey:@"dataToBePosted"];
    self.username = [decoder decodeObjectForKey:@"username"];
    self.password = [decoder decodeObjectForKey:@"password"];
    self.clientCertificate = [decoder decodeObjectForKey:@"clientCertificate"];
    [self setState:[decoder decodeInt32ForKey:@"state"]];
    self.isCancelled = [decoder decodeBoolForKey:@"isCancelled"];
    self.mutableData = [decoder decodeObjectForKey:@"mutableData"];
    self.downloadedDataSize = [decoder decodeIntegerForKey:@"downloadedDataSize"];
    self.downloadStreams = [decoder decodeObjectForKey:@"downloadStreams"];
    self.startPosition = [decoder decodeIntegerForKey:@"startPosition"];
    self.credentialPersistence = [decoder decodeIntegerForKey:@"credentialPersistence"];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  MKNetworkOperation *theCopy = [[[self class] allocWithZone:zone] init];  // use designated initializer
  
  [theCopy setStringEncoding:self.stringEncoding];
  [theCopy setUniqueId:[self.uniqueId copy]];
  
  [theCopy setConnection:[self.connection copy]];
  [theCopy setRequest:[self.request copy]];
  [theCopy setResponse:[self.response copy]];
  [theCopy setFieldsToBePosted:[self.fieldsToBePosted copy]];
  [theCopy setFilesToBePosted:[self.filesToBePosted copy]];
  [theCopy setDataToBePosted:[self.dataToBePosted copy]];
  [theCopy setUsername:[self.username copy]];
  [theCopy setPassword:[self.password copy]];
  [theCopy setClientCertificate:[self.clientCertificate copy]];
  [theCopy setResponseBlocks:[self.responseBlocks copy]];
  [theCopy setErrorBlocks:[self.errorBlocks copy]];
  [theCopy setState:self.state];
  [theCopy setIsCancelled:self.isCancelled];
  [theCopy setMutableData:[self.mutableData copy]];
  [theCopy setDownloadedDataSize:self.downloadedDataSize];
  [theCopy setUploadProgressChangedHandlers:[self.uploadProgressChangedHandlers copy]];
  [theCopy setDownloadProgressChangedHandlers:[self.downloadProgressChangedHandlers copy]];
  [theCopy setDownloadStreams:[self.downloadStreams copy]];
  [theCopy setCachedResponse:[self.cachedResponse copy]];
  [theCopy setCacheHandlingBlock:self.cacheHandlingBlock];
  [theCopy setStartPosition:self.startPosition];
  [theCopy setCredentialPersistence:self.credentialPersistence];
  
  return theCopy;
}

-(void) dealloc {
  
  [_connection cancel];
  _connection = nil;
}

-(void) updateHandlersFromOperation:(MKNetworkOperation*) operation {
  
  [self.responseBlocks addObjectsFromArray:operation.responseBlocks];
  [self.errorBlocks addObjectsFromArray:operation.errorBlocks];
  [self.uploadProgressChangedHandlers addObjectsFromArray:operation.uploadProgressChangedHandlers];
  [self.downloadProgressChangedHandlers addObjectsFromArray:operation.downloadProgressChangedHandlers];
  [self.downloadStreams addObjectsFromArray:operation.downloadStreams];
}

-(void) setCachedData:(NSData*) cachedData {
  
  self.cachedResponse = cachedData;    
  [self operationSucceeded];
}

-(void) updateOperationBasedOnPreviousHeaders:(NSMutableDictionary*) headers {
  
  NSString *lastModified = [headers objectForKey:@"Last-Modified"];
  NSString *eTag = [headers objectForKey:@"ETag"];
  if(lastModified) {
    [self.request setValue:lastModified forHTTPHeaderField:@"IF-MODIFIED-SINCE"];
  }
  
  if(eTag) {
    [self.request setValue:eTag forHTTPHeaderField:@"IF-NONE-MATCH"];
  }    
}

-(void) setUsername:(NSString*) username password:(NSString*) password {
  
  self.username = username;
  self.password = password;
}

-(void) setUsername:(NSString*) username password:(NSString*) password basicAuth:(BOOL) bYesOrNo {
  
  [self setUsername:username password:password];
  NSString *base64EncodedString = [[[NSString stringWithFormat:@"%@:%@", self.username, self.password] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedString];
  
  [self setAuthorizationHeaderValue:base64EncodedString forAuthType:@"Basic"];
}

-(void) onCompletion:(MKNKResponseBlock) response onError:(MKNKErrorBlock) error {
  
  [self.responseBlocks addObject:[response copy]];
  [self.errorBlocks addObject:[error copy]];
}

-(void) onUploadProgressChanged:(MKNKProgressBlock) uploadProgressBlock {
  
  [self.uploadProgressChangedHandlers addObject:[uploadProgressBlock copy]];
}

-(void) onDownloadProgressChanged:(MKNKProgressBlock) downloadProgressBlock {
  
  [self.downloadProgressChangedHandlers addObject:[downloadProgressBlock copy]];
}

-(void) setUploadStream:(NSInputStream*) inputStream {
  
#warning Method not tested yet.
  self.request.HTTPBodyStream = inputStream;
}

-(void) addDownloadStream:(NSOutputStream*) outputStream {
  
  [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
  [self.downloadStreams addObject:outputStream];
}

- (id)initWithURLString:(NSString *)aURLString
                 params:(NSMutableDictionary *)params
             httpMethod:(NSString *)method

{	
  if((self = [super init])) {
    
    self.responseBlocks = [NSMutableArray array];
    self.errorBlocks = [NSMutableArray array];        
    
    self.filesToBePosted = [NSMutableArray array];
    self.dataToBePosted = [NSMutableArray array];
    self.fieldsToBePosted = [NSMutableDictionary dictionary];
    
    self.uploadProgressChangedHandlers = [NSMutableArray array];
    self.downloadProgressChangedHandlers = [NSMutableArray array];
    self.downloadStreams = [NSMutableArray array];
    
    self.credentialPersistence = NSURLCredentialPersistenceForSession;
    
    NSURL *finalURL = nil;
    
    if(params)
      self.fieldsToBePosted = params;
    
    self.stringEncoding = NSUTF8StringEncoding; // use a delegate to get these values later
    
    if ([method isEqualToString:@"GET"])
      self.cacheHeaders = [NSMutableDictionary dictionary];
    
    if (([method isEqualToString:@"GET"] ||
         [method isEqualToString:@"DELETE"]) && (params && [params count] > 0)) {
      
      finalURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", aURLString, 
                                       [self encodedPostDataString]]];
    } else {
      finalURL = [NSURL URLWithString:aURLString];
    }
    
    self.request = [NSMutableURLRequest requestWithURL:finalURL                                                           
                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData                                            
                                       timeoutInterval:kMKNetworkKitRequestTimeOutInSeconds];
    
    [self.request setHTTPMethod:method];
    
    [self.request setValue:[NSString stringWithFormat:@"%@, en-us", 
                            [[NSLocale preferredLanguages] componentsJoinedByString:@", "]
                            ] forHTTPHeaderField:@"Accept-Language"];
    
    if (([method isEqualToString:@"POST"] ||
         [method isEqualToString:@"PUT"]) && (params && [params count] > 0)) {
      
      self.postDataEncoding = MKNKPostDataEncodingTypeURL;
    }
    
    self.state = MKNetworkOperationStateReady;
  }
  
  return self;
}

-(void) addHeaders:(NSDictionary*) headersDictionary {
  
  [headersDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [self.request addValue:obj forHTTPHeaderField:key];
  }];
}

-(void) setAuthorizationHeaderValue:(NSString*) token forAuthType:(NSString*) authType {
  
  [self.request setValue:[NSString stringWithFormat:@"%@ %@", authType, token] 
      forHTTPHeaderField:@"Authorization"];
}
/*
 Printing a MKNetworkOperation object is printed in curl syntax
 */

-(NSString*) description {
  
  NSMutableString *displayString = [NSMutableString stringWithFormat:@"%@\nRequest\n-------\n%@", 
                                    [[NSDate date] descriptionWithLocale:[NSLocale currentLocale]],
                                    [self curlCommandLineString]];
  
  NSString *responseString = [self responseString];    
  if([responseString length] > 0) {
    [displayString appendFormat:@"\n--------\nResponse\n--------\n%@\n", responseString];
  }
  
  return displayString;
}

-(NSString*) curlCommandLineString
{
  __block NSMutableString *displayString = [NSMutableString stringWithFormat:@"curl -X %@", self.request.HTTPMethod];
  
  if([self.filesToBePosted count] == 0 && [self.dataToBePosted count] == 0) {
    [[self.request allHTTPHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id val, BOOL *stop)
     {
       [displayString appendFormat:@" -H \"%@: %@\"", key, val];
     }];
  }
  
  [displayString appendFormat:@" \"%@\"",  self.url];
  
  if ([self.request.HTTPMethod isEqualToString:@"POST"] || [self.request.HTTPMethod isEqualToString:@"PUT"]) {
    
    NSString *option = [self.filesToBePosted count] == 0 ? @"-d" : @"-F";
    if(self.postDataEncoding == MKNKPostDataEncodingTypeURL) {
      [self.fieldsToBePosted enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        [displayString appendFormat:@" %@ \"%@=%@\"", option, key, obj];    
      }];
    } else {
      [displayString appendFormat:@" -d \"%@\"", [self encodedPostDataString]];
    }
    
    
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
  
  return displayString;
}


-(void) addData:(NSData*) data forKey:(NSString*) key {
  
  [self addData:data forKey:key mimeType:@"application/octet-stream" fileName:@"file"];
}

-(void) addData:(NSData*) data forKey:(NSString*) key mimeType:(NSString*) mimeType fileName:(NSString*) fileName {
  
  [self.request setHTTPMethod:@"POST"];
  
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        data, @"data",
                        key, @"name",
                        mimeType, @"mimetype",
                        fileName, @"filename",     
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
  
  if([self.filesToBePosted count] == 0 && [self.dataToBePosted count] == 0) {
    
    return [[self encodedPostDataString] dataUsingEncoding:self.stringEncoding];
  }
  
  NSString *boundary = @"0xKhTmLbOuNdArY";
  NSMutableData *body = [NSMutableData data];
  __block NSUInteger postLength = 0;    
  
  [self.fieldsToBePosted enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    
    NSString *thisFieldString = [NSString stringWithFormat:
                                     @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@",
                                 boundary, key, obj];
    
    [body appendData:[thisFieldString dataUsingEncoding:[self stringEncoding]]];
    [body appendData:[@"\r\n" dataUsingEncoding:[self stringEncoding]]];
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
    [body appendData:[@"\r\n" dataUsingEncoding:[self stringEncoding]]];
  }];
  
  [self.dataToBePosted enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    
    NSDictionary *thisDataObject = (NSDictionary*) obj;
    NSString *thisFieldString = [NSString stringWithFormat:
                                 @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\nContent-Transfer-Encoding: binary\r\n\r\n",
                                 boundary, 
                                 [thisDataObject objectForKey:@"name"], 
                                 [thisDataObject objectForKey:@"filename"], 
                                 [thisDataObject objectForKey:@"mimetype"]];
    
    [body appendData:[thisFieldString dataUsingEncoding:[self stringEncoding]]];         
    [body appendData:[thisDataObject objectForKey:@"data"]];
    [body appendData:[@"\r\n" dataUsingEncoding:[self stringEncoding]]];
  }];
  
  if (postLength >= 1)
    [self.request setValue:[NSString stringWithFormat:@"%lu", postLength] forHTTPHeaderField:@"content-length"];
  
  [body appendData: [[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:self.stringEncoding]];
  
  NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
  
  if(([self.filesToBePosted count] > 0) || ([self.dataToBePosted count] > 0)) {
    [self.request setValue:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, boundary] 
        forHTTPHeaderField:@"Content-Type"];
    
    [self.request setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
  }
  
  return body;
}


-(void) setCacheHandler:(MKNKResponseBlock) cacheHandler {
  
  self.cacheHandlingBlock = cacheHandler;
}

#pragma mark -
#pragma Main method
-(void) main {
  
  @autoreleasepool {
    [self start];
  }
}

-(void) endBackgroundTask {
  
#if TARGET_OS_IPHONE                
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
      [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
      self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
  });
#endif        
}

- (void) start
{
  
#if TARGET_OS_IPHONE
  self.backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.backgroundTaskId != UIBackgroundTaskInvalid)
      {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
        [self cancel];
      }
    });
  }];
  
#endif
  
  if(!self.isCancelled) {
    
    if ([self.request.HTTPMethod isEqualToString:@"POST"] || [self.request.HTTPMethod isEqualToString:@"PUT"]) {            
      
      [self.request setHTTPBody:[self bodyData]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      self.connection = [[NSURLConnection alloc] initWithRequest:self.request 
                                                        delegate:self 
                                                startImmediately:NO]; 
      
      [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                 forMode:NSRunLoopCommonModes];
      
      [self.connection start];
    });
    
    self.state = MKNetworkOperationStateExecuting;
  }
  else {
    self.state = MKNetworkOperationStateFinished;
    [self endBackgroundTask];
  }
}

#pragma -
#pragma mark NSOperation stuff

- (BOOL)isConcurrent
{
  return YES;
}

- (BOOL)isReady {
  
  return (self.state == MKNetworkOperationStateReady);
}

- (BOOL)isFinished 
{
  return (self.state == MKNetworkOperationStateFinished);
}

- (BOOL)isExecuting {
  
  return (self.state == MKNetworkOperationStateExecuting);
}

-(void) cancel {
  
  if([self isFinished]) 
    return;
  
  @synchronized(self) {
    self.isCancelled = YES;
    
    [self.connection cancel];
    
    [self.responseBlocks removeAllObjects];
    self.responseBlocks = nil;
    
    [self.errorBlocks removeAllObjects];
    self.errorBlocks = nil;
    
    [self.uploadProgressChangedHandlers removeAllObjects];
    self.uploadProgressChangedHandlers = nil;
    
    [self.downloadProgressChangedHandlers removeAllObjects];
    self.downloadProgressChangedHandlers = nil;
    
    for(NSOutputStream *stream in self.downloadStreams)
      [stream close];
    
    [self.downloadStreams removeAllObjects];
    self.downloadStreams = nil;
    
    self.authHandler = nil;    
    self.mutableData = nil;
    self.downloadedDataSize = 0;
    
    self.cacheHandlingBlock = nil;
    
    if(self.state == MKNetworkOperationStateExecuting)
      self.state = MKNetworkOperationStateFinished; // This notifies the queue and removes the operation.
    // if the operation is not removed, the spinner continues to spin, not a good UX
    
    [self endBackgroundTask];
  }
  [super cancel];
}

#pragma mark -
#pragma mark NSURLConnection delegates

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  
  self.state = MKNetworkOperationStateFinished;
  self.mutableData = nil;
  self.downloadedDataSize = 0;
  for(NSOutputStream *stream in self.downloadStreams)
    [stream close];
  
  [self operationFailedWithError:error];
  [self endBackgroundTask];
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  
  if ([challenge previousFailureCount] == 0) {
    
    if (((challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodDefault) ||
         (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic) ||
         (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest) ||
         (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM)) && 
        (self.username && self.password))
    {
      
      // for NTLM, we will assume user name to be of the form "domain\\username"
      NSURLCredential *credential = [NSURLCredential credentialWithUser:self.username 
                                                               password:self.password
                                                            persistence:self.credentialPersistence];
      
      [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
    }
    else if ((challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate) && self.clientCertificate) {
      
      NSData *certData = [[NSData alloc] initWithContentsOfFile:self.clientCertificate];
      
#warning method not implemented. Don't use client certicate authentication for now.
      SecIdentityRef myIdentity;  // ???
      
      SecCertificateRef myCert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
      SecCertificateRef certArray[1] = { myCert };
      CFArrayRef myCerts = CFArrayCreate(NULL, (void *)certArray, 1, NULL);
      CFRelease(myCert);
      NSURLCredential *credential = [NSURLCredential credentialWithIdentity:myIdentity
                                                               certificates:(__bridge NSArray *)myCerts
                                                                persistence:NSURLCredentialPersistencePermanent];
      CFRelease(myCerts);
      [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
    }
    else if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
#warning method not tested. proceed at your own risk
      SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
      SecTrustResultType result;
      SecTrustEvaluate(serverTrust, &result);
      
      if(result == kSecTrustResultProceed) {
        
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
      }
      else if(result == kSecTrustResultConfirm) {
        
        // ask user
        BOOL userOkWithWrongCert = NO; // (ACTUALLY CHEAT., DON'T BE A F***ING BROWSER, USERS ALWAYS TAP YES WHICH IS RISKY)
        if(userOkWithWrongCert) {
          
          // Cert not trusted, but user is OK with that
          [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        } else {
          
          // Cert not trusted, and user is not OK with that. Don't proceed
          [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
      } 
      else {
        
        // invalid or revoked certificate
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        //[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
      }
    }        
    else if (self.authHandler) {
      
      // forward the authentication to the view controller that created this operation
      // If this happens for NSURLAuthenticationMethodHTMLForm, you have to
      // do some shit work like showing a modal webview controller and close it after authentication.
      // I HATE THIS.
      self.authHandler(challenge);
    }
    else {
      [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
  } else {
    //  apple proposes to cancel authentication, which results in NSURLErrorDomain error -1012, but we prefer to trigger a 401
    //        [[challenge sender] cancelAuthenticationChallenge:challenge];
    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
  }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  
  NSUInteger size = [self.response expectedContentLength] < 0 ? 0 : [self.response expectedContentLength];
  self.response = (NSHTTPURLResponse*) response;
  
  // dont' save data if the operation was created to download directly to a stream.
  if([self.downloadStreams count] == 0)
    self.mutableData = [NSMutableData dataWithCapacity:size];
  else
    self.mutableData = nil;
  
  for(NSOutputStream *stream in self.downloadStreams)
    [stream open];
  
  NSDictionary *httpHeaders = [self.response allHeaderFields];
  
  // if you attach a stream to the operation, MKNetworkKit will not cache the response.
  // Streams are usually "big data chunks" that doesn't need caching anyways.
  
  if([self.request.HTTPMethod isEqualToString:@"GET"] && [self.downloadStreams count] == 0) {
    
    // We have all this complicated cache handling since NSURLRequestReloadRevalidatingCacheData is not implemented
    // do cache processing only if the request is a "GET" method
    NSString *lastModified = [httpHeaders objectForKey:@"Last-Modified"];
    NSString *eTag = [httpHeaders objectForKey:@"ETag"];
    NSString *expiresOn = [httpHeaders objectForKey:@"Expires"];
    
    NSString *contentType = [httpHeaders objectForKey:@"Content-Type"];
    // if contentType is image, 
    
    NSDate *expiresOnDate = nil;
    
    if([contentType rangeOfString:@"image"].location != NSNotFound) {
      
      // For images let's assume a expiry date of 7 days if there is no eTag or Last Modified.
      if(!eTag && !lastModified)
        expiresOnDate = [[NSDate date] dateByAddingTimeInterval:kMKNetworkKitDefaultImageCacheDuration];
      else    
        expiresOnDate = [[NSDate date] dateByAddingTimeInterval:kMKNetworkKitDefaultImageHeadRequestDuration];
    }
    
    NSString *cacheControl = [httpHeaders objectForKey:@"Cache-Control"]; // max-age, must-revalidate, no-cache
    NSArray *cacheControlEntities = [cacheControl componentsSeparatedByString:@","];
    
    for(NSString *substring in cacheControlEntities) {
      
      if([substring rangeOfString:@"max-age"].location != NSNotFound) {
        
        // do some processing to calculate expiresOn
        NSString *maxAge = nil;
        NSArray *array = [substring componentsSeparatedByString:@"="];
        if([array count] > 1)
          maxAge = [array objectAtIndex:1];
        
        expiresOnDate = [[NSDate date] dateByAddingTimeInterval:[maxAge intValue]];
      }
      if([substring rangeOfString:@"no-cache"].location != NSNotFound) {
        
        // Don't cache this request
        expiresOnDate = [[NSDate date] dateByAddingTimeInterval:kMKNetworkKitDefaultCacheDuration];
      }
    }
    
    // if there was a cacheControl entity, we would have a expiresOnDate that is not nil.        
    // "Cache-Control" headers take precedence over "Expires" headers
    
    expiresOn = [expiresOnDate rfc1123String];
    
    // now remember lastModified, eTag and expires for this request in cache
    if(expiresOn)
      [self.cacheHeaders setObject:expiresOn forKey:@"Expires"];
    if(lastModified)
      [self.cacheHeaders setObject:lastModified forKey:@"Last-Modified"];
    if(eTag)
      [self.cacheHeaders setObject:eTag forKey:@"ETag"];
  }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  
  if ([self.mutableData length] == 0 || [self.downloadStreams count] > 0) {
    // This is the first batch of data
    // Check for a range header and make changes as neccesary
    NSString *rangeString = [[self request] valueForHTTPHeaderField:@"Range"];
    if ([rangeString hasPrefix:@"bytes="] && [rangeString hasSuffix:@"-"]) {
      NSString *bytesText = [rangeString substringWithRange:NSMakeRange(6, [rangeString length] - 7)];
      self.startPosition = [bytesText integerValue];
      self.downloadedDataSize = self.startPosition;
      DLog(@"Resuming at %d bytes", self.startPosition);
    }
  }
  
  if([self.downloadStreams count] == 0)
    [self.mutableData appendData:data];
  
  for(NSOutputStream *stream in self.downloadStreams) {
    
    if ([stream hasSpaceAvailable]) {
      const uint8_t *dataBuffer = [data bytes];
      [stream write:&dataBuffer[0] maxLength:[data length]];
    }        
  }
  
  self.downloadedDataSize += [data length];
  
  for(MKNKProgressBlock downloadProgressBlock in self.downloadProgressChangedHandlers) {
    
    if([self.response expectedContentLength] > 0) {
      
      double progress = (double)(self.downloadedDataSize) / (double)(self.startPosition + [self.response expectedContentLength]);
      downloadProgressBlock(progress);
    }        
  }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
  
  for(MKNKProgressBlock uploadProgressBlock in self.uploadProgressChangedHandlers) {
    
    if(totalBytesExpectedToWrite > 0) {
      uploadProgressBlock(((double)totalBytesWritten/(double)totalBytesExpectedToWrite));
    }
  }
}

// http://stackoverflow.com/questions/1446509/handling-redirects-correctly-with-nsurlconnection
- (NSURLRequest *)connection: (NSURLConnection *)inConnection
             willSendRequest: (NSURLRequest *)inRequest
            redirectResponse: (NSURLResponse *)inRedirectResponse;
{
  if (inRedirectResponse) {
    NSMutableURLRequest *r = [self.request mutableCopy];
    [r setURL: [inRequest URL]];
    DLog(@"Redirected to %@", [[inRequest URL] absoluteString]);
    
    return r;
  } else {
    return inRequest;
  }
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  
  if([self isCancelled]) 
    return;
  
  self.state = MKNetworkOperationStateFinished;    
  
  for(NSOutputStream *stream in self.downloadStreams)
    [stream close];
  
  if (self.response.statusCode >= 200 && self.response.statusCode < 300 && ![self isCancelled]) {
    
    self.cachedResponse = nil; // remove cached data
    [self notifyCache];        
    [self operationSucceeded];
    
  } 
  if (self.response.statusCode >= 300 && self.response.statusCode < 400) {
    
    if(self.response.statusCode == 301) {
      DLog(@"%@ has moved to %@", self.url, [self.response.URL absoluteString]);
    }
    else if(self.response.statusCode == 304) {
      DLog(@"%@ not modified", self.url);
    }
    else if(self.response.statusCode == 307) {
      DLog(@"%@ temporarily redirected", self.url);
    }
    else {
      DLog(@"%@ returned status %d", self.url, (int) self.response.statusCode);
    }
    
  } else if (self.response.statusCode >= 400 && self.response.statusCode < 600 && ![self isCancelled]) {                        
    
    [self operationFailedWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                       code:self.response.statusCode
                                                   userInfo:self.response.allHeaderFields]];
  }  
  [self endBackgroundTask];
  
}

#pragma mark -
#pragma mark Our methods to get data

-(NSData*) responseData {
  
  if([self isFinished])
    return self.mutableData;
  else if(self.cachedResponse)
    return self.cachedResponse;
  else
    return nil;
}

-(NSString*)responseString {
  
  return [self responseStringWithEncoding:self.stringEncoding];
}

-(NSString*) responseStringWithEncoding:(NSStringEncoding) encoding {
  
  return [[NSString alloc] initWithData:[self responseData] encoding:encoding];
}

#if TARGET_OS_IPHONE
-(UIImage*) responseImage {
  
  return [UIImage imageWithData:[self responseData]];
}
#elif TARGET_OS_MAC
-(NSImage*) responseImage {
  
  return [[NSImage alloc] initWithData:[self responseData]];
}

-(NSXMLDocument*) responseXML {
  
  return [[NSXMLDocument alloc] initWithData:[self responseData] options:0 error:nil];
}
#endif

-(id) responseJSON {
  
  if([NSJSONSerialization class]) {
    if([self responseData] == nil) return nil;
    NSError *error = nil;
    id returnValue = [NSJSONSerialization JSONObjectWithData:[self responseData] options:0 error:&error];    
    if(error) DLog(@"JSON Parsing Error: %@", error);
    return returnValue;
  } else {
    DLog("No valid JSON Serializers found");
    return [self responseString];
  }
}


#pragma mark -
#pragma mark Overridable methods

-(void) operationSucceeded {
  
  for(MKNKResponseBlock responseBlock in self.responseBlocks)
    responseBlock(self);
}

-(void) showLocalNotification {
#if TARGET_OS_IPHONE
  
  if(self.localNotification) {
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:self.localNotification];
  } else if(self.shouldShowLocalNotificationOnError) {
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    
    localNotification.alertBody = [self.error localizedDescription];
    localNotification.alertAction = NSLocalizedString(@"Dismiss", @"");	
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
  }
#endif
}

-(void) operationFailedWithError:(NSError*) error {
  
  self.error = error;
  DLog(@"%@, [%@]", self, [self.error localizedDescription]);
  for(MKNKErrorBlock errorBlock in self.errorBlocks)
    errorBlock(error);  
  
#if TARGET_OS_IPHONE
  DLog(@"State: %d", [[UIApplication sharedApplication] applicationState]);
  if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
    [self showLocalNotification];
#endif
  
}

@end
