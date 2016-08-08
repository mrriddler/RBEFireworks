//
//  RBEChainFirework.m
//  RBENetWork
//
//  Created by Robbie on 15/12/3.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import "RBEChainFirework.h"
#import "RBEFirework.h"
#import "RBEFirework+Internal.h"
#import "RBEChainFirework+Internal.h"

@implementation RBEChainFirework

- (instancetype)initWithFireworkArray:(NSArray *)fireworkArr {
    self = [super init];
    if (self) {
        self.internalFireworkArr = [NSMutableArray arrayWithArray:fireworkArr];
        self.nextFireworkIndex = 0;
        
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

- (void)resume {
    NSAssert(self.nextFireworkIndex == 0, @"RBEChainFirework already has a firework on processing, could not fire again");
    NSAssert(self.internalFireworkArr.count > 0, @"RBEChainFirework could not start, cuz you have not add any firework in chainFirework");
    
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEChainFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(chainFireworkWillResume:)]) {
            [obj chainFireworkWillResume:self];
        }
    }];
    
    [self fireNextFirework];
}

- (void)cancel {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEChainFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(chainFireworkWillCancel:)]) {
            [obj chainFireworkWillCancel:self];
        }
    }];
    
    [self cancelAllFirework];
}

- (void)suspend {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEChainFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(chainFireworkWillSuspend:)]) {
            [obj chainFireworkWillSuspend:self];
        }
    }];
    
    NSUInteger currentFireworkIndex = self.nextFireworkIndex - 1;
    if (currentFireworkIndex < [self.internalFireworkArr count]) {
        RBEFirework *firework = self.internalFireworkArr[currentFireworkIndex];
        [firework suspend];
    }
}

- (BOOL)fireNextFirework {
    if (self.nextFireworkIndex < self.internalFireworkArr.count) {
        RBEFirework *firework = self.internalFireworkArr[self.nextFireworkIndex];
        firework.internalDelegate = self;
        
        self.nextFireworkIndex++;
        [firework resume];
        return YES;
    } else {
        return NO;
    }
}

- (void)cancelAfterwardFirework {
    [self.internalFireworkArr removeAllObjects];
    
    [self cleanRetainCycle];
}

- (void)cancelAllFirework {
    NSUInteger currentFireworkIndex = self.nextFireworkIndex - 1;
    if (currentFireworkIndex < [self.internalFireworkArr count]) {
        RBEFirework *firework = self.internalFireworkArr[currentFireworkIndex];
        [firework cancel];
    }
    
    [self.internalFireworkArr removeAllObjects];
}

- (void)resumeWithSuccessBlock:(ChainFireworkSuccessBlock)successBlock failureBlock:(ChainFireworkFailureBlock)failureBlock {
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    [self resume];
}

- (void)cleanRetainCycle {
    self.successBlock = nil;
    self.failureBlock = nil;
}

- (void)addAccessory:(id<RBEChainFireworkAccessoryProtocol>)accessory {
    [self.accessories addObject:accessory];
}

#pragma mark - RBEFireworkSetDelegate

- (void)fireworkFinished:(RBEFirework *)firework {
    if (![self fireNextFirework]) {
        [self chainWillComplete];
        
        if (self.successBlock) {
            self.successBlock(self);
        }
        
        if ([self.delegate respondsToSelector:@selector(chainFireworkFinished:)]) {
            [self.delegate chainFireworkFinished:self];
        }
        
        [self chainDidComplete];
        
        [self cleanRetainCycle];
    }
}

- (void)fireworkFailed:(RBEFirework *)firework {
    [self chainWillComplete];
    
    if (self.failureBlock) {
        self.failureBlock(self, firework);
    }
    
    if ([self.delegate respondsToSelector:@selector(chainFireworkFailed:failedFirework:)]) {
        [self.delegate chainFireworkFailed:self failedFirework:firework];
    }
    
    [self chainDidComplete];
    
    [self cleanRetainCycle];
}

- (void)chainWillComplete {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEChainFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(chainFireworkWillComplete:)]) {
            [obj chainFireworkWillComplete:self];
        }
    }];
}

- (void)chainDidComplete {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEChainFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(chainFireworkDidComplete:)]) {
            [obj chainFireworkDidComplete:self];
        }
    }];
}

- (NSArray *)fireworkArr {
    return [self.internalFireworkArr copy];
}

- (NSMutableArray<id<RBEChainFireworkAccessoryProtocol>> *)accessories {
    if (!_accessories) {
        _accessories = [[NSMutableArray alloc] init];
    }
    return _accessories;
}

@end
