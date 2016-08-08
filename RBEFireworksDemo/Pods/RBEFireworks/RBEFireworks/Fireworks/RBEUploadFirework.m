//
//  RBEUploadFirework.m
//  RBENetWork
//
//  Created by Robbie on 16/3/7.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEUploadFirework.h"
#import "RBEUploadFirework+Internal.h"
#import "RBEMarco.h"

@implementation RBEUploadFirework

- (instancetype)initWithUploadURL:(NSString *)uploadURL {
    return [self initWithUploadURL:uploadURL parameters:nil];
}

- (instancetype)initWithUploadURL:(NSString *)uploadURL parameters:(id)parameters {
    self = [super initWithRelativeURL:uploadURL parameters:parameters HTTPMethod:RBEHTTPMethodPost];
    if (self) {
        self.uploadURL = uploadURL;
    }
    return self;
}

- (void)clearRetainCycle {
    [super clearRetainCycle];
    self.mutipartFormDataConstructingBlock = nil;
    self.progressBlock = nil;
}

- (void)uploadWithFileURL:(NSURL *)fileURL name:(NSString *)name {
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    
    self.mutipartFormDataConstructingBlock = ^(id<AFMultipartFormData> mutipartFormData) {
        NSError *error;
        BOOL isSuccessed = [mutipartFormData appendPartWithFileURL:fileURL name:name error:&error];
        if (!isSuccessed) {
            RBELog(@"RBENetWork upload failed :%@", [error localizedFailureReason]);
        }
    };
}

- (void)uploadWithFileURL:(NSURL *)fileURL name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    
    self.mutipartFormDataConstructingBlock = ^(id<AFMultipartFormData> mutipartFormData) {
        NSError *error;
        BOOL isSuccessed = [mutipartFormData appendPartWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType error:&error];
        if (!isSuccessed) {
            RBELog(@"RBENetWork upload failed :%@", [error localizedFailureReason]);
        }
    };
}

- (void)uploadWithInputStream:(NSInputStream *)inputStream name:(NSString *)name fileName:(NSString *)fileName length:(int64_t)length mimeType:(NSString *)mimeType {
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    
    self.mutipartFormDataConstructingBlock = ^(id<AFMultipartFormData> mutipartFormData) {
        [mutipartFormData appendPartWithInputStream:inputStream name:name fileName:fileName length:length mimeType:mimeType];
    };
}

- (void)uploadWithFileData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    
    self.mutipartFormDataConstructingBlock = ^(id<AFMultipartFormData> mutipartFormData) {
        [mutipartFormData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
    };
}

- (void)uploadWithFormData:(NSData *)data name:(NSString *)name {
    NSParameterAssert(name);
    
    self.mutipartFormDataConstructingBlock = ^(id<AFMultipartFormData> mutipartFormData) {
        [mutipartFormData appendPartWithFormData:data name:name];
    };
}

- (void)uploadWithHeaders:(NSDictionary<NSString *,NSString *> *)headers body:(NSData *)body {
    NSParameterAssert(body);
    
    self.mutipartFormDataConstructingBlock = ^(id<AFMultipartFormData> mutipartFormData) {
        [mutipartFormData appendPartWithHeaders:headers body:body];
    };
}

@end
