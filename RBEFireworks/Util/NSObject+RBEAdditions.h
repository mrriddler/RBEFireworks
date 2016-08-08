//
//  NSObject+RBEAdditions.h
//  RBENetWork
//
//  Created by Robbie on 15/11/19.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (RBEAdditions)

+ (BOOL)rbe_checkJson:(id)json withValidator:(id)validatorJson;

@end
