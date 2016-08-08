//
//  DemoService.h
//  RBEFireworkPerformance
//
//  Created by Robbie on 16/8/2.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DemoNetworkUtil.h"

@interface DemoService : NSObject

+ (RBEFirework *)demoGetFirework;

+ (RBEFirework *)demoPostFirework;

+ (RBEUploadFirework *)demoUploadFirework;

+ (RBEDownloadFirework *)demoResumeDownloadFirework;

+ (RBEFirework *)demoFireworkOne;

+ (RBEFirework *)demoFireworkTwo;

+ (RBEFirework *)demoFireworkThree;

@end

@interface DemoFireworkAccessory : NSObject <RBEFireworkAccessoryProtocol>

@property (nonatomic, strong) UIActivityIndicatorView *indicator;

+ (instancetype)accessory;

- (void)fireworkWillResume:(RBEFirework *)firework;

- (void)fireworkWillComplete:(RBEFirework *)firework;

@end
