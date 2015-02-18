//
//  MKNetworkRequest.h
//  MKNetworkKit
//
//  Created by Mugunth Kumar (@mugunthkumar) on 23/06/14.
//  Copyright (C) 2011-2020 by Steinlogic Consulting and Training Pte Ltd

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


#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

typedef enum {
  
  MKNKParameterEncodingURL = 0, // default
  MKNKParameterEncodingJSON,
  MKNKParameterEncodingPlist
} MKNKParameterEncoding;


typedef enum {
  
  MKNKRequestStateReady = 0,
  MKNKRequestStateStarted,
  MKNKRequestStateResponseAvailableFromCache,
  MKNKRequestStateStaleResponseAvailableFromCache,
  MKNKRequestStateCancelled,
  MKNKRequestStateCompleted,
  MKNKRequestStateError
} MKNKRequestState;

@interface MKNetworkRequest : NSObject {
  
  MKNKRequestState _state;
}

@property (readonly) NSMutableURLRequest *request;
@property (readonly) NSHTTPURLResponse *response;

@property MKNKParameterEncoding parameterEncoding;
@property (readonly) MKNKRequestState state;

// if the resource require authentication
@property NSString *username;
@property NSString *password;

@property NSString *clientCertificate;
@property NSString *clientCertificatePassword;

@property NSString *downloadPath;

@property (readonly) BOOL requiresAuthentication;
@property (readonly) BOOL isSSL;

@property BOOL doNotCache;
@property BOOL alwaysCache;

@property BOOL ignoreCache;
@property BOOL alwaysLoad;

@property NSString *httpMethod;

@property (readonly) BOOL isCachedResponse;
@property (readonly) BOOL responseAvailable;

@property (readonly) NSData *multipartFormData;
@property (readonly) NSData *responseData;
@property (readonly) NSError *error;
@property (readonly) NSURLSessionTask *task;
@property (readonly) CGFloat progress;
@property (readonly) id responseAsJSON;

#if TARGET_OS_IPHONE
-(UIImage*) decompressedResponseImageOfSize:(CGSize) size;
@property (readonly) UIImage *responseAsImage;
#else
@property (readonly) NSImage *responseAsImage;
#endif

@property (readonly) NSString *responseAsString;

@property (readonly) BOOL cacheable;

- (instancetype)initWithURLString:(NSString *)aURLString
                           params:(NSDictionary *)params
                         bodyData:(NSData *)bodyData
                       httpMethod:(NSString *)method;

typedef void (^MKNKHandler)(MKNetworkRequest* completedRequest);

-(void) addParameters:(NSDictionary*) paramsDictionary;
-(void) addHeaders:(NSDictionary*) headersDictionary;
-(void) setAuthorizationHeaderValue:(NSString*) token forAuthType:(NSString*) authType;

-(void) attachFile:(NSString*) filePath forKey:(NSString*) key mimeType:(NSString*) mimeType;
-(void) attachData:(NSData*) data forKey:(NSString*) key mimeType:(NSString*) mimeType suggestedFileName:(NSString*) fileName;

-(void) addCompletionHandler:(MKNKHandler) completionHandler;
-(void) addUploadProgressChangedHandler:(MKNKHandler) uploadProgressChangedHandler;
-(void) addDownloadProgressChangedHandler:(MKNKHandler) downloadProgressChangedHandler;
-(void) cancel;
@end
