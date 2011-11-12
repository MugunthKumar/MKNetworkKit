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
}

+ (id)operationWithURLString:(NSString *)urlString
                      body:(NSMutableDictionary *)body
				httpMethod:(NSString *)method;

-(void) cancel;

@property (nonatomic, copy) ProgressBlock uploadProgressChangedHandler;
@property (nonatomic, copy) ProgressBlock downloadProgressChangedHandler;

@property (nonatomic, assign) NSStringEncoding stringEncoding;

-(void) onCompletion:(ResponseBlock) response onError:(ErrorBlock) error;
-(void) setUsername:(NSString*) name password:(NSString*) password;
-(void) addHeaders:(NSDictionary*) headersDictionary;

-(void) addFile:(NSString*) filePath forKey:(NSString*) key;
-(void) addFile:(NSString*) filePath forKey:(NSString*) key mimeType:(NSString*) mimeType;

-(void) addData:(NSData*) data forKey:(NSString*) key;
-(void) addData:(NSData*) data forKey:(NSString*) key mimeType:(NSString*) mimeType;

-(NSData*) responseData;

-(NSString*)responseString; // defaults to UTF8
-(NSString*) responseStringWithEncoding:(NSStringEncoding) encoding;

#ifdef __IPHONE_5_0
-(id) responseJSON;
#endif

@end
