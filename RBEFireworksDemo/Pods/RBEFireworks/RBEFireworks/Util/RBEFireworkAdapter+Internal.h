//
//  RBEFireworkAdapter+Internal.h
//  RBENetWork
//
//  Created by Robbie on 16/7/8.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEFireworkAdapter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RBEFireworkAdapterDelegate <NSObject>

@required

- (void)cancelAllRBEFireworkInConfigurationTpye:(RBESessionConfigurationType)configurationType  allowOutstandingTaskFinish:(BOOL)isAllow;

- (void)purgeInMemoryCache;

- (void)purgeAllCache;

@end

@interface RBEFireworkAdapter ()

@property (nonatomic, weak) id<RBEFireworkAdapterDelegate> delegate;

@end

NS_ASSUME_NONNULL_END