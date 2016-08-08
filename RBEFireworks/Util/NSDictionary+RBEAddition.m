//
//  NSDictionary+RBEAddition.m
//  RBENetWork
//
//  Created by Robbie on 15/11/24.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import "NSDictionary+RBEAddition.h"
#import "NSDate+RFC1123.h"

@implementation NSDictionary (RBEAddition)

- (id)rbe_objectForInsensitiveKey:(id)key {
    __block id obj = nil;
    id theKey = key;
    [self.allKeys enumerateObjectsUsingBlock:^(NSString *akey, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([akey compare:theKey options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            obj = [self objectForKey:akey];
            *stop = YES;
        }
    }];
    
    return obj;
}

- (BOOL)rbe_isContentTypeImage {
    NSString *contentType = [self rbe_objectForInsensitiveKey:@"Content-Type"];
    if ([contentType.lowercaseString rangeOfString:@"image"].location != NSNotFound) {
        return YES;
    }
    
    return NO;
}

- (BOOL)rbe_hasHTTPCacheHeaders {
    NSString *cacheControl = [self rbe_objectForInsensitiveKey:@"Cache-Control"];
    NSString *Etag = [self rbe_objectForInsensitiveKey:@"Etag"];
    NSString *lastModifed = [self rbe_objectForInsensitiveKey:@"Last-Modified"];
    NSString *expires = [self rbe_objectForInsensitiveKey:@"Expires"];
    
    return (cacheControl || Etag || lastModifed || expires);
}

- (BOOL)rbe_isCacheable {
    NSString *cacheControl = [self rbe_objectForInsensitiveKey:@"Cache-Control"];
    if (cacheControl && [cacheControl.lowercaseString rangeOfString:@"no-cache"].location != NSNotFound) {
        return NO;
    }
    
    if (cacheControl && [cacheControl.lowercaseString rangeOfString:@"no-store"].location != NSNotFound) {
        return NO;
    }
    
    NSDate *expires = [self rbe_Expires];
    if (expires) {
        if ([[self rbe_Date] compare:expires] == NSOrderedDescending) {
            return NO;
        }
    }
    
    NSString *maxAge = [self rbe_MaxAge];
    if (maxAge && [maxAge integerValue] <= 0) {
        return NO;
    }
    
    NSDate *lastModified = [self rbe_LastModified];
    if (lastModified && [[self rbe_Date] compare:lastModified] == NSOrderedAscending) {
        return NO;
    }
    
    return YES;
}

- (NSDate *)rbe_cacheExpireDate {
    NSDate *expireDate = nil;
    
    expireDate = [self rbe_Expires];
    if (expireDate) {
        return expireDate;
    }
    
    NSString *maxAge = [self rbe_MaxAge];
    if (maxAge) {
        expireDate = [[NSDate date] dateByAddingTimeInterval:[maxAge integerValue]];
    }
    return expireDate;
}

- (NSDate *)rbe_Date {
    NSString *date = [self valueForKey:@"Date"];
    NSDate *responseDate = date ? [NSDate rbe_dateFromRFC1123:date] : [NSDate date];
    return responseDate;
}

- (NSString *)rbe_MaxAge {
    NSString *maxAgeStr = nil;
    NSString *cacheContorl = [self rbe_objectForInsensitiveKey:@"Cache-Control"];
    
    NSInteger maxAge;
    NSRange cacheControlRange = [cacheContorl rangeOfString:@"max-age"];
    if (cacheControlRange.length > 0) {
        NSScanner *cacheControlScanner = [NSScanner scannerWithString:cacheContorl];
        [cacheControlScanner setScanLocation:cacheControlRange.location + cacheControlRange.length];
        [cacheControlScanner scanString:@"=" intoString:nil];
        if ([cacheControlScanner scanInteger:&maxAge]) {
            maxAgeStr = [NSString stringWithFormat:@"%ld", (long)maxAge];
        }
    }
    
    return maxAgeStr;
}

- (NSDate *)rbe_Expires {
    NSDate *expiresDate = nil;
    NSString *expires = [self rbe_objectForInsensitiveKey:@"Expires"];
    expiresDate = [NSDate rbe_dateFromRFC1123:expires];
    return expiresDate;
}

- (NSDate *)rbe_LastModified {
    NSDate *lastModifiedDate = nil;
    NSString *lastModified = [self rbe_objectForInsensitiveKey:@"Last-Modified"];
    lastModifiedDate = [NSDate rbe_dateFromRFC1123:lastModified];
    return lastModifiedDate;
}

@end
