//
//  NSDictionary+RBEAddition.h
//  RBENetWork
//
//  Created by Robbie on 15/11/24.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (RBEAddition)

//return value by key whether upercase or lowercase
- (id)rbe_objectForInsensitiveKey:(id)key;
//response header content whether is image
- (BOOL)rbe_isContentTypeImage;
//response header cache-control whether is no-cache
- (BOOL)rbe_isCacheable;
//response header whether have any valid cache information header
- (BOOL)rbe_hasHTTPCacheHeaders;
//according to response header calculate expiredate
- (NSDate *)rbe_cacheExpireDate;
//response header date or now
- (NSDate *)rbe_Date;

@end
