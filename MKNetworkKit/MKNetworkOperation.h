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

@class MKNetworkOperation;

typedef void (^MKNKProgressBlock)(double progress);
typedef void (^MKNKResponseBlock)(MKNetworkOperation* operation);
#if TARGET_OS_IPHONE
typedef void (^MKNKImageBlock) (UIImage* fetchedImage, NSString* urlString);
#elif TARGET_OS_MAC
typedef void (^MKNKImageBlock) (NSImage* fetchedImage, NSString* urlString);
#endif
typedef void (^MKNKErrorBlock)(NSError* error);

/*!
 @header MKNetworkOperation.h
 @abstract   Represents a single unique network operation.
 */

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
 *  @property error
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

/*!
 *  @abstract Add additional header parameters
 *  
 *  @discussion
 *	If you ever need to set additional headers after creating your operation, you this method.
 *  You normally set default headers to the engine and they get added to every request you create.
 *  On specific cases where you need to set a new header parameter for just a single API call, you can use this
 */
-(void) addHeaders:(NSDictionary*) headersDictionary;

/*!
 *  @abstract Attaches a file to the request
 *  
 *  @discussion
 *	This method lets you attach a file to the request
 *  The method has a side effect. It changes the HTTPMethod to "POST" regardless of what it was before.
 *  It also changes the post format to multipart/form-data
 *  The mime-type is assumed to be application/octet-stream
 */
-(void) addFile:(NSString*) filePath forKey:(NSString*) key;

/*!
 *  @abstract Attaches a file to the request and allows you to specify a mime-type
 *  
 *  @discussion
 *	This method lets you attach a file to the request
 *  The method has a side effect. It changes the HTTPMethod to "POST" regardless of what it was before.
 *  It also changes the post format to multipart/form-data
 */
-(void) addFile:(NSString*) filePath forKey:(NSString*) key mimeType:(NSString*) mimeType;

/*!
 *  @abstract Attaches a resource to the request from a NSData pointer
 *  
 *  @discussion
 *	This method lets you attach a NSData object to the request. The behaviour is exactly similar to addFile:forKey:
 *  The method has a side effect. It changes the HTTPMethod to "POST" regardless of what it was before.
 *  It also changes the post format to multipart/form-data
 *  The mime-type is assumed to be application/octet-stream
 */
-(void) addData:(NSData*) data forKey:(NSString*) key;

/*!
 *  @abstract Attaches a resource to the request from a NSData pointer and allows you to specify a mime-type
 *  
 *  @discussion
 *	This method lets you attach a NSData object to the request. The behaviour is exactly similar to addFile:forKey:mimeType:
 *  The method has a side effect. It changes the HTTPMethod to "POST" regardless of what it was before.
 *  It also changes the post format to multipart/form-data
 */
-(void) addData:(NSData*) data forKey:(NSString*) key mimeType:(NSString*) mimeType;

/*!
 *  @abstract Block Handler for completion and error
 *  
 *  @discussion
 *	This method sets your completion and error blocks. If your operation's response data was previously called,
 *  the completion block will be called almost immediately with the cached response. You can check if the completion 
 *  handler was invoked with a cached data or with real data by calling the isCachedResponse method.
 *
 *  @seealso
 *  isCachedResponse
 */
-(void) onCompletion:(MKNKResponseBlock) response onError:(MKNKErrorBlock) error;

/*!
 *  @abstract Block Handler for tracking upload progress
 *  
 *  @discussion
 *	This method can be used to update your progress bars when an upload is in progress. 
 *  The value range of the progress is 0 to 1.
 *
 */
-(void) onUploadProgressChanged:(MKNKProgressBlock) uploadProgressBlock;

/*!
 *  @abstract Block Handler for tracking download progress
 *  
 *  @discussion
 *	This method can be used to update your progress bars when a download is in progress. 
 *  The value range of the progress is 0 to 1.
 *
 */
-(void) onDownloadProgressChanged:(MKNKProgressBlock) downloadProgressBlock;

/*!
 *  @abstract Downloads a resource directly to a file or any output stream
 *  
 *  @discussion
 *	This method can be used to download a resource directly to a stream (It's normally a file in most cases).
 *  Calling this method multiple times adds new streams to the same operation.
 *  A stream cannot be removed after it is added.
 *
 */
-(void) setDownloadStream:(NSOutputStream*) outputStream;

/*!
 *  @abstract Helper method to check if the response is from cache
 *  
 *  @discussion
 *	This method should be used to check if your response is cached.
 *  When you enable caching on MKNetworkEngine, your completionHandler will be called with cached data first and then
 *  with real data, later after fetching. In your handler, you can call this method to check if it is from cache or not
 *
 */
-(BOOL) isCachedResponse;

/*!
 *  @abstract Helper method to retrieve the contents
 *  
 *  @discussion
 *	This method is used for accessing the downloaded data. If the operation is still in progress, the method returns nil instead of partial data. To access partial data, use a downloadStream.
 *
 *  @seealso
 *  setDownloadStream:
 */
-(NSData*) responseData;

/*!
 *  @abstract Helper method to retrieve the contents as a NSString
 *  
 *  @discussion
 *	This method is used for accessing the downloaded data. If the operation is still in progress, the method returns nil instead of partial data. To access partial data, use a downloadStream. The method also converts the responseData to a NSString using the stringEncoding specified in the operation
 *
 *  @seealso
 *  setDownloadStream:
 *  stringEncoding
 */
-(NSString*)responseString;

/*!
 *  @abstract Helper method to retrieve the contents as a NSString encoded using a specific string encoding
 *  
 *  @discussion
 *	This method is used for accessing the downloaded data. If the operation is still in progress, the method returns nil instead of partial data. To access partial data, use a downloadStream. The method also converts the responseData to a NSString using the stringEncoding specified in the parameter
 *
 *  @seealso
 *  setDownloadStream:
 *  stringEncoding
 */
-(NSString*) responseStringWithEncoding:(NSStringEncoding) encoding;

/*!
 *  @abstract Helper method to retrieve the contents as a UIImage
 *  
 *  @discussion
 *	This method is used for accessing the downloaded data as a UIImage. If the operation is still in progress, the method returns nil instead of a partial image. To access partial data, use a downloadStream. If the response is not a valid image, this method returns nil. This method doesn't obey the response mime type property. If the server response with a proper image data but set the mime type incorrectly, this method will still be able access the response as an image.
 *
 *  @seealso
 *  setDownloadStream:
 */
#if TARGET_OS_IPHONE
-(UIImage*) responseImage;
#elif TARGET_OS_MAC
-(NSImage*) responseImage;
-(NSXMLDocument*) responseXML;
#endif

#ifdef __IPHONE_5_0
/*!
 *  @abstract Helper method to retrieve the contents as a NSDictionary or NSArray depending on the JSON contents
 *  
 *  @discussion
 *	This method is used for accessing the downloaded data as a NSDictionary or an NSArray. If the operation is still in progress, the method returns nil. If the response is not a valid JSON, this method returns nil.
 *
 *  @availability
 *  iOS 5 and above
 */
-(id) responseJSON;
#endif

/*!
 *  @abstract Overridable custom method where you can add your custom business logic error handling
 *  
 *  @discussion
 *	This optional method can be overridden to do custom error handling. Be sure to call [super operationSucceeded] at the last.
 *  For example, a valid HTTP response (200) like "Item not found in database" might have a custom business error code
 *  You can override this method and called [super failWithError:customError]; to notify that HTTP call was successful but the method
 *  ended as a failed call
 *
 */
-(void) operationSucceeded;

/*!
 *  @abstract Overridable custom method where you can add your custom business logic error handling
 *  
 *  @discussion
 *	This optional method can be overridden to do custom error handling. Be sure to call [super operationSucceeded] at the last.
 *  For example, a invalid HTTP response (401) like "Unauthorized" might be a valid case in your app.
 *  You can override this method and called [super operationSucceeded]; to notify that HTTP call failed but the method
 *  ended as a success call. For example, Facebook login failed, but to your business implementation, it's not a problem as you
 *  are going to try alternative login mechanisms.
 *
 */
-(void) operationFailedWithError:(NSError*) error;

// internal methods called by MKNetworkEngine only.
// Don't touch
-(void) setCachedData:(NSData*) cachedData;
-(void) setCacheHandler:(MKNKResponseBlock) cacheHandler;
-(void) updateHandlersFromOperation:(MKNetworkOperation*) operation;
-(NSString*) uniqueIdentifier;

@end
