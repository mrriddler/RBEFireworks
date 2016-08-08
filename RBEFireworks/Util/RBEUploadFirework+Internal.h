//
//  RBEUploadFirework+Internal.h
//  RBENetWork
//
//  Created by Robbie on 16/7/8.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEUploadFirework.h"

NS_ASSUME_NONNULL_BEGIN

@interface RBEUploadFirework ()

@property (nonatomic, copy) NSString *uploadURL;

//implement AFMultipartFormData Protocol method in this block so that implement upload task NSdata
@property (nullable, nonatomic, copy) AFConstructingBlock mutipartFormDataConstructingBlock;

@end

NS_ASSUME_NONNULL_END