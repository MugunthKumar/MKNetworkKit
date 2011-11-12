//
//  ImageFetchOperation.m
//  ImageCache
//
//  Created by Mugunth on 25/2/11
//  Copyright 2011 Steinlogic. All rights reserved.
//

#import "ImageFetchOperation.h"

@implementation ImageFetchOperation

@synthesize photoURL = _photoURL;
@synthesize observerBlocks = _observerBlocks;
@synthesize completionBlock = _completionBlock;

-(id) initWithURL:(NSURL*) url onCompletion:(void(^)()) block
{
	if((self = [super init]))
	{
    self.completionBlock = block;
    self.photoURL = url;    
    self.observerBlocks = [NSMutableArray array];
	}
	
	return self;
}


-(NSString*) description
{
	return [NSString stringWithFormat:@"URL: %@", self.photoURL];
}

#pragma mark -
- (void)main 
{
    @autoreleasepool {
        
        /*
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:self.photoURL];
    
    [request setCompletionBlock:^
     {
         UIImage *downloadedImage = nil;
         
         int statusCode = [request responseStatusCode];
         NSString *contentType = [[request responseHeaders] objectForKey:@"Content-Type"];
         
         if(statusCode >= 200 && statusCode < 300 && [contentType isEqualToString:@"image/jpeg"])
         {
             downloadedImage = [UIImage imageWithData:[request responseData]];
         }
         else
         {
             DLog(@"Error: %d - %@", statusCode, [request responseStatusMessage]);
             return;
         }
         
         for(ImageBlock block in self.observerBlocks)
             block(downloadedImage, self.photoURL);
         
         _completionBlock();
     }
     ];
    
    [request setFailedBlock:^
     {
         DLog(@"Failed fetching image at: %@", self.photoURL);
         _completionBlock();
     }
     ];
     
    [request startSynchronous];*/
    }
}

-(void) addImageFetchObserverBlock:(void(^)(UIImage* image, NSURL* url)) newBlock
{
    [self.observerBlocks addObject:[newBlock copy]];
}

- (void)dealloc {
    _photoURL = nil;
    _completionBlock = nil;
  _observerBlocks = nil;
}


@end
