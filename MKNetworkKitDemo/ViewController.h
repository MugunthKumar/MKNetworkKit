//
//  ViewController.h
//  MKNetworkKit
//
//  Created by Mugunth Kumar on 7/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) MKNetworkOperation *uploadOperation;
@property (strong, nonatomic) MKNetworkOperation *downloadOperation;
@property (strong, nonatomic) MKNetworkOperation *currencyOperation;

@property (nonatomic, weak) IBOutlet UIProgressView *downloadProgessBar;
@property (nonatomic, weak) IBOutlet UIProgressView *uploadProgessBar;
@end
