//
//  RBEDataBase.m
//  RBECache
//
//  Created by Robbie on 16/5/25.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEDataBase.h"
#import <CommonCrypto/CommonDigest.h>
#import "RBEResultSet.h"
#import "RBEMarco.h"

static NSString *md5Str(NSString *string) {
    const char *str = [string UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (uint32_t)strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
}

@interface RBEResultSet ()

- (void)setResultSetId:(NSString *)resultSetId;

- (NSString *)resultSetId;

- (void)setStatement:(RBEStatement *)statement;

- (void)setDB:(RBEDataBase *)db;

@end

@implementation RBEDataBase

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = [path copy];
        _db = nil;
    }
    return self;
}

- (void)dealloc {
    [self close];
}

- (BOOL)open {
    if (_db) {
        return true;
    }
    
    if (_dbIsClosing) {
        return false;
    }
    
    int responseCode = sqlite3_open(_path.UTF8String, &_db);
    if (responseCode == SQLITE_OK) {
        CFDictionaryValueCallBacks cachedStatementValueCallbacks = {0};
        _cachedStatement = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &cachedStatementValueCallbacks);
        
        CFDictionaryValueCallBacks resultSetsValueCallbacks = {0};
        _resultSets = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &resultSetsValueCallbacks);
        return true;
    } else {
        _db = nil;
        RBELog(@"database openning failed %d", responseCode);
        return false;
    }
}

- (BOOL)close {
    if (!_db) {
        return true;
    }
    
    if (_dbIsClosing) {
        return false;
    }
    
    _dbIsClosing = true;
    
    CFRelease(_cachedStatement);
    _cachedStatement = nil;
    
    CFRelease(_resultSets);
    _resultSets = nil;
    
    int responseCode;
    BOOL retry = false;
    BOOL finalizeStmt = false;
    
    do {
        retry = false;
        responseCode = sqlite3_close(_db);
        if (responseCode == SQLITE_BUSY || responseCode == SQLITE_LOCKED) {
            if (!finalizeStmt) {
                finalizeStmt = true;
                sqlite3_stmt *pStmt;
                while ((pStmt = sqlite3_next_stmt(_db, nil)) != 0) {
                    sqlite3_finalize(pStmt);
                    retry = true;
                }
            }
        } else if (responseCode != SQLITE_OK) {
            RBELog(@"RBEDatabase: error occur database closing");
        }
        
    } while (retry);
    
    _db = nil;
    _dbIsClosing = false;
    return true;
}

- (RBEStatement *)prepareStatementWithSql:(NSString *)sql {
    sqlite3_stmt *pStmt;
    pStmt = (sqlite3_stmt *)CFDictionaryGetValue(_cachedStatement, (__bridge const void *)sql);
    
    if (!pStmt) {
        int responseCode = sqlite3_prepare_v2(_db, sql.UTF8String, -1, &pStmt, 0);
        if (responseCode != SQLITE_OK) {
            RBELog(@"RBEDatabase: error occur statement preparing errorcode %d errorMsg %@", [self lastErrorCode], [self lastErrorMsg]);
            
            sqlite3_finalize(pStmt);
            return nil;
        } else {
            CFDictionarySetValue(_cachedStatement, (__bridge const void *)sql, pStmt);
        }
    } else {
        sqlite3_reset(pStmt);
    }
    
    RBEStatement *statement = [[RBEStatement alloc] init];
    [statement setStmt:pStmt];
    
    return statement;
}

- (void)bindObject:(id)obj toIndex:(int)idx ofStmt:(sqlite3_stmt *)pStmt {
    if (!obj || [obj isKindOfClass:[NSNull class]]) {
        sqlite3_bind_null(pStmt, idx);
    } else if ([obj isKindOfClass:[NSData class]]) {
        const void *bytes = [obj bytes];
        if (!bytes) {
            bytes = "";
        }
        
        sqlite3_bind_blob(pStmt, idx, bytes, (int)[obj length], SQLITE_STATIC);
    } else if ([obj isKindOfClass:[NSDate class]]) {
        sqlite3_bind_double(pStmt, idx, [obj timeIntervalSince1970]);
    } else if ([obj isKindOfClass:[NSNumber class]]) {
        if (strcmp([obj objCType], @encode(unsigned char)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj unsignedCharValue]);
        } else if (strcmp([obj objCType], @encode(unsigned short)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj unsignedShortValue]);
        } else if (strcmp([obj objCType], @encode(unsigned int)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj unsignedIntValue]);
        } else if (strcmp([obj objCType], @encode(unsigned long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj unsignedLongValue]);
        } else if (strcmp([obj objCType], @encode(unsigned long long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj unsignedLongLongValue]);
        } else if (strcmp([obj objCType], @encode(bool)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj boolValue] ? 1 : 0);
        } else if (strcmp([obj objCType], @encode(char)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj charValue]);
        } else if (strcmp([obj objCType], @encode(short)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj shortValue]);
        } else if (strcmp([obj objCType], @encode(int)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj intValue]);
        } else if (strcmp([obj objCType], @encode(long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj longValue]);
        } else if (strcmp([obj objCType], @encode(long long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj longLongValue]);
        } else if (strcmp([obj objCType], @encode(float)) == 0) {
            sqlite3_bind_double(pStmt, idx, [obj floatValue]);
        } else if (strcmp([obj objCType], @encode(double)) == 0) {
            sqlite3_bind_double(pStmt, idx, [obj doubleValue]);
        } else {
            sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
        }
    } else {
        sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
    }
}

- (BOOL)excuteSql:(NSString *)sql {
    NSParameterAssert(sql.length > 0);
    
    if (![self dbIsAvialable]) {
        return false;
    }
    
    char *error = nil;
    int responseCode = sqlite3_exec(_db, sql.UTF8String, NULL, NULL, &error);
    if (error) {
        RBELog(@"RBEDatabase: error occur sql excuting errorMsg %@", [NSString stringWithUTF8String:error]);
        sqlite3_free(error);
        return false;
    }
    
    return responseCode == SQLITE_OK;
}

- (RBEResultSet *)excuteQuery:(NSString *)sql withParametesArr:(NSArray *)parArr {
    if (![self dbIsAvialable]) {
        return nil;
    }
    
    RBEStatement *statement = [self prepareStatementWithSql:sql];
    RBEResultSet *resultSet = nil;
    
    if (statement) {
        int count = sqlite3_bind_parameter_count(statement.stmt);
        
        NSAssert(count == parArr.count, @"RBEDatabase: sql sentence and parArr count not match");
        
        for (int i = 0; i < count; i++) {
            int j = i + 1;
            [self bindObject:parArr[i] toIndex:j ofStmt:statement.stmt];
        }
        
        resultSet = [RBEResultSet resultSetWithStatement:statement usingDB:self];
        NSString *resultSetId = md5Str([NSString stringWithFormat:@"%@%d", sql, (int)time(nil)]);
        [resultSet setResultSetId:resultSetId];
        
        CFDictionarySetValue(_resultSets, (__bridge const void *)resultSetId, (__bridge const void *)resultSet);
    } else {
        return nil;
    }
    
    return resultSet;
}

- (BOOL)excuteUpdate:(NSString *)sql withParametersArr:(NSArray *)parArr {
    if (![self dbIsAvialable]) {
        return false;
    }
    
    RBEStatement *statement = [self prepareStatementWithSql:sql];
    int responseCode;
    
    if (statement) {
        int count = sqlite3_bind_parameter_count(statement.stmt);
        
        NSAssert(count == parArr.count, @"RBEDatabase: sql sentence and parArr count not match");
        
        for (int i = 0; i < count; i++) {
            int j = i + 1;
            [self bindObject:parArr[i] toIndex:j ofStmt:statement.stmt];
        }
        
        responseCode = sqlite3_step(statement.stmt);
        
        if (responseCode != SQLITE_DONE) {
            RBELog(@"RBEDatabase: error occur update excuting errorcode %d errorMsg %@", [self lastErrorCode], [self lastErrorMsg]);
        }
    } else {
        return false;
    }
    
    return responseCode == SQLITE_DONE;
}

- (void)closeResultSet:(RBEResultSet *)resultSet {
    CFDictionaryRemoveValue(_resultSets, (__bridge const void *)resultSet.resultSetId);
}

- (BOOL)dbIsAvialable {
    return (_db && !_dbIsClosing);
}

- (int)lastErrorCode {
    return sqlite3_errcode(_db);
}

- (NSString *)lastErrorMsg {
    return [NSString stringWithUTF8String:sqlite3_errmsg(_db)];
}

@end
