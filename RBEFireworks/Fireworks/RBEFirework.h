//
//  RBEFirework.h
//  RBENetWork
//
//  Created by Robbie on 15/11/18.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import "RBERequest.h"
#import "AFNetworking.h"

NS_ASSUME_NONNULL_BEGIN

@class RBEFirework;

typedef NS_ENUM(NSInteger, RBESessionConfigurationType) {
    RBESessionConfigurationTypeDefault = 1,
    RBESessionConfigurationTypeEphemeral,
    RBESessionConfigurationTypeBackground,
};

typedef void (^SuccessBlock)(RBEFirework *responseFirework);
typedef void (^FailureBlock)(RBEFirework *responseFirework);
typedef void (^AFConstructingBlock)(id<AFMultipartFormData> mutipartFormData);
typedef void (^RBEProgressBlock)(NSProgress *progress);

@protocol RBEFireworkDelegate <NSObject>

@optional

- (void)fireworkFinished:(RBEFirework *)firework;
- (void)fireworkFailed:(RBEFirework *)firework;

@end

@protocol RBEFireworkAccessoryProtocol <NSObject>

@optional

- (void)fireworkWillResume:(RBEFirework *)firework;
- (void)fireworkWillComplete:(RBEFirework *)firework;
- (void)fireworkDidComplete:(RBEFirework *)firework;
- (void)fireworkWillSuspend:(RBEFirework *)firework;
- (void)fireworkWillCancel:(RBEFirework *)firework;

@end


@interface RBEFirework : RBERequest

@property (nonatomic, readonly, assign) NSURLSessionTaskState state;

//default is RBESessionConfigurationTypeDefault, see more form apple document NSURLSessionConfiguration
@property (nonatomic, assign) RBESessionConfigurationType sessionConfigurationType;

@property (nonatomic, readonly, assign) NSInteger responseStatusCode;
@property (nullable, nonatomic, strong) NSDictionary *responseHTTPHeaders;
@property (nonatomic, strong) id responseObject;
@property (nullable, nonatomic, strong) NSError *responseError;

@property (nullable, nonatomic, weak) id<RBEFireworkDelegate> delegate;

@property (nullable, nonatomic, strong) id responseValidator;

- (void)resume;

- (void)cancel;
//suspend task, you should call resume later, or call clearRatainCycle to avoid retain cycle
- (void)suspend;

- (void)setSuccessBlock:(nullable SuccessBlock)successBlock failureBlock:(nullable FailureBlock)failureBlock;

- (void)resumeWithSuccessBlock:(nullable SuccessBlock)successBlock failureBlock:(nullable FailureBlock) failureBlock;

- (void)clearRetainCycle;

- (void)addAccessory:(id<RBEFireworkAccessoryProtocol>)accessory;

- (id)cachedObject;

- (BOOL)isEqualToFirework:(RBEFirework *)firework;

@end

@interface RBEFirework (ChainFireworkAddition)

- (void)breakChain;

@end

NS_ASSUME_NONNULL_END
