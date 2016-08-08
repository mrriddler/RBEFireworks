//
//  RBEChainFirework.h
//  RBENetWork
//
//  Created by Robbie on 15/12/3.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RBEFirework.h"

NS_ASSUME_NONNULL_BEGIN

@class RBEChainFirework;

typedef void(^ChainFireworkSuccessBlock)(RBEChainFirework *chainFirework);
typedef void(^ChainFireworkFailureBlock)(RBEChainFirework *chainFirework, RBEFirework *failedFirework);

@protocol RBEChainFireworkDelegate <NSObject>

@optional

- (void)chainFireworkFinished:(RBEChainFirework *)chainFirework;
- (void)chainFireworkFailed:(RBEChainFirework *)chainFirework failedFirework:(RBEFirework *)firework;

@end

@protocol RBEChainFireworkAccessoryProtocol <NSObject>

@optional

- (void)chainFireworkWillResume:(RBEChainFirework *)chainFirework;
- (void)chainFireworkWillComplete:(RBEChainFirework *)chainFirework;
- (void)chainFireworkDidComplete:(RBEChainFirework *)chainFirework;
- (void)chainFireworkWillSuspend:(RBEChainFirework *)chainFirework;
- (void)chainFireworkWillCancel:(RBEChainFirework *)chainFirework;

@end



@interface RBEChainFirework : NSObject

@property (nonnull, nonatomic, strong) NSArray *fireworkArr;

@property (nullable, nonatomic, copy) ChainFireworkSuccessBlock successBlock;
@property (nullable, nonatomic, copy) ChainFireworkFailureBlock failureBlock;

@property (nullable, nonatomic, weak) id<RBEChainFireworkDelegate> delegate;

- (instancetype)initWithFireworkArray:(NSArray<RBEFirework *> *)fireworkArr;

- (void)resume;

- (void)cancel;
//suspend task, you should call resume later, or call clearRatainCycle to avoid retain cycle
- (void)suspend;

- (void)resumeWithSuccessBlock:(nullable ChainFireworkSuccessBlock)successBlock
                failureBlock:(nullable ChainFireworkFailureBlock)failureBlock;

- (void)cleanRetainCycle;

- (void)addAccessory:(id<RBEChainFireworkAccessoryProtocol>)accessory;

@end

NS_ASSUME_NONNULL_END
