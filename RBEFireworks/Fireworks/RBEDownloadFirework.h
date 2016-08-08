//
//  RBEDownloadFirework.h
//  RBENetWork
//
//  Created by Robbie on 16/3/7.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEFirework.h"

NS_ASSUME_NONNULL_BEGIN


@interface RBEDownloadFirework : RBEFirework

//is resumable download task header Provide ETag Or LastModified
@property (nonatomic, assign) BOOL isProvideETagOrLastModified;

@property (nullable, nonatomic, copy) RBEProgressBlock progressBlock;

- (instancetype)initWithRelativeURL:(NSString *)relativeURL NS_UNAVAILABLE;

- (instancetype)initWithRelativeURL:(NSString *)relativeURL HTTPMethod:(RBEHTTPMethod)HTTPMethod NS_UNAVAILABLE;

- (instancetype)initWithRelativeURL:(NSString *)relativeURL parameters:(nullable id)parameters HTTPMethod:(RBEHTTPMethod)HTTPMethod NS_UNAVAILABLE;

- (instancetype)initWithDownloadURL:(NSString *)downloadURL destinationPath:(NSString *)destinationPath;

- (instancetype)initWithDownloadURL:(NSString *)downloadURL parameters:(nullable id)parameters destinationPath:(NSString *)destinationPath;

//finally downloaded content path
- (nullable NSString *)downloadedContentPath;

@end

NS_ASSUME_NONNULL_END
