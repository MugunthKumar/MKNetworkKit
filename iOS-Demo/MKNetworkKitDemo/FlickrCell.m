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
                                                                         //size:CGSizeMake(self.thumbnailImage.frame.size.width * 2, self.thumbnailImage.frame.size.height * 2) // uncomment this line to load images in background. It's slow though.
                                    onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
                                        
                                        if([self.loadingImageURLString isEqualToString:[url absoluteString]]) {
                                            
                                            if (isInCache) {
                                                self.thumbnailImage.image = fetchedImage;
                                            } else {
                                                UIImageView *loadedImageView = [[UIImageView alloc] initWithImage:fetchedImage];
                                                loadedImageView.frame = self.thumbnailImage.frame;
                                                loadedImageView.alpha = 0;
                                                [self.contentView addSubview:loadedImageView];
                                                
                                                [UIView animateWithDuration:0.4
                                                                 animations:^
                                                 {
                                                     loadedImageView.alpha = 1;
                                                     self.thumbnailImage.alpha = 0;
                                                 }
                                                                 completion:^(BOOL finished)
                                                 {
                                                     self.thumbnailImage.image = fetchedImage;
                                                     self.thumbnailImage.alpha = 1;
                                                     [loadedImageView removeFromSuperview];
                                                 }];
                                            }
                                        }
                                    }];
}

@end
