//
//  RBEChainFirework.h
//  RBENetWork
//
//  Created by Robbie on 15/12/4.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RBEBatchFirework;
@class RBEFirework;

typedef void(^BatchFireworkSuccessBlock)(RBEBatchFirework *batchFirework);
typedef void(^BatchFireworkFailureBlock)(RBEBatchFirework *batchFirework,  NSArray<RBEFirework *> *failedFireworks);

@protocol RBEBatchFireworkDelegate <NSObject>

@optional

- (void)batchFireworkFinished:(RBEBatchFirework *)batchFirework;
- (void)batchFireworkFailed:(RBEBatchFirework *)batchFirework failedFireworks:(NSArray<RBEFirework *> *)failedFireworks;

@end

@protocol RBEBatchFireworkAccessoryProtocol <NSObject>

@optional

- (void)batchFireworkWillResume:(RBEBatchFirework *)batchFirework;
- (void)batchFireworkWillComplete:(RBEBatchFirework *)batchFirework;
- (void)batchFireworkDidComplete:(RBEBatchFirework *)batchFirework;
- (void)batchFireworkWillSuspend:(RBEBatchFirework *)batchFirework;
- (void)batchFireworkWillCancel:(RBEBatchFirework *)batchFirework;

@end

@interface RBEBatchFirework : NSObject

@property (nonnull, nonatomic, strong) NSArray *fireworkArr;

@property (nullable, nonatomic, weak) id<RBEBatchFireworkDelegate> delegate;

@property (nullable, nonatomic, copy) BatchFireworkSuccessBlock successBlock;
@property (nullable, nonatomic, copy) BatchFireworkFailureBlock failureBlock;

- (instancetype)initWithFireworkArray:(NSArray<RBEFirework *> *)fireworkArr shouldCancelAllFireworkIfOneFireworkFailed:(BOOL)shouldCancelAllFirework;

- (void)resume;

- (void)cancel;
//suspend task, you should call resume later, or call clearRatainCycle to avoid retain cycle
- (void)suspend;

- (void)resumeWithSuccessBlock:(nullable BatchFireworkSuccessBlock)successBlock
                failureBlock:(nullable BatchFireworkFailureBlock)failureBlock;

- (void)cleanRetainCycle;

- (void)addAccessory:(id<RBEBatchFireworkAccessoryProtocol>)accessory;

@end

NS_ASSUME_NONNULL_END
