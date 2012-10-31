//
//  FlickrCell.h
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth Kumar on 22/1/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlickrCell : UITableViewCell 

@property (nonatomic, strong) IBOutlet UIImageView *thumbnailImage;
@property (nonatomic, assign) IBOutlet UILabel *titleLabel;
@property (nonatomic, assign) IBOutlet UILabel *authorNameLabel;

@property (nonatomic, strong) NSString* loadingImageURLString;
@property (nonatomic, strong) MKNetworkOperation* imageLoadingOperation;
-(void) setFlickrData:(NSDictionary*) thisFlickrImage;
@end
