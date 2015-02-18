//
//  UIImageView+MKNKAdditions.m
//  Tokyo
//
//  Created by Mugunth on 30/6/14.
//  Copyright (c) 2014 LifeOpp Pte Ltd. All rights reserved.
//

#import <objc/runtime.h>

#import "UIImageView+MKNKAdditions.h"

#import "MKNetworkKit.h"

static MKNetworkHost *imageHost;
static char imageFetchRequestKey;

const float kFromCacheAnimationDuration = 0.0f;
const float kFreshLoadAnimationDuration = 0.25f;

@implementation UIImageView (MKNKAdditions)

+(void) initialize {
  
  imageHost = [[MKNetworkHost alloc] init];
  [imageHost enableCache];
}

+(MKNetworkRequest*) cacheImageFromURLString:(NSString*) imageUrlString {
  
  return [UIImageView cacheImageFromURLString:imageUrlString decompressedImageSize:CGSizeZero];
}

+(MKNetworkRequest*) cacheImageFromURLString:(NSString*) imageUrlString decompressedImageSize:(CGSize) size {
  
  MKNetworkRequest *request = [imageHost requestWithURLString:imageUrlString];
  
  if(!CGSizeEqualToSize(size, CGSizeZero)) {
    
    [request addCompletionHandler:^(MKNetworkRequest *completedRequest) {
      
      [completedRequest decompressedResponseImageOfSize:size];
    }];
  }
  return request;
}

-(MKNetworkRequest*) imageFetchRequest {
  
  return (MKNetworkRequest*) objc_getAssociatedObject(self, &imageFetchRequestKey);
}

-(void) setImageFetchRequest:(MKNetworkRequest *)imageFetchRequest {
  
  objc_setAssociatedObject(self, &imageFetchRequestKey, imageFetchRequest, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(MKNetworkRequest*) loadImageFromURLString:(NSString*) imageUrlString {
  
  return [self loadImageFromURLString:imageUrlString placeHolderImage:nil animated:YES];
}

-(MKNetworkRequest*) loadImageFromURLString:(NSString*) imageUrlString placeHolderImage:(UIImage*) placeHolderImage animated:(BOOL) animated {
  
  if(placeHolderImage)
    self.image = placeHolderImage;
  
  [self.imageFetchRequest cancel];  
  
  self.imageFetchRequest = [imageHost requestWithURLString:imageUrlString];
  [self.imageFetchRequest addCompletionHandler:^(MKNetworkRequest *completedRequest) {
    
    if(completedRequest.responseAvailable) {
      
      CGFloat animationDuration = completedRequest.isCachedResponse?kFromCacheAnimationDuration:kFreshLoadAnimationDuration;
      
      UIImage *decompressedImage = [completedRequest decompressedResponseImageOfSize:self.frame.size];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        
        if(animated) {
          [UIView transitionWithView:self.superview
                            duration:animationDuration
                             options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                          animations:^{
                            self.image = decompressedImage;
                          } completion:nil];
        } else {
          self.image = decompressedImage;
        }

      });
    } else {
      if(completedRequest.state == MKNKRequestStateError)
        NSLog(@"Request: %@ failed with error: %@", completedRequest, completedRequest.error);
    }
  }];
  
  [imageHost startRequest:self.imageFetchRequest];
  
  return self.imageFetchRequest;
}
@end
