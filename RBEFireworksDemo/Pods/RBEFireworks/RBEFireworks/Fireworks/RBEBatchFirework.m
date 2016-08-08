//
//  RBEChainFirework.m
//  RBENetWork
//
//  Created by Robbie on 15/12/4.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import "RBEBatchFirework.h"
#import "RBEFirework.h"
#import "RBEFirework+Internal.h"
#import "RBEBatchFirework+Internal.h"

@implementation RBEBatchFirework

- (instancetype)initWithFireworkArray:(NSArray *)fireworkArr shouldCancelAllFireworkIfOneFireworkFailed:(BOOL)shouldCancelAllFirework {
    self = [super init];
    if (self) {
        self.internalFireworkArr = [NSMutableArray arrayWithArray:fireworkArr];
        self.finishedCount = 0;
        self.excutedCount = 0;
        self.shouldCancelAllFirework = shouldCancelAllFirework;
        self.failedFireworks = [[NSMutableArray alloc] init];
        
        __block BOOL isParametersLegal = YES;
        [self.internalFireworkArr enumerateObjectsUsingBlock:^(RBEFirework *firework, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![firework isKindOfClass:[RBEFirework class]]) {
                isParametersLegal = NO;
                *stop = YES;
            }
        }];
        
        NSAssert(isParametersLegal, @"RBEBatchFirework can only fire RBEFirework");
    }
    return self;
}

- (void)dealloc {
    [self cancel];
}

- (void)resume {
    NSAssert(!self.finishedCount, @"RBEBatchFirework already have firework on processing, could not fire again");
    
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEBatchFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(batchFireworkWillResume:)]) {
            [obj batchFireworkWillResume:self];
        }
    }];
    
    [self.internalFireworkArr enumerateObjectsUsingBlock:^(RBEFirework *firework, NSUInteger idx, BOOL * _Nonnull stop) {
        firework.internalDelegate = self;
        [firework resume];
    }];
}

- (void)cancel {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEBatchFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(batchFireworkWillCancel:)]) {
            [obj batchFireworkWillCancel:self];
        }
    }];
    
    [self.internalFireworkArr enumerateObjectsUsingBlock:^(RBEFirework *firework, NSUInteger idx, BOOL * _Nonnull stop) {
        [firework cancel];
    }];
    
    [self cleanRetainCycle];
}

- (void)suspend {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEBatchFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(batchFireworkWillSuspend:)]) {
            [obj batchFireworkWillSuspend:self];
        }
    }];
    
    [self.internalFireworkArr enumerateObjectsUsingBlock:^(RBEFirework *firework, NSUInteger idx, BOOL * _Nonnull stop) {
        [firework suspend];
    }];
}

- (void)resumeWithSuccessBlock:(BatchFireworkSuccessBlock)successBlock failureBlock:(BatchFireworkFailureBlock)failureBlock {
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    [self resume];
}

- (void)cleanRetainCycle {
    self.successBlock = nil;
    self.failureBlock = nil;
}

- (void)addAccessory:(id<RBEBatchFireworkAccessoryProtocol>)accessory {
    [self.accessories addObject:accessory];
}

#pragma mark - RBEFireworkSetDelegate

- (void)fireworkFinished:(RBEFirework *)firework {
    self.excutedCount++;
    self.finishedCount++;
    
    if (self.finishedCount == self.internalFireworkArr.count) {
        [self batchWillComplete];
        
        if ([self.delegate respondsToSelector:@selector(batchFireworkFinished:)]) {
            [self.delegate batchFireworkFinished:self];
        }
        
        if (self.successBlock) {
            self.successBlock(self);
        }
        
        [self batchDidComplete];
        
        [self cleanRetainCycle];
    }
}

- (void)fireworkFailed:(RBEFirework *)firework {
    self.excutedCount++;
    [self.failedFireworks addObject:firework];
    
    if (self.shouldCancelAllFirework) {
        [self batchWillComplete];

        if ([self.delegate respondsToSelector:@selector(batchFireworkFailed:failedFireworks:)]) {
            [self.delegate batchFireworkFailed:self failedFireworks:[self.failedFireworks copy]];
        }
        
        [self.internalFireworkArr enumerateObjectsUsingBlock:^(RBEFirework *firework, NSUInteger idx, BOOL * _Nonnull stop) {
            [firework cancel];
        }];
        
        if (self.failureBlock) {
            self.failureBlock(self, [self.failedFireworks copy]);
        }
        
        [self batchDidComplete];
        
        [self cleanRetainCycle];
    }
    
    if (self.excutedCount == self.internalFireworkArr.count) {
        [self batchWillComplete];
        
        if ([self.delegate respondsToSelector:@selector(batchFireworkFailed:failedFireworks:)]) {
            [self.delegate batchFireworkFailed:self failedFireworks:[self.failedFireworks copy]];
        }
        
        if (self.failureBlock) {
            self.failureBlock(self, [self.failedFireworks copy]);
        }
        
        [self batchDidComplete];
        
        [self cleanRetainCycle];
    }
}

- (void)batchWillComplete {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEBatchFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(batchFireworkWillComplete:)]) {
            [obj batchFireworkWillComplete:self];
        }
    }];
}

- (void)batchDidComplete {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEBatchFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(batchFireworkDidComplete:)]) {
            [obj batchFireworkDidComplete:self];
        }
    }];
}

- (NSArray *)fireworkArr {
    return [self.internalFireworkArr copy];
}

- (NSMutableArray<id<RBEBatchFireworkAccessoryProtocol>> *)accessories {
    if (!_accessories) {
        _accessories = [[NSMutableArray alloc] init];
    }
    return _accessories;
}

@end
