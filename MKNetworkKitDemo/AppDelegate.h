//
//  AppDelegate.h
//  MKNetworkKit
//
//  Created by Mugunth Kumar on 7/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YahooEngine.h"
#import "ExampleUploader.h"
#import "ExampleDownloader.h"

#define ApplicationDelegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) YahooEngine *engine;
@property (strong, nonatomic) ExampleUploader *uploader;
@property (strong, nonatomic) ExampleDownloader *downloader;


@end
