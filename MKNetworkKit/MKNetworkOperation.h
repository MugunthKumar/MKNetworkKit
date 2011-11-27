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
typedef void (^ResponseBlock)(MKNetworkOperation* request);
typedef void (^ErrorBlock)(NSError* requestError);

@interface MKNetworkOperation : NSOperation {
    
    @private
    int _state;
    BOOL _freezable;
}

+ (id)operationWithURLString:(NSString *)urlString
                      body:(NSMutableDictionary *)body
				httpMethod:(NSString *)method;

@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, assign) BOOL freezable;
@property (nonatomic, readonly, strong) NSError *error;

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
