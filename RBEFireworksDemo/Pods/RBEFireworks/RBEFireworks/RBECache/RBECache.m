//
//  RBECache.m
//  RBEMemoryCache
//
//  Created by Robbie on 16/1/8.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBECache.h"
#import "RBEMemoryCache.h"
#import "RBEDiskCache.h"
#import <pthread.h>
#import <UIKit/UIKit.h>

static const NSTimeInterval RBEDefaultSyncInterval = 5;
static const NSUInteger RBEDefaultSyncCount = 3;

@interface RBECache ()

@property (nonatomic, strong) RBEMemoryCache *memoryCache;
@property (nonatomic, strong) RBEDiskCache *diskCache;
@property (nonatomic, strong) NSMutableArray *syncArr;
@property (nonatomic, assign) NSTimeInterval syncInterval;
@property (nonatomic, assign) NSUInteger syncCount;

@end

@implementation RBECache {
    pthread_mutex_t _mutexLock;
    dispatch_queue_t _queue;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"RBECache should be initialized with design initializer initWithCacheDirectory:inMemoryCost Or initWithCacheDirectory:"
                                 userInfo:nil];
}

- (instancetype)initWithCacheDirectory:(NSString *)cacheDirectory {
    return [self initWithCacheDirectory:cacheDirectory memoryCacheCapacity:0 diskCacheCapacity:0];
}

- (instancetype)initWithCacheDirectory:(NSString *)cacheDirectory memoryCacheCapacity:(NSUInteger)memoryCacheCapacity {
    return [self initWithCacheDirectory:cacheDirectory memoryCacheCapacity:memoryCacheCapacity diskCacheCapacity:0];
}

- (instancetype)initWithCacheDirectory:(NSString *)cacheDirectory memoryCacheCapacity:(NSUInteger)memoryCacheCapacity diskCacheCapacity:(NSUInteger)diskCacheCapacity {
    self = [super init];
    if (self) {
        self.syncArr = [[NSMutableArray alloc] init];
        self.syncInterval = RBEDefaultSyncInterval;
        self.syncCount = RBEDefaultSyncCount;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sync) name:UIApplicationWillTerminateNotification object:nil];
        
        pthread_mutex_init(&_mutexLock, NULL);
        _queue = dispatch_queue_create("com.rbe.cache.sync", DISPATCH_QUEUE_SERIAL);
        
        if (memoryCacheCapacity) {
            self.memoryCache = [[RBEMemoryCache alloc] initWithMemoryCapacity:memoryCacheCapacity];
        } else {
            self.memoryCache = [[RBEMemoryCache alloc] init];
        }
        
        if (diskCacheCapacity) {
            self.diskCache = [[RBEDiskCache alloc] initWithDirectoryPath:cacheDirectory WithDiskCapacity:diskCacheCapacity];
        } else {
            self.diskCache = [[RBEDiskCache alloc] initWithDirectoryPath:cacheDirectory];
        }
        
        [self syncRecursively];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

- (void)setObject:(id)object forKeyedSubscript:(id)key {
    self.memoryCache[key] = object;
    
    [self mutexLock];
    [self.syncArr addObject:key];
    NSUInteger arrCount = self.syncArr.count;
    NSUInteger syncCount = self.syncCount;
    [self mutexUnlock];
    
    if (arrCount >= syncCount) {
        dispatch_async(_queue, ^{
            [self sync];
        });
    }
}

- (id)objectForKeyedSubscript:(id)key {
    id object = nil;
    
    if (self.memoryCache[key]) {
        object = self.memoryCache[key];
        [self.diskCache setLeastUsedDate:[[NSDate alloc] init] forKey:key];
    } else if (self.diskCache[key]) {
        object = self.diskCache[key];
        self.memoryCache[key] = object;
    }
    
    return object;
}

- (void)removeObjectWithKey:(id)key {
    [self.memoryCache removeObjectWithKey:key];
    [self.diskCache removeObjectWithKey:key];
    
    [self mutexLock];
    [self.syncArr removeObject:key];
    [self mutexUnlock];
}

- (NSDate *)diskCacheModificationDateWithKey:(id)key {
    return [self.diskCache modificationDateWithKey:key];
}

- (void)purgeMemoryCache {
    [self sync];
    [self.memoryCache removeAllObjects];
}

- (void)purgeAllCache {
    [self mutexLock];
    [self.syncArr removeAllObjects];
    [self mutexUnlock];
    
    [self.memoryCache removeAllObjects];
    [self.diskCache removeAllObjects];
}

- (void)setCustomSyncCount:(NSUInteger)count {
    [self mutexLock];
    self.syncCount = count;
    [self mutexUnlock];
}

- (void)setCustomSyncInterval:(NSTimeInterval)interval {
    [self mutexLock];
    self.syncInterval = interval;
    [self mutexUnlock];
}

- (void)sync {
    [self mutexLock];
    
    [self.syncArr enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        id obj = self.memoryCache[key];
        if (obj) {
            self.diskCache[key] = obj;
        }
    }];
    
    [self.syncArr removeAllObjects];
    
    [self mutexUnlock];
}

- (void)syncRecursively {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.syncInterval * NSEC_PER_SEC)), _queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf sync];
        [strongSelf syncRecursively];
    });
}

- (void)mutexLock {
    pthread_mutex_lock(&_mutexLock);
}

- (void)mutexUnlock {
    pthread_mutex_unlock(&_mutexLock);
}

@end
