//
//  RBEDownloadFirework.m
//  RBENetWork
//
//  Created by Robbie on 16/3/7.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEDownloadFirework.h"
#import "RBEDownloadFirework+Internal.h"
#import "RBEFirework+Internal.h"
#import "RBEFireworkHost.h"

@implementation RBEDownloadFirework

- (instancetype)initWithDownloadURL:(NSString *)downloadURL destinationPath:(NSString *)destinationPath {
    return [self initWithDownloadURL:downloadURL parameters:nil destinationPath:destinationPath];
}

- (instancetype)initWithDownloadURL:(NSString *)downloadURL parameters:(id)parameters destinationPath:(NSString *)destinationPath {
    self = [super initWithRelativeURL:downloadURL parameters:parameters HTTPMethod:RBEHTTPMethodGet];
    if (self) {
        self.downloadURL = downloadURL;
        self.isProvideETagOrLastModified = YES;
        self.destinationPath = destinationPath;
    }
    return self;
}

- (void)resume {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(fireworkWillResume:)]) {
            [obj fireworkWillResume:self];
        }
    }];
    
    if (self.state == NSURLSessionTaskStateSuspended) {
        
        if (self.isProvideETagOrLastModified) {
            [self.downLoadTask resume];
        } else {
            [self.dataTask resume];
        }
        
        return;
    }
    
    [[RBEFireworkHost sharedInstance] resumeFirework:self];
}

- (void)suspend {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(fireworkWillSuspend:)]) {
            [obj fireworkWillSuspend:self];
        }
    }];

    if (self.isProvideETagOrLastModified) {
        [self.downLoadTask suspend];
    } else {
        [self.dataTask suspend];
    }
}

- (NSString *)downloadedContentPath {
    NSString *downloadContentPath = [[RBEFireworkHost sharedInstance] downloadedContentPathWithFirework:self];
    return downloadContentPath;
}

- (void)clearRetainCycle {
    [super clearRetainCycle];
    self.progressBlock = nil;
}

#pragma mark - Getter And Setter

- (NSURLSessionTaskState)state {
    if (self.isProvideETagOrLastModified) {
        return self.downLoadTask.state;
    } else {
        return self.dataTask.state;
    }
}

- (NSInteger)responseStatusCode {
    if (self.isProvideETagOrLastModified) {
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)self.downLoadTask.response;
        return HTTPResponse.statusCode;
    } else {
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)self.dataTask.response;
        return HTTPResponse.statusCode;
    }
}

- (NSDictionary *)responseHttpHeaders {
    if (self.isProvideETagOrLastModified) {
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)self.downLoadTask.response;
        return [HTTPResponse.allHeaderFields copy];
    } else {
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)self.dataTask.response;
        return [HTTPResponse.allHeaderFields copy];
    }
}

@end
