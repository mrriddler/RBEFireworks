//
//  RBEDiskCache.m
//  RBECache
//
//  Created by Robbie on 16/5/26.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEDiskCache.h"
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>
#import <sys/stat.h>
#import "RBEDataBase.h"
#import "RBEResultSet.h"
#import "RBEMarco.h"

static NSString *const kRBECacheDBPathComponent = @"rbeCache.sqlite";

static NSString *md5Str(NSString *string) {
    const char *str = [string UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (uint32_t)strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
}

@interface RBECacheRelation : NSObject

@property (nonatomic, strong) NSString *cacheId;
@property (nonatomic, strong) NSData *cacheContent;
@property (nonatomic, assign) int leastUsedTime;
@property (nonatomic, assign) int size;
@property (nonatomic, assign) int modificationTime;

+ (NSString *)creatTable;

+ (NSString *)sumSize;

+ (NSString *)insertOrReplace;

+ (NSString *)query;

+ (NSString *)updateLeastUsedTime;

+ (NSString *)delete;

+ (NSString *)orderByLeastUsedTime;

- (instancetype)initWithDic:(NSDictionary *)dic;

- (NSArray *)parasArr;

@end

@implementation RBECacheRelation

+ (NSString *)creatTable {
    return @"create table if not exists rbecache (cacheId text, cacheContent blob, leastUsedTime integer, size integer, modificationTime integer, primary key(cacheId)); create index if not exists leastUsedTime on rbecache(leastUsedTime);";
}

+ (NSString *)sumSize {
    return @"select sum(size) from rbecache";
}

+ (NSString *)insertOrReplace {
    return @"insert or replace into rbecache (cacheId, cacheContent, leastUsedTime, size, modificationTime) values (?, ?, ?, ?, ?);";
}

+ (NSString *)query {
    return @"select cacheId, cacheContent, leastUsedTime, size, modificationTime from rbecache where cacheId = ?;";
}

+ (NSString *)updateLeastUsedTime {
    return @"update rbecache set leastUsedTime = ? where cacheId = ?";
}

+ (NSString *)delete {
    return @"delete from rbecache where cacheId = ?";
}

+ (NSString *)orderByLeastUsedTime {
    return @"select cacheId, cacheContent, leastUsedTime, size, modificationTime from rbecache order by leastUsedTime desc";
}

- (instancetype)initWithDic:(NSDictionary *)dic {
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dic];
    }
    return self;
}

- (NSArray *)parasArr {
    return @[self.cacheId, self.cacheContent, @(self.leastUsedTime), @(self.size), @(self.modificationTime)];
}

@end

@implementation RBEDiskCache {
    dispatch_semaphore_t _semaphore;
    dispatch_queue_t _queue;
    NSString *_dbPath;
    NSInteger _diskCapacity;
    NSInteger _diskUsage;
    
    RBEDataBase *_rbeDataBase;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"RBEDiskCache must be initialized with design initializer initWithDirectoryPath Or initWithDirectoryPath:WithDiskCapacity"
                                 userInfo:nil];
    return [self initWithDirectoryPath:@""];
}

- (instancetype)initWithDirectoryPath:(NSString *)directoryPath {
    return [self initWithDirectoryPath:directoryPath WithDiskCapacity:0];
}

- (instancetype)initWithDirectoryPath:(NSString *)directoryPath WithDiskCapacity:(NSInteger)diskCapacity {
    self = [super init];
    if (self) {
        _dbPath = [directoryPath stringByAppendingPathComponent:kRBECacheDBPathComponent];
        _semaphore = dispatch_semaphore_create(1);
        _queue = dispatch_queue_create("com.rbe.disk.cache", DISPATCH_QUEUE_CONCURRENT);
        _diskCapacity = diskCapacity;
        
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
            RBELog(@"RBEDatabase: error occur directory creating %@", error);
            return nil;
        }
        
        _rbeDataBase = [[RBEDataBase alloc] initWithPath:_dbPath];
        if (![_rbeDataBase open] || ![_rbeDataBase excuteSql:[RBECacheRelation creatTable]]) {
            RBELog(@"RBEDatabase: error occur database openning");
            return nil;
        }
        
        RBEResultSet *resultSet = [_rbeDataBase excuteQuery:[RBECacheRelation sumSize] withParametesArr:nil];
        
        if ([resultSet next]) {
            _diskUsage = [resultSet intForColumnIndex:0];
        }
        [resultSet close];
    }
    return self;
}

- (void)trimToCapacity:(NSInteger)capacity {
    dispatch_async(_queue, ^{
        [self semaphoreLock];
        
        if (_diskCapacity == 0) {
            [self semaphoreUnLock];
            return;
        }
        
        if (_diskUsage <= _diskCapacity) {
            [self semaphoreUnLock];
            return;
        }
        
        NSMutableArray *cacheArr = [[NSMutableArray alloc] init];
        RBEResultSet *resultSet = [_rbeDataBase excuteQuery:[RBECacheRelation orderByLeastUsedTime] withParametesArr:nil];
        while ([resultSet next]) {
            RBECacheRelation *cacheRelation = [[RBECacheRelation alloc] initWithDic:[resultSet resultDic]];
            
            [cacheArr addObject:cacheRelation];
        }
        [resultSet close];
        
        do {
            RBECacheRelation *cacheRelation = [cacheArr lastObject];
            BOOL isSucceed = [_rbeDataBase excuteUpdate:[RBECacheRelation delete] withParametersArr:@[cacheRelation.cacheId]];
            
            if (!isSucceed) {
                break;
            }
            
            [cacheArr removeLastObject];
            _diskUsage -= cacheRelation.size;
        } while (_diskUsage > _diskCapacity);
        
        [self semaphoreUnLock];
    });
}

- (void)setObject:(id)object forKeyedSubscript:(id)key {
    NSData *cacheContent = nil;
    
    @try {
        cacheContent = [NSKeyedArchiver archivedDataWithRootObject:object];
    } @catch (NSException *exception) {
        // do nothing
    }
    
    if (!cacheContent) {
        return;
    }
    
    RBECacheRelation *cacheRelation = [[RBECacheRelation alloc] init];
    cacheRelation.cacheId = md5Str([NSString stringWithFormat:@"%@", key]);
    cacheRelation.cacheContent = cacheContent;
    cacheRelation.leastUsedTime = (int)time(nil);
    cacheRelation.size = (int)[cacheContent length];
    cacheRelation.modificationTime = (int)time(nil);
    
    [self semaphoreLock];
    
    BOOL isSucceed =  [_rbeDataBase excuteUpdate:[RBECacheRelation insertOrReplace] withParametersArr:[cacheRelation parasArr]];
    
    if (!isSucceed) {
        [self semaphoreUnLock];
        return;
    }
    
    if (_diskCapacity != 0) {
        _diskUsage += cacheRelation.size;
    }
    
    [self semaphoreUnLock];
    
    [self trimToCapacity:_diskCapacity];
}

- (id)objectForKeyedSubscript:(id)key {
    id obj = nil;
    RBECacheRelation *cacheRelation = nil;
    [self semaphoreLock];
    
    RBEResultSet *resultSet = [_rbeDataBase excuteQuery:[RBECacheRelation query] withParametesArr:@[md5Str([NSString stringWithFormat:@"%@", key])]];
    
    if ([resultSet next]) {
        cacheRelation = [[RBECacheRelation alloc] initWithDic:[resultSet resultDic]];
    }
    [resultSet close];
    
    if (cacheRelation) {
        [_rbeDataBase excuteUpdate:[RBECacheRelation updateLeastUsedTime] withParametersArr:@[@((int)time(nil)), cacheRelation.cacheId]];
        
        [self semaphoreUnLock];
        
        @try {
            obj = [NSKeyedUnarchiver unarchiveObjectWithData:cacheRelation.cacheContent];
        } @catch (NSException *exception) {
            // do nothing
        }
    } else {
        [self semaphoreUnLock];
    }
    
    return obj;
}

- (void)setLeastUsedDate:(NSDate *)date forKey:(id)key {
    [self semaphoreLock];
    [self setLeastUsedDateUnLockFile:date forKey:key];
    [self semaphoreUnLock];
}

- (BOOL)setLeastUsedDateUnLockFile:(NSDate *)date forKey:(id)key {
    BOOL isSuccess = true;
    
    isSuccess = [_rbeDataBase excuteUpdate:[RBECacheRelation updateLeastUsedTime] withParametersArr:@[date, md5Str([NSString stringWithFormat:@"%@", key])]];
    
    return isSuccess;
}

- (NSDate *)leastUsedDateWithKey:(id)key {
    NSDate *leastUsedDate = nil;
    RBECacheRelation *cacheRelation = nil;
    
    [self semaphoreLock];
    
    RBEResultSet *resultSet = [_rbeDataBase excuteQuery:[RBECacheRelation query] withParametesArr:@[md5Str([NSString stringWithFormat:@"%@", key])]];
    if ([resultSet next]) {
        cacheRelation = [[RBECacheRelation alloc] initWithDic:[resultSet resultDic]];
    }
    [resultSet close];
    
    [self semaphoreUnLock];
    
    if (cacheRelation) {
        leastUsedDate = [[NSDate alloc] initWithTimeIntervalSince1970:(NSTimeInterval)cacheRelation.leastUsedTime];
    }
    
    return leastUsedDate;
}

- (NSDate *)modificationDateWithKey:(id)key {
    NSDate *modificationDate = nil;
    RBECacheRelation *cacheRelation = nil;
    
    [self semaphoreLock];
    
    RBEResultSet *resultSet = [_rbeDataBase excuteQuery:[RBECacheRelation query] withParametesArr:@[md5Str([NSString stringWithFormat:@"%@", key])]];
    if ([resultSet next]) {
        cacheRelation = [[RBECacheRelation alloc] initWithDic:[resultSet resultDic]];
    }
    [resultSet close];
    
    [self semaphoreUnLock];
    
    if (cacheRelation) {
        modificationDate = [[NSDate alloc] initWithTimeIntervalSince1970:(NSTimeInterval)cacheRelation.modificationTime];
    }
    
    return modificationDate;
}

- (void)removeObjectWithKey:(id)key {
    [self semaphoreLock];
    [self removeObjectInUnlockWithKey:key];
    [self semaphoreUnLock];
}

- (void)removeObjectInUnlockWithKey:(id)key {
    RBECacheRelation *cacheRelation = nil;
    
    RBEResultSet *resultSet = [_rbeDataBase excuteQuery:[RBECacheRelation query] withParametesArr:@[md5Str([NSString stringWithFormat:@"%@", key])]];
    if ([resultSet next]) {
        cacheRelation = [[RBECacheRelation alloc] initWithDic:[resultSet resultDic]];
    }
    [resultSet close];
    
    if (cacheRelation) {
        BOOL isSuccess = [_rbeDataBase excuteUpdate:[RBECacheRelation delete] withParametersArr:@[md5Str([NSString stringWithFormat:@"%@", key])]];
        if (isSuccess) {
            _diskUsage -= cacheRelation.size;
        }
    }
}

- (void)removeAllObjects {
    [self semaphoreLock];
    
    BOOL isSuccess = [_rbeDataBase close];
    if (isSuccess) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:_dbPath error:&error];
        if (error) {
            RBELog(@"RBEDiskCache could not remove file to path : %@", [error localizedFailureReason]);
        } else {
            _diskUsage = 0;
            
            if (![_rbeDataBase open] || ![_rbeDataBase excuteSql:[RBECacheRelation creatTable]]) {
                RBELog(@"RBEDatabase: error occur database openning");
            }
        }
    }
    
    [self semaphoreUnLock];
}

- (void)semaphoreLock {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
}

- (void)semaphoreUnLock {
    dispatch_semaphore_signal(_semaphore);
}

@end
