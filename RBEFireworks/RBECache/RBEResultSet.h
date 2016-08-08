//
//  RBEResultSet.h
//  RBECache
//
//  Created by Robbie on 16/5/25.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class RBEDataBase;

@interface RBEStatement : NSObject {
    sqlite3_stmt *_stmt;
}

- (void)setStmt:(sqlite3_stmt *)stmt;

- (sqlite3_stmt *)stmt;

- (void)reset;

- (void)close;

@end

@interface RBEResultSet : NSObject {
    RBEDataBase *_db;
    RBEStatement *_statement;
    
    NSString *_resultSetId;
}

+ (instancetype)resultSetWithStatement:(RBEStatement *)statement usingDB:(RBEDataBase *)db;

- (BOOL)next;

- (void)close;

- (int)intForColumnIndex:(int)columnIdx;

- (unsigned int)unsignedIntForColumnIndex:(int)columnIdx;

- (long)longForColumnIndex:(int)columnIdx;

- (unsigned long)unsignedLongForColumnIndex:(int)columnIdx;

- (long long)longLongForColumnIndex:(int)columnIdx;

- (unsigned long long)unsignedLongLongForColumnIndex:(int)columnIdx;

- (BOOL)boolForColumnIndex:(int)columnIdx;

- (double)doubleForColumnIndex:(int)columnIdx;

- (NSString *)stringForColumnIndex:(int)columnIdx;

- (NSDate *)dateForColumnIndex:(int)columnIdx;

- (NSData *)dataForColumnIndex:(int)columnIdx;

- (id)objectForColumnIndex:(int)columnIdx;

- (NSDictionary *)resultDic;

@end


