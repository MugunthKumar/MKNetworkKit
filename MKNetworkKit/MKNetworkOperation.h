//
//  MKRequest.h
//  MKNetworkKit
//
//  Created by Mugunth on 25/2/11.
//  Copyright 2011 Steinlogic. All rights reserved.
//

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
