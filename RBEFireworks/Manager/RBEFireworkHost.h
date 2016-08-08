//
//  RBEFireworkHost.h
//  RBENetWork
//
//  Created by Robbie on 15/11/24.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RBEFirework;
@class RBEHTTPSessionManager;

@interface RBEFireworkHost : NSObject

+ (RBEFireworkHost *)sharedInstance;

- (void)resumeFirework:(RBEFirework *)firework;

- (void)cancelFirework:(RBEFirework *)firework;

- (NSString *)downloadedContentPathWithFirework:(RBEFirework *)firework;

@end

@interface RBEFireworkHost (RBECache)

- (void)setCacheResponeForFirework:(RBEFirework *)firework withManager:(RBEHTTPSessionManager *)manager;

- (nullable RBEFirework *)retrieveCachedFireworkWithFirework:(RBEFirework *)firework;

- (void)cacheFirework:(RBEFirework *)firework;

@end

NS_ASSUME_NONNULL_END