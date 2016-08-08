//
//  RBEDiskCache.h
//  RBECache
//
//  Created by Robbie on 16/5/26.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RBEDiskCache : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDirectoryPath:(NSString *)directoryPath;

- (instancetype)initWithDirectoryPath:(NSString *)directoryPath WithDiskCapacity:(NSInteger)diskCapacity NS_DESIGNATED_INITIALIZER;

- (void)setObject:(id) object forKeyedSubscript:(id)key;

- (nullable id)objectForKeyedSubscript:(id)key;

- (void)trimToCapacity:(NSInteger)capacity;

- (void)setLeastUsedDate:(NSDate *)date forKey:(id)key;

- (nullable NSDate *)leastUsedDateWithKey:(id)key;

- (nullable NSDate *)modificationDateWithKey:(id)key;

- (void)removeObjectWithKey:(id)key;

- (void)removeAllObjects;

@end

NS_ASSUME_NONNULL_END
