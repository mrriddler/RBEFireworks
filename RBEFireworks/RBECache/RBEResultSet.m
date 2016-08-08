//
//  RBEResultSet.m
//  RBECache
//
//  Created by Robbie on 16/5/25.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEResultSet.h"
#import "RBEDataBase.h"
#import "RBEMarco.h"

@implementation RBEStatement

- (void)reset {
    if (_stmt) {
        sqlite3_reset(_stmt);
    }
}

- (void)close {
    if (_stmt) {
        sqlite3_finalize(_stmt);
        _stmt = nil;
    }
}

- (void)setStmt:(sqlite3_stmt *)stmt {
    _stmt = stmt;
}

- (sqlite3_stmt *)stmt {
    return _stmt;
}

@end

@interface RBEDataBase ()

- (void)closeResultSet:(RBEResultSet *)resultSet;

@end

@implementation RBEResultSet

+ (instancetype)resultSetWithStatement:(RBEStatement *)statement usingDB:(RBEDataBase *)db {
    RBEResultSet *resultSet = [[self alloc] init];
    
    [resultSet setStatement:statement];
    [resultSet setDB:db];
    
    return resultSet;
}

- (void)dealloc {
    [self close];
}

- (BOOL)next {
    int responseCode = sqlite3_step(_statement.stmt);
    
    if (responseCode != SQLITE_DONE && responseCode != SQLITE_ROW) {
        RBELog(@"RBEDatabase: error occur query excuting errorcode %d errorMsg %@", [_db lastErrorCode], [_db lastErrorMsg]);
    }
    
    if (responseCode != SQLITE_ROW) {
        [self close];
    }
        
    return responseCode == SQLITE_ROW;
}

- (void)close {
    [_db closeResultSet:self];
    _db = nil;
}

- (int)intForColumnIndex:(int)columnIdx {
    return sqlite3_column_int(_statement.stmt, columnIdx);
}

- (unsigned int)unsignedIntForColumnIndex:(int)columnIdx {
    return (unsigned int)sqlite3_column_int64(_statement.stmt, columnIdx);
}

- (long)longForColumnIndex:(int)columnIdx {
    return (long)sqlite3_column_int64(_statement.stmt, columnIdx);
}

- (unsigned long)unsignedLongForColumnIndex:(int)columnIdx {
    return (unsigned long)sqlite3_column_int64(_statement.stmt, columnIdx);
}

- (long long)longLongForColumnIndex:(int)columnIdx {
    return sqlite3_column_int64(_statement.stmt, columnIdx);
}

- (unsigned long long)unsignedLongLongForColumnIndex:(int)columnIdx {
    return (unsigned long long)sqlite3_column_int64(_statement.stmt, columnIdx);
}

- (double)doubleForColumnIndex:(int)columnIdx {
    return sqlite3_column_double(_statement.stmt, columnIdx);
}

- (BOOL)boolForColumnIndex:(int)columnIdx {
    return sqlite3_column_int64(_statement.stmt, columnIdx) ? true : false;
}

- (NSString *)stringForColumnIndex:(int)columnIdx {
    if (sqlite3_column_type(_statement.stmt, columnIdx) == SQLITE_NULL) {
        return nil;
    }
    
    const char *c = (const char *)sqlite3_column_text(_statement.stmt, columnIdx);
    if (!c) {
        return nil;
    }
    
    return [NSString stringWithUTF8String:c];
}

- (NSDate *)dateForColumnIndex:(int)columnIdx {
    if (sqlite3_column_type(_statement.stmt, columnIdx) == SQLITE_NULL) {
        return nil;
    }
    
    return [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(_statement.stmt, columnIdx)];
}

- (NSData *)dataForColumnIndex:(int)columnIdx {
    if (sqlite3_column_type(_statement.stmt, columnIdx) == SQLITE_NULL) {
        return nil;
    }
    
    const char *dataBuffer = sqlite3_column_blob(_statement.stmt, columnIdx);
    int dataSize = sqlite3_column_bytes(_statement.stmt, columnIdx);
    
    if (!dataBuffer) {
        return nil;
    }
    
    return [NSData dataWithBytes:dataBuffer length:(NSUInteger)dataSize];
}

- (id)objectForColumnIndex:(int)columnIdx {
    int columnType = sqlite3_column_type(_statement.stmt, columnIdx);
    id result = nil;
    
    if (columnType == SQLITE_INSERT) {
        result = [NSNumber numberWithLongLong:[self longLongForColumnIndex:columnIdx]];
    } else if (columnType == SQLITE_FLOAT) {
        result = [NSNumber numberWithDouble:[self doubleForColumnIndex:columnIdx]];
    } else if (columnType == SQLITE_BLOB) {
        result = [self dataForColumnIndex:columnIdx];
    } else {
        result = [self stringForColumnIndex:columnIdx];
    }
    
    if (!result) {
        result = [NSNull null];
    }
    
    return result;
}

- (NSDictionary *)resultDic {
    NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
    
    int columnCount = sqlite3_column_count(_statement.stmt);
    
    if (columnCount <= 0) {
        return nil;
    }
    
    for (int i = 0; i < columnCount; i++) {
        NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(_statement.stmt, i)];
        resultDic[columnName] = [self objectForColumnIndex:i];
    }
    
    return [resultDic copy];
}

- (void)setStatement:(RBEStatement *)statement {
    _statement = statement;
}

- (void)setDB:(RBEDataBase *)db {
    _db = db;
}

- (void)setResultSetId:(NSString *)resultSetId {
    _resultSetId = resultSetId;
}

- (NSString *)resultSetId {
    return _resultSetId;
}

@end

