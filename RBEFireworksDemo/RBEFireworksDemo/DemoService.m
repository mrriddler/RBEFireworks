//
//  DemoService.m
//  RBEFireworkPerformance
//
//  Created by Robbie on 16/8/2.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "DemoService.h"

@implementation DemoService

+ (RBEFirework *)demoGetFirework {
    RBEFirework *firework = [[RBEFirework alloc] initWithRelativeURL:@"demo"];
    return firework;
}

+ (RBEFirework *)demoPostFirework {
    RBEFirework *firework = [[RBEFirework alloc] initWithRelativeURL:@"demo" parameters:@{@"demo" : @"demo"} HTTPMethod:RBEHTTPMethodPost];
    return firework;
}

+ (RBEUploadFirework *)demoUploadFirework {
    RBEUploadFirework *upload = [[RBEUploadFirework alloc] initWithUploadURL:@"demo"];
    [upload uploadWithFileURL:[NSURL URLWithString:@"demoURL"] name:@"demo" fileName:@"demoFileName" mimeType:@"demoMimeType"];
    return upload;
}

+ (RBEDownloadFirework *)demoResumeDownloadFirework {
    RBEDownloadFirework *download = [[RBEDownloadFirework alloc] initWithDownloadURL:@"demo" destinationPath:@"demoDestinationPath"];
    //Employ NSURLSession downloadTaskWithResumeData API or self-Implementaion
    download.isProvideETagOrLastModified = YES;
    [download resumeWithSuccessBlock:^(RBEFirework * _Nonnull responseFirework) {
        NSString *path = [download downloadedContentPath];
        if (path) {
            //Get path to do...
        }
    } failureBlock:^(RBEFirework * _Nonnull responseFirework) {
        //failure to do...
    }];
    return download;
}

+ (RBEFirework *)demoFireworkOne {
    RBEFirework *firework = [[RBEFirework alloc] initWithRelativeURL:@"demoOne"];
    return firework;
}

+ (RBEFirework *)demoFireworkTwo {
    RBEFirework *firework = [[RBEFirework alloc] initWithRelativeURL:@"demoTwo"];
    return firework;
}

+ (RBEFirework *)demoFireworkThree {
    RBEFirework *firework = [[RBEFirework alloc] initWithRelativeURL:@"demoThree"];
    return firework;
}

@end

@implementation DemoFireworkAccessory

+ (instancetype)accessory {
    DemoFireworkAccessory *accessory = [[DemoFireworkAccessory alloc] init];
    accessory.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    return accessory;
}

- (void)fireworkWillResume:(RBEFirework *)firework {
    [self.indicator startAnimating];
}

- (void)fireworkWillComplete:(RBEFirework *)firework {
    [self.indicator stopAnimating];
}

@end
