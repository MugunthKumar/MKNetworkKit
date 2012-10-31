//
//  ExampleUploader.m
//  MKNetworkKitDemo
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

#import "ExampleUploader.h"

@implementation ExampleUploader

-(MKNetworkOperation*) uploadImageFromFile:(NSString*) file 
                              onCompletion:(TwitPicBlock) completionBlock
                                   onError:(MKNKErrorBlock) errorBlock {
  
  MKNetworkOperation *op = [self operationWithPath:@"api/upload" 
                                            params:@{@"username": kTwitterUserName,
                                                    @"password": kTwitterPassword}
                                        httpMethod:@"POST"];
  
  [op addFile:file forKey:@"media"];
  
  // setFreezable uploads your images after connection is restored!
  [op setFreezable:YES];
  
  [op onCompletion:^(MKNetworkOperation* completedOperation) {
    
    NSString *xmlString = [completedOperation responseString];
    NSUInteger start = [xmlString rangeOfString:@"<mediaurl>"].location;
    if(start == NSNotFound) {
      
      DLog(@"%@", xmlString);
      errorBlock(nil);
      return;
    }
    xmlString = [xmlString substringFromIndex:start + @"<mediaurl>".length];
    NSUInteger end = [xmlString rangeOfString:@"</mediaurl>"].location;
    xmlString = [xmlString substringToIndex:end];
    completionBlock(xmlString);
  }
           onError:^(NSError* error) {
             
             errorBlock(error);
           }];
  
  [self enqueueOperation:op];
  
  
  return op;
}

@end
