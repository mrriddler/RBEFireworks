//
//  RBECache.h
//  RBEMemoryCache
//
//  Created by Robbie on 16/1/8.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RBECache : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCacheDirectory:(NSString *)cacheDirectory;

- (instancetype)initWithCacheDirectory:(NSString *)cacheDirectory memoryCacheCapacity:(NSUInteger)memoryCacheCapacity;

- (instancetype)initWithCacheDirectory:(NSString *)cacheDirectory memoryCacheCapacity:(NSUInteger)memoryCacheCapacity diskCacheCapacity:(NSUInteger)diskCacheCapacity NS_DESIGNATED_INITIALIZER;

- (void)setObject:(id) object forKeyedSubscript:(id)key;

- (nullable id)objectForKeyedSubscript:(id)key;

- (void)removeObjectWithKey:(id)key;

- (nullable NSDate *)diskCacheModificationDateWithKey:(id)key;

- (void)purgeMemoryCache;

- (void)purgeAllCache;

- (void)setCustomSyncInterval:(NSTimeInterval)interval;

- (void)setCustomSyncCount:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
