//
//  MKNetwork.h
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

#import <UIKit/UIKit.h>

@class MKNetworkOperation;

typedef void (^ProgressBlock)(double progress);
typedef void (^ResponseBlock)(MKNetworkOperation* operation);
typedef void (^ErrorBlock)(NSError* error);

/*!
 *  @class MKNetworkOperation
 *  @abstract Represents a single unique network operation.
 *  
 *  @discussion
 *	You normally create an instance of this class using the methods exposed by MKNetworkEngine
 *  Created operations are enqueued into the shared queue on MKNetworkEngine
 *  MKNetworkOperation encapsulates both request and response
 *  Printing a MKNetworkOperation prints out a cURL command that can be copied and pasted directly on terminal
 *  Freezable operations are serialized when network connectivity is lost and performed when connection is restored
 */
@interface MKNetworkOperation : NSOperation {
    
    @private
    int _state;
    BOOL _freezable;
}

/*!
 *  @abstract Creates a simple network operation
 *  
 *  @discussion
 *	Creates an operation with the given URL string.
 *  The default headers you specified in your MKNetworkEngine subclass gets added to the headers
 *  The params dictionary in this method gets attached to the URL as query parameters if the HTTP Method is GET/DELETE
 *  The params dictionary is attached to the body if the HTTP Method is POST/PUT
 */
+ (id)operationWithURLString:(NSString *)urlString
                      params:(NSMutableDictionary *)body
				httpMethod:(NSString *)method;

/*!
 *  @abstract String Encoding Property
 *  @property stringEncoding
 *  
 *  @discussion
 *	Creates an operation with the given URL string.
 *  The default headers you specified in your MKNetworkEngine subclass gets added to the headers
 *  The params dictionary in this method gets attached to the URL as query parameters if the HTTP Method is GET/DELETE
 *  The params dictionary is attached to the body if the HTTP Method is POST/PUT
 */
@property (nonatomic, assign) NSStringEncoding stringEncoding;

/*!
 *  @abstract Freezable request
 *  @property freezable
 *  
 *  @discussion
 *	Freezable operations are serialized when the network goes down and restored when the connectivity is up again.
 */
@property (nonatomic, assign) BOOL freezable;

/*!
 *  @abstract Error object
 *  @property Variable that holds the network error
 *  
 *  @discussion
 *	If the network operation results in an error, this will hold the response error, otherwise it will be nil
 */
@property (nonatomic, readonly, strong) NSError *error;


/*!
 *  @abstract Authentication methods
 *  
 *  @discussion
 *	If your request needs to be authenticated, set your username and password using this method.
 */
-(void) setUsername:(NSString*) name password:(NSString*) password;

-(void) addHeaders:(NSDictionary*) headersDictionary;

-(void) addFile:(NSString*) filePath forKey:(NSString*) key;
-(void) addFile:(NSString*) filePath forKey:(NSString*) key mimeType:(NSString*) mimeType;

-(void) addData:(NSData*) data forKey:(NSString*) key;
-(void) addData:(NSData*) data forKey:(NSString*) key mimeType:(NSString*) mimeType;

-(BOOL) isCacheable;
-(NSData*) responseData;

-(void) onCompletion:(ResponseBlock) response onError:(ErrorBlock) error;
-(void) onUploadProgressChanged:(ProgressBlock) uploadProgressBlock;
-(void) onDownloadProgressChanged:(ProgressBlock) downloadProgressBlock;
-(void) setDownloadStream:(NSOutputStream*) outputStream;
-(void) setCacheHandler:(ResponseBlock) cacheHandler;
-(void) setCachedData:(NSData*) cachedData;
-(BOOL) isCachedResponse;
-(NSString*)responseString; // defaults to UTF8
-(NSString*) responseStringWithEncoding:(NSStringEncoding) encoding;

-(void) updateHandlersFromOperation:(MKNetworkOperation*) operation;

-(NSString*) uniqueIdentifier;
-(UIImage*) responseImage;
#ifdef __IPHONE_5_0
-(id) responseJSON;
#endif

@end
