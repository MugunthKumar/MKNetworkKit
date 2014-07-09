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
#import "MKObject.h"

#if TARGET_OS_IPHONE
#import "UIImageView+MKNKAdditions.h"
#elif TARGET_OS_MAC
#endif

#if TARGET_OS_IPHONE
#import "UIAlertView+MKNKAdditions.h"
#elif TARGET_OS_MAC
#import "NSAlertView+MKNKAdditions.h"
#endif

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

#ifdef DEBUG
#define DLog(fmt, ...) {NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);}
#else
#define DLog(...)
#endif

// ALog always displays output regardless of the DEBUG setting
#define ALog(fmt, ...) {NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);}
#endif
