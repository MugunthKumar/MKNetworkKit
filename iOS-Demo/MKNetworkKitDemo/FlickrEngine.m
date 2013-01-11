//
//  FlickrEngine.m
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth Kumar (@mugunthkumar) on 22/1/12.
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

#import "FlickrEngine.h"

@implementation FlickrEngine

-(void) imagesForTag:(NSString*) tag completionHandler:(FlickrImagesResponseBlock) imageURLBlock errorHandler:(MKNKErrorBlock) errorBlock {

    MKNetworkOperation *op = [self operationWithPath:FLICKR_IMAGE_URL([tag mk_urlEncodedString])];

    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
    
        [completedOperation responseJSONWithCompletionHandler:^(id jsonObject) {
          imageURLBlock(jsonObject[@"photos"][@"photo"]);
        }];        
        
    } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
        
        errorBlock(error);
    }];
    
    [self enqueueOperation:op];
}

-(NSString*) cacheDirectoryName {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *cacheDirectoryName = [documentsDirectory stringByAppendingPathComponent:@"FlickrImages"];
    return cacheDirectoryName;
}

@end
