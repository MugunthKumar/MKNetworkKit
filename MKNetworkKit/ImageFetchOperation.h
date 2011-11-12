//
//  ImageFetchOperation.h
//  ImageCache
//
//  Created by Mugunth on 25/2/11.
//  Copyright 2011 Steinlogic. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ImageBlock)(UIImage* image, NSURL* url);
@interface ImageFetchOperation : NSOperation

@property (nonatomic, copy) void (^completionBlock)();
@property (nonatomic, retain) NSURL *photoURL;
@property (nonatomic, retain) NSMutableArray *observerBlocks;

-(id) initWithURL:(NSURL*) url onCompletion:(void(^)()) block;
-(void) addImageFetchObserverBlock:(void(^)(UIImage* image, NSURL* url)) newBlock;

@end
