//
//  RBEBatchFirework+Internal.h
//  RBEFireworkPerformance
//
//  Created by Robbie on 16/8/3.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEBatchFirework.h"

NS_ASSUME_NONNULL_BEGIN

@interface RBEBatchFirework () <RBEFireworkInternalDelegate>

//should cancel all firework if one firework failed
@property (nonatomic, assign) BOOL shouldCancelAllFirework;
@property (nullable, nonatomic, strong) NSMutableArray *failedFireworks;
@property (nonatomic, assign) NSInteger excutedCount;
@property (nonatomic, assign) NSInteger finishedCount;
@property (nonatomic, strong) NSMutableArray *internalFireworkArr;
@property (nullable, nonatomic, strong) NSMutableArray<id<RBEBatchFireworkAccessoryProtocol>> *accessories;

@end

NS_ASSUME_NONNULL_END