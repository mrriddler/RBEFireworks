//
//  RBEUploadFirework.h
//  RBENetWork
//
//  Created by Robbie on 16/3/7.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEFirework.h"

NS_ASSUME_NONNULL_BEGIN

@interface RBEUploadFirework : RBEFirework

@property (nullable, nonatomic, copy) RBEProgressBlock progressBlock;

- (instancetype)initWithRelativeURL:(NSString *)relativeURL HTTPMethod:(RBEHTTPMethod)httpMethod NS_UNAVAILABLE;

- (instancetype)initWithRelativeURL:(NSString *)relativeURL parameters:(nullable id)parameters HTTPMethod:(RBEHTTPMethod)HTTPMethod NS_UNAVAILABLE;

- (instancetype)initWithUploadURL:(NSString *)uploadURL;

- (instancetype)initWithUploadURL:(NSString *)uploadURL parameters:(nullable id)parameters;

- (void)uploadWithFileURL:(NSURL *)fileURL
                     name:(NSString *)name;

- (void)uploadWithFileURL:(NSURL *)fileURL
                     name:(NSString *)name
                 fileName:(NSString *)fileName
                 mimeType:(NSString *)mimeType;

- (void)uploadWithInputStream:(nullable NSInputStream *)inputStream
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                       length:(int64_t)length
                     mimeType:(NSString *)mimeType;

- (void)uploadWithFileData:(NSData *)data
                      name:(NSString *)name
                  fileName:(NSString *)fileName
                  mimeType:(NSString *)mimeType;

- (void)uploadWithFormData:(NSData *)data
                      name:(NSString *)name;

- (void)uploadWithHeaders:(nullable NSDictionary <NSString *, NSString *> *)headers
                     body:(NSData *)body;

@end

NS_ASSUME_NONNULL_END
