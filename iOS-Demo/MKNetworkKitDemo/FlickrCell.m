//
//  FlickrCell.m
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth Kumar on 22/1/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "FlickrCell.h"

@implementation FlickrCell

//=========================================================== 
// + (BOOL)automaticallyNotifiesObserversForKey:
//
//=========================================================== 
+ (BOOL)automaticallyNotifiesObserversForKey: (NSString *)theKey 
{
    BOOL automatic;
    
    if ([theKey isEqualToString:@"thumbnailImage"]) {
        automatic = NO;
    } else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }
    
    return automatic;
}

-(void) prepareForReuse {
    
    self.thumbnailImage.image = nil;
    [self.imageLoadingOperation cancel];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void) setFlickrData:(NSDictionary*) thisFlickrImage {
    
    self.titleLabel.text = thisFlickrImage[@"title"];
	self.authorNameLabel.text = thisFlickrImage[@"owner"];
    self.loadingImageURLString =
    [NSString stringWithFormat:@"http://farm%@.static.flickr.com/%@/%@_%@_s.jpg", 
     thisFlickrImage[@"farm"], thisFlickrImage[@"server"], 
     thisFlickrImage[@"id"], thisFlickrImage[@"secret"]];
    
    self.imageLoadingOperation = [ApplicationDelegate.flickrEngine imageAtURL:[NSURL URLWithString:self.loadingImageURLString]
                                                                         size:self.thumbnailImage.frame.size
                                    completionHandler:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
                                        
                                        if([self.loadingImageURLString isEqualToString:[url absoluteString]]) {
                                          
                                          [UIView transitionWithView:self.contentView
                                                            duration:isInCache?0.1f:0.4f
                                                             options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                                                               self.thumbnailImage.image = fetchedImage;
                                                             } completion:nil];
                                        }
                                    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
                                      
                                    }];
}

@end
