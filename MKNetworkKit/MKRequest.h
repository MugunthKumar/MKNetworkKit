//
//  MKRequest.h
//  MKNetworkKit
//
//  Created by Mugunth on 25/2/11.
//  Copyright 2011 Steinlogic. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MKRequest;

typedef void (^ProgressBlock)(double progress);
typedef void (^ResponseBlock)(MKRequest* request);
typedef void (^ErrorBlock)(NSError* requestError);

@interface MKRequest : NSOperation {
    
    @private
    int _state;
}

+ (id)requestWithURLString:(NSString *)urlString
                      body:(NSMutableDictionary *)body
				httpMethod:(NSString *)method;

-(void) cancel;

@property (nonatomic, copy) ProgressBlock uploadProgressChangedHandler;
@property (nonatomic, copy) ProgressBlock downloadProgressChangedHandler;
@property (nonatomic, assign) NSStringEncoding stringEncoding;

-(void) onCompletion:(ResponseBlock) response onError:(ErrorBlock) error;
-(void) setUsername:(NSString*) name password:(NSString*) password;

-(void) addFile:(NSString*) filePath forKey:(NSString*) key;
-(void) addFile:(NSString*) filePath forKey:(NSString*) key mimeType:(NSString*) mimeType;

-(NSData*) responseData;
-(NSString*)responseString; // defaults to UTF8
-(NSString*) responseStringWithEncoding:(NSStringEncoding) encoding;

#ifdef __IPHONE_5_0
-(id) responseJSON;
#endif
@end
