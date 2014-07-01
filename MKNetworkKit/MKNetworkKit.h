//
//  MKNetworkKit.h
//  Tokyo
//
//  Created by Mugunth on 26/6/14.
//  Copyright (c) 2014 LifeOpp Pte Ltd. All rights reserved.
//

#ifndef MKNetworkKit_h
#define MKNetworkKit_h

#import "MKNetworkHost.h"
#import "MKNetworkRequest.h"
#import "UIImageView+MKNKAdditions.h"

#ifdef __OBJC_GC__
#error MKNetworkKit does not support Objective-C Garbage Collection
#endif

#if TARGET_OS_IPHONE
#ifndef __IPHONE_7_0
#error MKNetworkKit is supported only on iOS 7 and above
#endif
#endif

#if TARGET_OS_MAC
#ifndef __MAC_10_9
#error MKNetworkKit is supported only on Mac OS X Mavericks and above
#endif
#endif

#if ! __has_feature(objc_arc)
#error MKNetworkKit is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#endif
