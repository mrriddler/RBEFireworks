//
//  RBEMemoryCache.h
//  RBEMemoryCache
//
//  Created by Robbie on 16/1/4.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RBEMemoryCache : NSObject

- (instancetype)init;

- (instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity;

- (void)setObject:(id) object forKeyedSubscript:(id)key;

- (nullable id)objectForKeyedSubscript:(id)key;

- (void)removeObjectWithKey:(id)key;

- (void)removeAllObjects;

@end

NS_ASSUME_NONNULL_END
