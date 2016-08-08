//
//  ViewController.m
//  RBEFireworksDemo
//
//  Created by Robbie on 16/8/7.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "ViewController.h"
#import "DemoService.h"

@interface ViewController () <RBEFireworkDelegate, RBEChainFireworkDelegate, RBEBatchFireworkDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)demoBasicFireworks {
    RBEFirework *getFirework = [DemoService demoGetFirework];
    [getFirework resume];
    
    RBEFirework *postFirework = [DemoService demoPostFirework];
    [postFirework resumeWithSuccessBlock:^(RBEFirework * _Nonnull responseFirework) {
        //succes to do...
    } failureBlock:^(RBEFirework * _Nonnull responseFirework) {
        //failure to do...
    }];
    
    RBEFirework *demoOne = [DemoService demoFireworkOne];
    RBEFirework *demoTwo = [DemoService demoFireworkTwo];
    RBEFirework *demoThree = [DemoService demoFireworkThree];
    
    RBEChainFirework *chain = [[RBEChainFirework alloc] initWithFireworkArray:@[demoOne, demoTwo, demoThree]];
    [chain resumeWithSuccessBlock:^(RBEChainFirework * _Nonnull chainFirework) {
        RBEFirework *successOne = [chainFirework.fireworkArr firstObject];
        NSDictionary *successDicOne = successOne.responseObject;
        if (successDicOne) {
            //first successed...
        }
        
        RBEFirework *successTwo = chainFirework.fireworkArr[1];
        NSDictionary *successDicTwo = successTwo.responseObject;
        if (successDicTwo) {
            //second successed...
        }
        
        RBEFirework *successThree = [chainFirework.fireworkArr lastObject];
        NSDictionary *successDicThree = successThree.responseObject;
        if (successDicThree) {
            //third successed...
        }
        
    } failureBlock:^(RBEChainFirework * _Nonnull chainFirework, RBEFirework * _Nonnull failedFirework) {
        if ([failedFirework isEqualToFirework:[chainFirework.fireworkArr firstObject]]) {
            //first failed...
        } else if ([failedFirework isEqualToFirework:chainFirework.fireworkArr[1]]) {
            //second failed...
        } else {
            //third failed...
        }
    }];
    
    [demoOne setSuccessBlock:^(RBEFirework * _Nonnull responseFirework) {
        //first successed...
    } failureBlock:^(RBEFirework * _Nonnull responseFirework) {
        //first failed...
    }];
    
    [demoTwo setSuccessBlock:^(RBEFirework * _Nonnull responseFirework) {
        //second successed...
    } failureBlock:^(RBEFirework * _Nonnull responseFirework) {
        //second failed...
    }];
    
    [demoThree setSuccessBlock:^(RBEFirework * _Nonnull responseFirework) {
        //third successed...
    } failureBlock:^(RBEFirework * _Nonnull responseFirework) {
        //third failed...
    }];
    
    RBEBatchFirework *batch = [[RBEBatchFirework alloc] initWithFireworkArray:@[demoOne, demoTwo, demoThree] shouldCancelAllFireworkIfOneFireworkFailed:NO];
    [batch resume];
}

- (void)demoAdvancedFireworks {
    RBEFirework *demoOne = [DemoService demoFireworkOne];
    demoOne.cachePattern = RBECachePatternFreshness;
    demoOne.cacheFreshnessInSecond = 7 * 24 * 60 * 60;
    
    id cachedObject = demoOne.cachedObject;
    if (cachedObject) {
        //cache to do...
    }
    
    //validte response object type
    demoOne.responseValidator = @[@{@"demoId" : [NSString class],
                                    @"demoTime" : [NSNumber class],
                                    @"demoStuff" : @{
                                            @"demoStuffId" : [NSString class],
                                            @"demoStuffContent" : [NSString class]
                                            }}];
    
    //cutom request independent from global process
    demoOne.customRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"demo"]];
    
    DemoFireworkAccessory *accessory = [DemoFireworkAccessory accessory];
    [demoOne addAccessory:accessory];
    
    demoOne.sessionConfigurationType = RBESessionConfigurationTypeDefault;
    
    //other firework configuration, see more from NSURLRequest
    demoOne.HTTPShouldUsePipelining = YES;
    demoOne.timeoutInterval = 60;
    demoOne.HTTPShouldHandleCookies = YES;
    demoOne.allowsCellularAccess = YES;
    demoOne.networkServiceType = NSURLNetworkServiceTypeDefault;
    
    //suspend and cancel
    /**
     *  if your suspend RBEChainFirework or RBEBatchFirework
     *  you must call cancel or resume or cleanRetainCycle later
     *  otherwise there will be retain cycle
     */
    [demoOne resume];
    [demoOne suspend];
    [demoOne cancel];
    
    //if particular condition occur, you could stop chain firework
    //demoThree will not excute
    RBEFirework *demoTwo = [DemoService demoFireworkTwo];
    [demoTwo setSuccessBlock:^(RBEFirework * _Nonnull responseFirework) {
        NSDictionary *respondeDic = responseFirework.responseObject;
        if (respondeDic[@"demo"]) {
            [responseFirework breakChain];
        }
    } failureBlock:^(RBEFirework * _Nonnull responseFirework) {
        //failure to do
    }];
    
    RBEFirework *demoThree = [DemoService demoFireworkThree];
    
    RBEChainFirework *chain = [[RBEChainFirework alloc] initWithFireworkArray:@[demoTwo, demoThree]];
    [chain resume];
    
    RBEDownloadFirework *download = [DemoService demoResumeDownloadFirework];
    download.progressBlock = ^(NSProgress *progress) {
        //progress to do...
    };
    
    RBEUploadFirework *upload = [DemoService demoUploadFirework];
    upload.progressBlock = ^(NSProgress *progress) {
        //progress to do...
    };
    
    //print request base infomation
    NSLog(@"%@", demoOne);
}

#pragma mark RBEFirework Deleagte

//Firework success
- (void)fireworkFinished:(RBEFirework *)firework {}
//Firework fail
- (void)fireworkFailed:(RBEFirework *)firework {}
//Chain Firework success
- (void)chainFireworkFinished:(RBEChainFirework *)chainFirework {}
//Chain Firework fail
- (void)chainFireworkFailed:(RBEChainFirework *)chainFirework failedFirework:(RBEFirework *)firework {}
//Batch Firework success
- (void)batchFireworkFinished:(RBEBatchFirework *)batchFirework {}
//Batch Firework fail
- (void)batchFireworkFailed:(RBEBatchFirework *)batchFirework failedFireworks:(NSArray<RBEFirework *> *)failedFireworks {}

@end
