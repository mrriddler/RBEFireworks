//
//  RBEFirework+Internal.h
//  RBENetWork
//
//  Created by Robbie on 16/7/7.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEFirework.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RBEFireworkInternalDelegate <NSObject>

@required

- (void)fireworkFinished:(RBEFirework *)firework;
- (void)fireworkFailed:(RBEFirework *)firework;

@end

@interface RBEFirework ()

@property (nullable, nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nullable, nonatomic, strong) NSURLSessionDownloadTask *downLoadTask;

@property (nullable, nonatomic, copy) SuccessBlock successBlock;
@property (nullable, nonatomic, copy) FailureBlock failureBlock;

//do not directly call this delegate, internal impletion deleagate
@property (nullable, nonatomic, strong) id<RBEFireworkInternalDelegate> internalDelegate;

@property (nullable, nonatomic, strong) NSMutableArray<id<RBEFireworkAccessoryProtocol>> *accessories;

@end

NS_ASSUME_NONNULL_END