//
//  RBEChainFirework+Internal.h
//  RBENetWork
//
//  Created by Robbie on 16/7/8.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEChainFirework.h"

NS_ASSUME_NONNULL_BEGIN

@interface RBEChainFirework () <RBEFireworkInternalDelegate>

@property (nonatomic, strong) NSMutableArray *internalFireworkArr;
@property (nonatomic, assign) NSInteger nextFireworkIndex;
@property (nullable, nonatomic, strong) NSMutableArray<id<RBEChainFireworkAccessoryProtocol>> *accessories;

- (void)cancelAfterwardFirework;

@end

NS_ASSUME_NONNULL_END