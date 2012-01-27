//
//  NSDate+RFC1123.m
//  MKNetworkKit
//
//  Created by Marcus Rohrmoser
//  http://blog.mro.name/2009/08/nsdateformatter-http-header/
//
//  No obvious license attached

#import "NSDate+RFC1123.h"

@implementation NSDate (RFC1123)

+(NSDate*)dateFromRFC1123:(NSString*)value_
{
    if(value_ == nil)
        return nil;    
    
    __strong static NSDateFormatter *rfc1123 = nil;
    if (!rfc1123) {
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            rfc1123 = [[NSDateFormatter alloc] init];
            rfc1123.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            rfc1123.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            rfc1123.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss z";
        });
    }
    NSDate *ret = [rfc1123 dateFromString:value_];
    if(ret != nil)
        return ret;
    
    static NSDateFormatter *rfc850 = nil;
    if(!rfc850)
    {
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            rfc850 = [[NSDateFormatter alloc] init];
            rfc850.locale = rfc1123.locale;
            rfc850.timeZone = rfc1123.timeZone;
            rfc850.dateFormat = @"EEEE',' dd'-'MMM'-'yy HH':'mm':'ss z";
        });
    }
    ret = [rfc850 dateFromString:value_];
    if(ret != nil)
        return ret;
    
    static NSDateFormatter *asctime = nil;
    if(!asctime)
    {
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            
            asctime = [[NSDateFormatter alloc] init];
            asctime.locale = rfc1123.locale;
            asctime.timeZone = rfc1123.timeZone;
            asctime.dateFormat = @"EEE MMM d HH':'mm':'ss yyyy";
        });
    }
    return [asctime dateFromString:value_];
}

-(NSString*)rfc1123String
{
    static NSDateFormatter *df = nil;
    if(!df)
    {
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            df = [[NSDateFormatter alloc] init];
            df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
        });
    }
    return [df stringFromDate:self];
}

@end
