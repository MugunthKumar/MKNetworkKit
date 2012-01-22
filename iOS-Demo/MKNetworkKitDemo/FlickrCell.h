//
//  FlickrCell.h
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth Kumar on 22/1/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlickrCell : UITableViewCell 

@property (nonatomic, assign) IBOutlet UIImageView *thumbnailImage;
@property (nonatomic, assign) IBOutlet UILabel *titleLabel;
@property (nonatomic, assign) IBOutlet UILabel *authorNameLabel;

@property (nonatomic, assign) NSString* loadingImageURLString;
-(void) setFlickrData:(NSDictionary*) thisFlickrImage;
@end
