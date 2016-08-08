//
//  RBEHTTPSessionManager.m
//  RBENetWork
//
//  Created by Robbie on 15/12/23.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import "RBEHTTPSessionManager.h"
#import "NSString+RBEAdditions.h"
#import "RBEMarco.h"
#import "NSString+RBEAdditions.h"

@interface RBEResumeDownloadTask : NSObject

@property (nonatomic, assign) NSUInteger taskIdentifier;
@property (nonatomic, strong) NSString *destinationPath;
@property (nonatomic, strong) NSString *cachePath;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) BOOL isProvidedETagOrLastModified;
@property (nonatomic, assign) NSUInteger totalBytesWritten;
@property (nonatomic, assign) NSUInteger totalBytesExpectedToWrite;

@end

@implementation RBEResumeDownloadTask

- (instancetype)initWithTaskIdentifier:(NSUInteger)taskIdentifier {
    self = [super init];
    if (self) {
        self.taskIdentifier = taskIdentifier;
    }
    return self;
}

-(void)dealloc {
    [self.outputStream close];
    self.outputStream = nil;
}

- (dispatch_queue_t)queue {
    if (!_queue) {
        NSString *queueLabel = [NSString stringWithFormat:@"come.rbe.http.session.manager.resume.delegate %lu", (unsigned long)self.taskIdentifier];
        _queue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    return _queue;
}

@end

static NSString *const kRBEIncompleteDownLoadPath = @"kRBEIncompleteDownLoadPath";

@interface RBEHTTPSessionManager ()

@property (strong, nonatomic) NSMutableDictionary *rbeResumeDownloadTaskDic;
@property (strong, nonatomic) NSMutableDictionary *downloadedContentPath;

@end

@implementation RBEHTTPSessionManager {
    dispatch_semaphore_t _semaphore;
}

+ (instancetype)manager {
    return [[[self class] alloc] initWithBaseURL:nil];
}

- (instancetype)init {
    return [self initWithBaseURL:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    return [self initWithBaseURL:url sessionConfiguration:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    return [self initWithBaseURL:nil sessionConfiguration:configuration];
}

- (instancetype)initWithBaseURL:(NSURL *)url sessionConfiguration:(NSURLSessionConfiguration *)configuration {
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (self) {
        self.rbeResumeDownloadTaskDic = [[NSMutableDictionary alloc] init];
        self.downloadedContentPath = [[NSMutableDictionary alloc] init];
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (NSURLSessionTask *)GET:(NSString *)URLString
                       parameters:(id)parameters
                  destinationPath:(NSString *)destinationPath
     isProvidedETagOrLastModified:(BOOL)isProvidedETagOrLastModified
                         progress:(void (^)(NSProgress * _Nonnull))downloadProgress
                          success:(void (^)(NSURLSessionTask * _Nonnull, id _Nullable))success
                          failure:(void (^)(NSURLSessionTask * _Nullable, NSError * _Nonnull))failure
{
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&serializationError];
    if (serializationError) {
        if (failure) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        
        return nil;
    }
    
    
    NSString *downloadTaskCachePath = [[self cacheDirectory] stringByAppendingPathComponent:[NSString rbe_md5StringFromString:request.URL.absoluteString]];
    
    if (isProvidedETagOrLastModified) {
        
        __block NSURLSessionDownloadTask *downloadTask = nil;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTaskCachePath]) {
            
            //Two operations: download to location, move file from location to destination path, either one of them fail will resume data
            NSData *resumeData = [NSData dataWithContentsOfFile:downloadTaskCachePath];
            downloadTask = [self downloadTaskWithResumeData:resumeData progress:downloadProgress destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                NSURL *destinationURL = [NSURL URLWithString:destinationPath];
                return destinationURL;
            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                if (error) {
                    failure(downloadTask, error);
                } else {
                    success(downloadTask, filePath);
                }
            }];
        } else {
            downloadTask = [self downloadTaskWithRequest:request progress:downloadProgress destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                NSURL *destinationURL = [NSURL URLWithString:destinationPath];
                return destinationURL;
            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                if (error) {
                    failure(downloadTask, error);
                } else {
                    success(downloadTask, filePath);
                }
            }];
        }
        
        RBEResumeDownloadTask *resumeDownloadTask = [[RBEResumeDownloadTask alloc] initWithTaskIdentifier:downloadTask.taskIdentifier];
        resumeDownloadTask.destinationPath = destinationPath;
        resumeDownloadTask.cachePath = downloadTaskCachePath;
        resumeDownloadTask.isProvidedETagOrLastModified = isProvidedETagOrLastModified;
        
        [self semaphoreLock];
        self.rbeResumeDownloadTaskDic[@(downloadTask.taskIdentifier)] = resumeDownloadTask;
        [self semaphoreUnlock];
        
        [downloadTask resume];
        return downloadTask;
    } else {
        //Two operations: download to location, move file from location to destination path, either one of them fail will resume data
        BOOL shouldResume = [self shouldResumeAtPath:downloadTaskCachePath withRequest:request];
        NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:downloadTaskCachePath append:shouldResume];
        [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [outputStream open];
        
        NSURLSessionDataTask *dataTask = [self GET:URLString parameters:parameters progress:downloadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            success(dataTask, destinationPath);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            failure(dataTask, error);
        }];
        
        RBEResumeDownloadTask *resumeDownloadTask = [[RBEResumeDownloadTask alloc] initWithTaskIdentifier:dataTask.taskIdentifier];
        resumeDownloadTask.destinationPath = destinationPath;
        resumeDownloadTask.cachePath = downloadTaskCachePath;
        resumeDownloadTask.isProvidedETagOrLastModified = isProvidedETagOrLastModified;
        resumeDownloadTask.outputStream = outputStream;
        
        [self semaphoreLock];
        self.rbeResumeDownloadTaskDic[@(dataTask.taskIdentifier)] = resumeDownloadTask;
        [self semaphoreUnlock];
        
        [self dataTaskDidRecieveResponse];
        
        [dataTask resume];
        return dataTask;
    }
        
    return nil;
}

- (void)dataTaskDidRecieveResponse {
    __weak typeof(self) weakSelf = self;
    [self setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf semaphoreLock];
        RBEResumeDownloadTask *resumeDownloadTask = strongSelf.rbeResumeDownloadTaskDic[@(dataTask.taskIdentifier)];
        [strongSelf semaphoreUnlock];
        
        if (resumeDownloadTask && !resumeDownloadTask.isProvidedETagOrLastModified) {
            dispatch_async(resumeDownloadTask.queue, ^{
                
                NSHTTPURLResponse *HTTPURLResponse = (NSHTTPURLResponse *)response;
                
                NSString *contentLength = HTTPURLResponse.allHeaderFields[@"Content-Length"];
                if (contentLength) {
                    resumeDownloadTask.totalBytesExpectedToWrite = [contentLength integerValue];
                } else {
                    [dataTask cancel];
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey: NSLocalizedString(@"HTTP Header did not contain Content-Length.", nil),
                                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Resume DownLoadTask must provide Content-Length in HTTP Header.", nil),
                                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please provide Content_length in HTTP Header", nil)
                                               };
                    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:kCFErrorHTTPParseFailure userInfo:userInfo];
                    [super URLSession:session task:dataTask didCompleteWithError:error];
                }
               
                /* HTTP Content-Range from http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
                 The first 500 bytes:
                 bytes 0-499/1234
                 The second 500 bytes:
                 bytes 500-999/1234
                 All except for the first 500 bytes:
                 bytes 500-1233/1234
                 The last 500 bytes:
                 bytes 734-1233/1234
                 */
                long long fileOffset = 0;
                if (HTTPURLResponse.statusCode == 206) {
                    NSString *contentRange = [HTTPURLResponse.allHeaderFields valueForKey:@"Content-Range"];
                    if ([contentRange hasPrefix:@"bytes"]) {
                        NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
                        if ([bytes count] == 4) {
                            fileOffset = [bytes[1] longLongValue];
                        }
                    }
                }
                
                fileOffset = MAX(fileOffset, 0);
                
                //There only 3 possibility, start new downloadTask, resume downloadTask, downloadTask has been fully downloaded
                //resume downloadTask or downloadTask has been fully downloaded would truncate file offset
                //if this is not a range HTTP response, then there is no resume
                if ([strongSelf fileSizeForPath:resumeDownloadTask.cachePath] != fileOffset) {
                    [resumeDownloadTask.outputStream close];
                    BOOL shouldResume = YES;
                    if (fileOffset > 0) {
                        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:resumeDownloadTask.cachePath];
                        [fileHandle truncateFileAtOffset:fileOffset];
                        [fileHandle closeFile];
                    } else {
                        shouldResume = NO;
                        RBELog(@"this is not a range HTTP response, resume downloadTask will just download it again, there is no resume");
                        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:resumeDownloadTask.cachePath];
                        [fileHandle closeFile];
                    }
                    
                    resumeDownloadTask.outputStream = [NSOutputStream outputStreamToFileAtPath:resumeDownloadTask.cachePath append:shouldResume];
                    [resumeDownloadTask.outputStream open];
                }
           });
            return NSURLSessionResponseAllow;
        } else {
            return NSURLSessionResponseAllow;
        }
    }];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self semaphoreLock];
    RBEResumeDownloadTask *resumeDownloadTask = self.rbeResumeDownloadTaskDic[@(dataTask.taskIdentifier)];
    [self semaphoreUnlock];
    
    if (!resumeDownloadTask || resumeDownloadTask.isProvidedETagOrLastModified) {
        [super URLSession:session dataTask:dataTask didReceiveData:data];
        return;
    }
    
    dispatch_async(resumeDownloadTask.queue, ^{
        NSOutputStream *outputStream = resumeDownloadTask.outputStream;
        const uint8_t *dataBuffer = [data bytes];
        NSInteger totalNumberOfBytesNeedToBeWritten = [data length];
        NSInteger totalNumberOfBytesWritten = 0;
        NSInteger numberOfBytesWritten = 0;
        
        while (YES) {
            if ([outputStream hasSpaceAvailable]) {
                numberOfBytesWritten = [outputStream write:&dataBuffer[totalNumberOfBytesWritten] maxLength:totalNumberOfBytesNeedToBeWritten - totalNumberOfBytesWritten];
                if (numberOfBytesWritten == -1) {
                    break;
                }
                
                totalNumberOfBytesWritten += numberOfBytesWritten;
                
                if (totalNumberOfBytesWritten >= totalNumberOfBytesNeedToBeWritten) {
                    resumeDownloadTask.totalBytesWritten += totalNumberOfBytesWritten;
                    break;
                }
            }
        }
        
        if (outputStream.streamError) {
            [dataTask cancel];
            [self URLSession:session task:dataTask didCompleteWithError:outputStream.streamError];
            return;
        }
        
        if (resumeDownloadTask.totalBytesExpectedToWrite <= resumeDownloadTask.totalBytesWritten) {
            
            BOOL shouldMove = YES;
            NSError *error = nil;
            if ([[NSFileManager defaultManager] fileExistsAtPath:resumeDownloadTask.destinationPath]) {
                if (![[NSFileManager defaultManager] removeItemAtPath:resumeDownloadTask.destinationPath error:&error]) {
                    RBELog(@"RBENetWork remove path failed:%@", [error localizedFailureReason]);
                    shouldMove = NO;
                }
            }
            
            if (shouldMove && [[NSFileManager defaultManager] moveItemAtPath:resumeDownloadTask.cachePath toPath:resumeDownloadTask.destinationPath error:&error]) {
                //Two operations both successed
                [self semaphoreLock];
                self.downloadedContentPath[dataTask.originalRequest.URL.absoluteString] = resumeDownloadTask.destinationPath;
                [self semaphoreUnlock];
                if ([[NSFileManager defaultManager] fileExistsAtPath:resumeDownloadTask.cachePath]) {
                    if (![[NSFileManager defaultManager] removeItemAtPath:resumeDownloadTask.cachePath error:&error]) {
                        RBELog(@"RBENetWork remove path failed:%@", [error localizedFailureReason]);
                    }
                }
            } else {
                //do nothing download Content is already in cachePath
                RBELog(@"RBENetWork move file to url failed:%@", [error localizedFailureReason]);
                [self semaphoreLock];
                self.downloadedContentPath[dataTask.originalRequest.URL.absoluteString] = resumeDownloadTask.cachePath;
                [self semaphoreUnlock];
            }
        }
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    
    [self semaphoreLock];
    RBEResumeDownloadTask *resumeDownloadTask = self.rbeResumeDownloadTaskDic[@(downloadTask.taskIdentifier)];
    [self semaphoreUnlock];
    
    if (!resumeDownloadTask) {
        [super URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    } else {
        
        //Apple resume download will not return location
        if (!location) {
            return;
        }
        
        //async will lead delegate execute before block and system will delete location file
        dispatch_sync(resumeDownloadTask.queue, ^{
            
            //move file from location to destination path
            BOOL shouldMove = YES;
            NSError *error = nil;
            if ([[NSFileManager defaultManager] fileExistsAtPath:resumeDownloadTask.destinationPath]) {
                if (![[NSFileManager defaultManager] removeItemAtPath:resumeDownloadTask.destinationPath error:&error]) {
                    RBELog(@"RBENetWork remove path failed:%@", [error localizedFailureReason]);
                    shouldMove = NO;
                }
            }
            
            NSError *moveToError = nil;
            NSString *locationStr = [location.absoluteString substringFromIndex:7];
            if (shouldMove && [[NSFileManager defaultManager] moveItemAtPath:locationStr toPath:resumeDownloadTask.destinationPath error:&moveToError]) {
                //move file from location to destination path successed
                [self semaphoreLock];
                self.downloadedContentPath[downloadTask.originalRequest.URL.absoluteString] = resumeDownloadTask.destinationPath;
                [self semaphoreUnlock];
                if ([[NSFileManager defaultManager] fileExistsAtPath:resumeDownloadTask.cachePath]) {
                    if (![[NSFileManager defaultManager] removeItemAtPath:resumeDownloadTask.cachePath error:&error]) {
                        RBELog(@"RBENetWork remove path failed:%@", [error localizedFailureReason]);
                    }
                }
            } else {
                if (moveToError) {
                    RBELog(@"RBENetWork move file to url failed:%@", [moveToError localizedFailureReason]);
                    [[NSNotificationCenter defaultCenter] postNotificationName:AFURLSessionDownloadTaskDidFailToMoveFileNotification object:downloadTask userInfo:moveToError.userInfo];
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:AFURLSessionDownloadTaskDidFailToMoveFileNotification object:downloadTask userInfo:error.userInfo];
                }
                
                //move file from location to destination path failed and try to move file from location to cachePath
                BOOL isMovedToCache = YES;
                NSError *error= nil;
                if ([[NSFileManager defaultManager] fileExistsAtPath:resumeDownloadTask.cachePath]) {
                    
                    if ([[NSFileManager defaultManager] removeItemAtPath:resumeDownloadTask.cachePath error:&error]) {
                        if (![[NSFileManager defaultManager] moveItemAtPath:locationStr toPath:resumeDownloadTask.cachePath error:&error]) {
                            RBELog(@"RBENetWork remove path failed:%@", [error localizedFailureReason]);
                            isMovedToCache = NO;
                        }
                    } else {
                        RBELog(@"RBENetWork remove path failed:%@", [error localizedFailureReason]);
                        isMovedToCache = NO;
                    }
                } else {
                    if (![[NSFileManager defaultManager] moveItemAtPath:locationStr toPath:resumeDownloadTask.cachePath error:&error]) {
                        isMovedToCache = NO;
                        RBELog(@"RBENetWork remove path failed:%@", [error localizedFailureReason]);
                    }
                }
                
                if (isMovedToCache) {
                    [self semaphoreLock];
                    self.downloadedContentPath[downloadTask.originalRequest.URL.absoluteString] = resumeDownloadTask.cachePath;
                    [self semaphoreUnlock];
                }
            }
        });
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self semaphoreLock];
    RBEResumeDownloadTask *resumeDownloadTask = self.rbeResumeDownloadTaskDic[@(task.taskIdentifier)];
    [self semaphoreUnlock];
    
    if (!resumeDownloadTask) {
        [super URLSession:session task:task didCompleteWithError:error];
        return;
    }
    
    dispatch_async(resumeDownloadTask.queue, ^{
        [self semaphoreLock];
        [self.rbeResumeDownloadTaskDic removeObjectForKey:@(task.taskIdentifier)];
        [self semaphoreUnlock];
        
        if (!resumeDownloadTask.isProvidedETagOrLastModified) {
            [super URLSession:session task:task didCompleteWithError:error];
            return;
        }
        
        //resume task ,even though file operation occur error
        if (error && error.userInfo[NSURLSessionDownloadTaskResumeData]) {
            NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:resumeDownloadTask.cachePath]) {
                
                NSError *error= nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:resumeDownloadTask.cachePath error:&error]) {
                    RBELog(@"RBENetWork remove directory failed:%@", [error localizedFailureReason]);
                } else {
                    [resumeData writeToFile:resumeDownloadTask.cachePath atomically:YES];
                }
            } else {
                [resumeData writeToFile:resumeDownloadTask.cachePath atomically:YES];
            }
        }
        
        [super URLSession:session task:task didCompleteWithError:error];
    });
}

- (NSString *)downloadedContentPathWithURLString:(NSString *)urlString {
    __block NSString *downloadContentPath = nil;
    
    [self semaphoreLock];
    [self.downloadedContentPath enumerateKeysAndObjectsUsingBlock:^(NSString *taskURL, NSString *path, BOOL * _Nonnull stop) {
        if ([urlString isEqualToString:taskURL]) {
            downloadContentPath = path;
            *stop = YES;
        }
    }];
    [self semaphoreUnlock];
    
    return downloadContentPath;
}

- (void)semaphoreLock {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
}

- (void)semaphoreUnlock {
    dispatch_semaphore_signal(_semaphore);
}

//If a file operation error or outputstream stream error occur, it will still resume data from cache path. In
//this scenario, downloadTask has fully downloaded. If just retrieve downloadedBytes from cache path and set
//range HTTP headers, HTTP response status code will be 416, cuz of requesting out of range of resource in
//sever. To prevent that, minus downloadedBytes.

- (BOOL)shouldResumeAtPath:(NSString *)path withRequest:(NSMutableURLRequest *)request {
    BOOL shouldResume = NO;
    
    unsigned long long downloadedBytes = [self fileSizeForPath:path];
    if (downloadedBytes > 1) {
        downloadedBytes --;
        
        [request setValue:[NSString stringWithFormat:@"bytes=%llu-", downloadedBytes] forHTTPHeaderField:@"Range"];
        
        shouldResume = YES;
    }
    
    return shouldResume;
}

- (unsigned long long)fileSizeForPath:(NSString *)path {
    unsigned long long fileSize = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileAttributeDic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
        if (!error && fileAttributeDic) {
            fileSize = [fileAttributeDic fileSize];
        }
    }
    
    return fileSize;
}

- (NSString *)cacheDirectory {
    static NSString *cacheDirectory;
    
    if (!cacheDirectory) {
        cacheDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:kRBEIncompleteDownLoadPath];
    }
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
        RBELog(@"RBENetWork creat directory failed:%@", [error localizedFailureReason]);
        cacheDirectory = nil;
    }
    
    return cacheDirectory;
}

@end
