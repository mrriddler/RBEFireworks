//
//  RBEHTTPSessionManager.h
//  RBENetWork
//
//  Created by Robbie on 15/12/23.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import "AFHTTPSessionManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface RBEHTTPSessionManager : AFHTTPSessionManager

+ (instancetype)manager;

- (instancetype)initWithBaseURL:(nullable NSURL *)url;

- (instancetype)initWithBaseURL:(nullable NSURL *)url
           sessionConfiguration:(nullable NSURLSessionConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

//According to NSURLSessionDownloadTask documentation, a download can be resumed only if it is an HTTP or
//HTTPS GET request, and only if the remote server supports byte-range requests (with the Range header) and
//provides the ETag or Last-Modified header in its responses

//This framework implement resume download task two different ways, first one base on NSURLSssionDownLoadTask
//downloadTaskWithResumeData method, in this way, you must fullfill documentation claim to make it work. In
//another way, you could not meet ETag or Last-Modified header in its responses need, but GET request, and
//only if the remote server supports byte-range requests is mandatory.

- (nullable NSURLSessionTask *)GET:(NSString *)URLString
                            parameters:(nullable id)parameters
                       destinationPath:(NSString *)destinationPath
          isProvidedETagOrLastModified:(BOOL)isProvidedETagOrLastModified
                              progress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress
                               success:(nullable void (^)(NSURLSessionTask * task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionTask * _Nullable task, NSError * error))failure;

- (NSString *)downloadedContentPathWithURLString:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
