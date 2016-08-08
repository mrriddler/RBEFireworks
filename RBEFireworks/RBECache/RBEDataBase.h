//
//  RBEDataBase.h
//  RBECache
//
//  Created by Robbie on 16/5/25.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class RBEResultSet;

@interface RBEDataBase : NSObject {
    sqlite3 *_db;
    NSString *_path;
    
    CFMutableDictionaryRef _cachedStatement;
    CFMutableDictionaryRef _resultSets;
    
    BOOL _dbIsClosing;
}

- (instancetype)initWithPath:(NSString *)path;

- (BOOL)open;

- (BOOL)close;

- (BOOL)excuteSql:(NSString *)sql;

- (RBEResultSet *)excuteQuery:(NSString *)sql withParametesArr:(NSArray *)parArr;

- (BOOL)excuteUpdate:(NSString *)sql withParametersArr:(NSArray *)parArr;

- (int)lastErrorCode;

- (NSString *)lastErrorMsg;

@end
