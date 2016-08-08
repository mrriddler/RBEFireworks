//
//  NSDate+RFC1123.h
//  RBENetWork
//
//  Created by Robbie on 15/11/23.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (RFC1123)

+ (NSDate *)rbe_dateFromRFC1123:(NSString *)value;

- (NSString *)rbe_RFC1123String;

@end
