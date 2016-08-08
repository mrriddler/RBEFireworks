//
//  RBEFireworkHost.m
//  RBENetWork
//
//  Created by Robbie on 15/11/24.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import "AFURLSessionManager.h"

#import "RBEFireworkHost.h"
#import "RBEFirework.h"
#import "RBEFirework+Internal.h"
#import "RBEDownloadFirework.h"
#import "RBEDownloadFirework+Internal.h"
#import "RBEUploadFirework.h"
#import "RBEUploadFirework+Internal.h"
#import "RBECache.h"
#import "RBEFireworkAdapter.h"
#import "RBEFireworkAdapter+Internal.h"
#import "RBEMarco.h"
#import "NSDictionary+RBEAddition.h"
#import "NSString+RBEAdditions.h"
#import "NSDate+RFC1123.h"
#import "NSObject+RBEAdditions.h"
#import "RBEHTTPSessionManager.h"

static const CGFloat LM_Factor = 0.2; //heuristic expiratin constant parameter
static const NSUInteger RBECacheMaxDuration = 24 * 60 * 60; // 1 day
static const NSUInteger RBECacheMinDuration = 0.5; // 0.5 second
static const NSUInteger RBEDefalutCacheFreshness = 3 * 60; // 3 minutes

@interface RBEFireworkHost ()<RBEFireworkAdapterDelegate>

@property (nonatomic, strong) RBEFireworkAdapter *fireworkAdapater;
@property (nonatomic, strong) RBECache *responseObjectCache;
@property (nonatomic, strong) RBEHTTPSessionManager *defaultManager;
@property (nonatomic, strong) RBEHTTPSessionManager *emphermalManager;
@property (nonatomic, strong) RBEHTTPSessionManager *backgroundManager;

@end

@implementation RBEFireworkHost

+ (RBEFireworkHost *)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.fireworkAdapater = [RBEFireworkAdapter sharedInstance];
        self.fireworkAdapater.delegate = self;
        if (self.fireworkAdapater.freshnessCacheDirectory) {
            self.responseObjectCache = [[RBECache alloc] initWithCacheDirectory:self.fireworkAdapater.freshnessCacheDirectory memoryCacheCapacity:self.fireworkAdapater.freshnessMemoryCount diskCacheCapacity:self.fireworkAdapater.freshnessDiskCapacity];
        }
        
        if (self.fireworkAdapater.HTTPCacheDirectory) {
            NSURLCache *urlCache = [[NSURLCache alloc] initWithMemoryCapacity:self.fireworkAdapater.HTTPMemoryCapacity diskCapacity:self.fireworkAdapater.HTTPDiskCapacity diskPath:self.fireworkAdapater.HTTPCacheDirectory];
            [NSURLCache setSharedURLCache:urlCache];
        }    }
    return self;
}

- (void)resumeFirework:(RBEFirework *)firework {
    if (!firework.sessionConfigurationType) {
        firework.sessionConfigurationType = RBESessionConfigurationTypeDefault;
    }
    
    switch (firework.sessionConfigurationType) {
        case RBESessionConfigurationTypeDefault:
            [self resumeFirework:firework withManager:self.defaultManager];
            break;
        case RBESessionConfigurationTypeEphemeral:
            [self resumeFirework:firework withManager:self.emphermalManager];
            break;
        case RBESessionConfigurationTypeBackground:
            [self resumeFirework:firework withManager:self.backgroundManager];
            break;
    }
}

- (void)AddDefaultSettingForFirework:(RBEFirework *)firework withManager:(RBEHTTPSessionManager *)manager {
    if (self.fireworkAdapater.acceptableContentTypes) {
        manager.responseSerializer.acceptableContentTypes = self.fireworkAdapater.acceptableContentTypes;
    }
    
    manager.securityPolicy.allowInvalidCertificates = self.fireworkAdapater.allowInvalidCertificates;
    
    id<RBEParametersAdapterProtocol> adapters = [RBEFireworkAdapter sharedInstance].paramterAdapters;
    if ([adapters respondsToSelector:@selector(adaptedParametersWithOriginalParameters:)]) {
        firework.parameters = [adapters adaptedParametersWithOriginalParameters:firework.parameters];
    }
    
    [self setCacheResponeForFirework:firework withManager:manager];
    
    if (self.fireworkAdapater.requestSerializerType == 0) {
        self.fireworkAdapater.requestSerializerType = RBEFireworkRequestSerializerTypeHTTP;
    }
    
    if (self.fireworkAdapater.responseSerializerType == 0) {
        self.fireworkAdapater.responseSerializerType = RBEFireworkResponseSerializerTypeJSON;
    }
    
    if (firework.cachePattern == RBECachePatternFreshness) {
        if (![firework.changedObserveKeyPaths containsObject:NSStringFromSelector(@selector(cacheFreshnessInSecond))]) {
            firework.cacheFreshnessInSecond = RBEDefalutCacheFreshness;
        }
    }
    
    [firework.changedObserveKeyPaths enumerateObjectsUsingBlock:^(NSString *keyPath, BOOL * _Nonnull stop) {
        if (![keyPath isEqualToString:NSStringFromSelector(@selector(cacheFreshnessInSecond))]) {
            [manager.requestSerializer setValue:[firework valueForKey:keyPath] forKeyPath:keyPath];
        }
    }];
}

- (void)resumeFirework:(RBEFirework *)firework withManager:(RBEHTTPSessionManager *)manager {
    if (!firework.customRequest) {
        [self AddDefaultSettingForFirework:firework withManager:manager];
    }
    
    RBEFirework *cachedFirework = nil;
    if (!(firework.customRequest && [firework isMemberOfClass:[RBEDownloadFirework class]]) && firework.cachePattern == RBECachePatternFreshness) {
        cachedFirework = [self retrieveCachedFireworkWithFirework:firework];
    }
    
    //cache hit
    if (cachedFirework) {
        [self handleFireworkResponse:cachedFirework isFromCahce:YES];
        return;
    }
    
    switch (self.fireworkAdapater.requestSerializerType) {
        case RBEFireworkRequestSerializerTypeHTTP:
            manager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        case RBEFireworkRequestSerializerTypeJSON:
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        case RBEFireworkRequestSerializerTypePList:
            manager.requestSerializer = [AFPropertyListRequestSerializer serializer];
    }
    
    switch (self.fireworkAdapater.responseSerializerType) {
        case RBEFireworkResponseSerializerTypeHTTP:
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        case RBEFireworkResponseSerializerTypeJSON:
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        case RBEFireworkResponseSerializerTypeXML:
            manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        case RBEFireworkResponseSerializerTypePList:
            manager.responseSerializer = [AFPropertyListResponseSerializer serializer];
            break;
        case RBEFireworkResponseSerializerTypeImage:
            manager.responseSerializer = [AFImageResponseSerializer serializer];
            break;
    }
    
    if (firework.HTTPHeaders) {
        [firework.HTTPHeaders.allKeys enumerateObjectsUsingBlock:^(id HTTPHeaderFieldKey, NSUInteger idx, BOOL * _Nonnull stop) {
            id HTTPHeaderFieldValue = firework.HTTPHeaders[HTTPHeaderFieldKey];
            if ([HTTPHeaderFieldKey isKindOfClass:[NSString class]] && [HTTPHeaderFieldValue isKindOfClass:[NSString class]]) {
                [manager.requestSerializer setValue:HTTPHeaderFieldValue forHTTPHeaderField:HTTPHeaderFieldKey];
            } else {
                NSAssert(NO , @"firework HTTPheader's value and HTTPHeaderField must be NSString");
            }
        }];
    }
    
    if (firework.customRequest) {
        firework.dataTask = [manager dataTaskWithRequest:firework.customRequest uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            firework.responseError = error;
            firework.responseObject = responseObject;
            [self handleFireworkResponse:firework isFromCahce:NO];
        }];
        
        [firework.dataTask resume];
        return;
    }
    
    switch (firework.HTTPMethod) {
        case RBEHTTPMethodGet: {
            if ([firework isMemberOfClass:[RBEDownloadFirework class]]) {
                //resumable download Task
                RBEDownloadFirework *resumeDownloadTask = (RBEDownloadFirework *)firework;
                NSURLSessionTask *task = [manager GET:resumeDownloadTask.URL parameters:resumeDownloadTask.parameters destinationPath:resumeDownloadTask.destinationPath isProvidedETagOrLastModified:resumeDownloadTask.isProvideETagOrLastModified progress:^(NSProgress * _Nonnull downloadProgress) {
                    if (resumeDownloadTask.progressBlock) {
                        resumeDownloadTask.progressBlock(downloadProgress);
                    }
                } success:^(NSURLSessionTask * _Nonnull task, id  _Nullable responseObject) {
                    resumeDownloadTask.responseObject = responseObject;
                    [self handleFireworkResponse:resumeDownloadTask isFromCahce:NO];
                } failure:^(NSURLSessionTask * _Nullable task, NSError * _Nonnull error) {
                    resumeDownloadTask.responseError = error;
                    [self handleFireworkResponse:resumeDownloadTask isFromCahce:NO];
                }];
                
                if ([task isKindOfClass:[NSURLSessionDataTask class]]) {
                    resumeDownloadTask.dataTask = (NSURLSessionDataTask *)task;
                } else {
                    resumeDownloadTask.downLoadTask = (NSURLSessionDownloadTask *)task;
                }
            } else {
                firework.dataTask = [manager GET:firework.URL parameters:firework.parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    firework.responseObject = responseObject;
                    [self handleFireworkResponse:firework isFromCahce:NO];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    firework.responseError = error;
                    [self handleFireworkResponse:firework isFromCahce:NO];
                }];
            }
        }
            break;
        case RBEHTTPMethodPost: {
            if ([firework isMemberOfClass:[RBEUploadFirework class]]) {
                //mutipart upload task
                RBEUploadFirework *uploadFirework = (RBEUploadFirework *)firework;
                uploadFirework.dataTask = [manager POST:uploadFirework.URL parameters:uploadFirework.parameters constructingBodyWithBlock:uploadFirework.mutipartFormDataConstructingBlock progress:^(NSProgress * _Nonnull uploadProgress) {
                    if (uploadFirework.progressBlock) {
                        uploadFirework.progressBlock(uploadProgress);
                    }
                } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    uploadFirework.responseObject = responseObject;
                    [self handleFireworkResponse:uploadFirework isFromCahce:NO];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    uploadFirework.responseError = error;
                    [self handleFireworkResponse:uploadFirework isFromCahce:NO];
                }];
            } else {
                firework.dataTask = [manager POST:firework.URL parameters:firework.parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    firework.responseObject = responseObject;
                    [self handleFireworkResponse:firework isFromCahce:NO];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    firework.responseError = error;
                    [self handleFireworkResponse:firework isFromCahce:NO];
                }];
            }
        }
            break;
        case RBEHTTPMethodPut: {
            firework.dataTask = [manager PUT:firework.URL parameters:firework.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                firework.responseObject = responseObject;
                [self handleFireworkResponse:firework isFromCahce:NO];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                firework.responseError = error;
                [self handleFireworkResponse:firework isFromCahce:NO];
            }];
        }
            break;
        case RBEHTTPMethodPatch: {
            firework.dataTask = [manager PATCH:firework.URL parameters:firework.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                firework.responseObject = responseObject;
                [self handleFireworkResponse:firework isFromCahce:NO];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                firework.responseError = error;
                [self handleFireworkResponse:firework isFromCahce:NO];
            }];
        }
            break;
        case RBEHTTPMethodDelete: {
            firework.dataTask = [manager DELETE:firework.URL parameters:firework.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                firework.responseObject = responseObject;
                [self handleFireworkResponse:firework isFromCahce:NO];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                firework.responseError = error;
                [self handleFireworkResponse:firework isFromCahce:NO];
            }];
        }
            break;
        case RBEHTTPMethodHead: {
            firework.dataTask = [manager HEAD:firework.URL parameters:firework.parameters success:^(NSURLSessionDataTask * _Nonnull task) {
                [self handleFireworkResponse:firework isFromCahce:NO];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                firework.responseError = error;
                [self handleFireworkResponse:firework isFromCahce:NO];
            }];
        }
            break;
    }
}

- (void)cancelFirework:(RBEFirework *)firework {
    if ([firework isMemberOfClass:[RBEDownloadFirework class]]) {
        [firework.downLoadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            //do nothing, RBEHTTPSessionManager has already taken care of this
        }];
    } else {
        [firework.dataTask cancel];
    }
    [firework clearRetainCycle];
}

- (RBEFireworkResponseType)validateResponse:(RBEFirework *)firework {
    RBEFireworkResponseType responseType = RBEFireworkResponseTypeSuccess;
    
    id jsonValidator = firework.responseValidator;
    if (jsonValidator) {
        if ([NSObject rbe_checkJson:firework.responseObject withValidator:jsonValidator]) {
            responseType = RBEFireworkResponseTypeSuccess;
        } else {
            responseType = RBEFireworkResponseTypeFailure;
        }
    }
    
    if (firework.responseError) {
        responseType = RBEFireworkResponseTypeFailure;
    }
    
    if (self.fireworkAdapater.validateBlock) {
        responseType = self.fireworkAdapater.validateBlock(firework);
    }
    
    return responseType;
}

- (void)handleFireworkResponse:(RBEFirework *)firework isFromCahce:(BOOL)isFromCache {
    if (isFromCache) {
        firework.dataSource = RBEDataSourceCache;
    } else {
        firework.dataSource = RBEDataSourceNewtWork;
    }
    
    [firework.accessories enumerateObjectsUsingBlock:^(id<RBEFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(fireworkWillComplete:)]) {
            [obj fireworkWillComplete:firework];
        }
    }];
    
    if ([firework isMemberOfClass:[RBEDownloadFirework class]] || [firework isMemberOfClass:[RBEUploadFirework class]] || firework.customRequest) {
        if (firework.responseError) {
            if (firework.failureBlock) {
                firework.failureBlock(firework);
            }
            
            if (firework.internalDelegate) {
                [firework.internalDelegate fireworkFailed:firework];
            }
            
            if ([firework.delegate respondsToSelector:@selector(fireworkFailed:)]) {
                [firework.delegate fireworkFailed:firework];
            }
        } else {
            if (firework.successBlock) {
                firework.successBlock(firework);
            }
            
            if (firework.internalDelegate) {
                [firework.internalDelegate fireworkFinished:firework];
            }
            
            if ([firework.delegate respondsToSelector:@selector(fireworkFinished:)]) {
                [firework.delegate fireworkFinished:firework];
            }
        }
        
        [firework.accessories enumerateObjectsUsingBlock:^(id<RBEFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(fireworkDidComplete:)]) {
                [obj fireworkDidComplete:firework];
            }
        }];
        
        [firework clearRetainCycle];
        
        return;
    }
    
    RBEFireworkResponseType responseType = [self validateResponse:firework];
    switch (responseType) {
        case RBEFireworkResponseTypeSuccess: {
            if (!isFromCache) {
                [self cacheFirework:firework];
            }
            
            if (firework.successBlock) {
                firework.successBlock(firework);
            }
            
            if (firework.internalDelegate) {
                [firework.internalDelegate fireworkFinished:firework];
            }
            
            if ([firework.delegate respondsToSelector:@selector(fireworkFinished:)]) {
                [firework.delegate fireworkFinished:firework];
            }
        }
            break;
            
        case RBEFireworkResponseTypeFailure: {
            if (firework.failureBlock) {
                firework.failureBlock(firework);
            }
            
            if (firework.internalDelegate) {
                [firework.internalDelegate fireworkFailed:firework];
            }
            
            if ([firework.delegate respondsToSelector:@selector(fireworkFailed:)]) {
                [firework.delegate fireworkFailed:firework];
            }
        }
            break;
            
        case RBEFireworkResponseTypeIgnore: {
            if (firework.internalDelegate) {
                [firework.internalDelegate fireworkFailed:firework];
            }
        }
            break;
    }
    
    [firework.accessories enumerateObjectsUsingBlock:^(id<RBEFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(fireworkDidComplete:)]) {
            [obj fireworkDidComplete:firework];
        }
    }];
    
    [firework clearRetainCycle];
}

- (NSString *)downloadedContentPathWithFirework:(RBEFirework *)firework {
    NSString *downloadContentPath = nil;
    switch (firework.sessionConfigurationType) {
        case RBESessionConfigurationTypeDefault:
            downloadContentPath = [self.defaultManager downloadedContentPathWithURLString:firework.URL];
            break;
        case RBESessionConfigurationTypeEphemeral:
            downloadContentPath = [self.emphermalManager downloadedContentPathWithURLString:firework.URL];
            break;
        case RBESessionConfigurationTypeBackground:
            downloadContentPath = [self.backgroundManager downloadedContentPathWithURLString:firework.URL];
            break;
    }
    return downloadContentPath;
}

#pragma mark RBEFireworkAdapterDelegate

- (void)cancelAllRBEFireworkInConfigurationTpye:(RBESessionConfigurationType)configurationType allowOutstandingTaskFinish:(BOOL)isAllow {
    switch (configurationType) {
        case RBESessionConfigurationTypeDefault:
            [self.defaultManager invalidateSessionCancelingTasks:isAllow];
            break;
        case RBESessionConfigurationTypeEphemeral:
            [self.emphermalManager invalidateSessionCancelingTasks:isAllow];
            break;
        case RBESessionConfigurationTypeBackground:
            [self.backgroundManager invalidateSessionCancelingTasks:isAllow];
            break;
    }
    
}
- (void)purgeAllCache {
    [self.responseObjectCache purgeAllCache];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)purgeInMemoryCache {
    [self.responseObjectCache purgeMemoryCache];
}

#pragma mark Getter

- (RBEHTTPSessionManager *)defaultManager {
    if (!_defaultManager) {
        _defaultManager = [[RBEHTTPSessionManager alloc] initWithBaseURL:nil sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return _defaultManager;
}

- (RBEHTTPSessionManager *)emphermalManager {
    if (!_emphermalManager) {
        _emphermalManager = [[RBEHTTPSessionManager alloc] initWithBaseURL:nil sessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    }
    return _emphermalManager;
}

- (RBEHTTPSessionManager *)backgroundManager {
    if (!_backgroundManager) {
        _backgroundManager = [[RBEHTTPSessionManager alloc] initWithBaseURL:nil sessionConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"RBEFirework"]];
    }
    return _backgroundManager;
}

@end

#pragma mark RBENetWorkHost + RBECache

@implementation RBEFireworkHost (RBECache)

- (void)setCacheResponeForFirework:(RBEFirework *)firework withManager:(RBEHTTPSessionManager *)manager {
    __weak typeof(self) weakSelf = self;
    __weak typeof(firework) weakFirework = firework;
    
    [manager setDataTaskWillCacheResponseBlock:^NSCachedURLResponse * _Nonnull(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSCachedURLResponse * _Nonnull proposedResponse) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakFirework) strongFirework = weakFirework;
        
        //this frameWrok do not cache image, because you may use other framework to cache image, other framework would provide more richer function and cache image in memory is easy to cost a memory warning, normally app only possess 500MB Memory of iphone, give or take
        if ([strongFirework.responseHTTPHeaders rbe_isContentTypeImage]) {
            return nil;
        }
        
        //this framework do not cache customRequest and do not cache resumable download task
        if (strongFirework.customRequest || [strongFirework isMemberOfClass:[RBEDownloadFirework class]]) {
            return nil;
        }
        
        if (strongFirework.cachePattern == RBECachePatternHTTP) {
            return [strongSelf cacheResponseWithProposedResponse:proposedResponse];
        } else {
            return nil;
        }
    }];
}

- (NSCachedURLResponse *)cacheResponseWithProposedResponse:(NSCachedURLResponse *)proposedResponse {
    NSHTTPURLResponse *HTTPURLResponse = (NSHTTPURLResponse *)proposedResponse.response;
    NSMutableDictionary *responseHTTPHeader = [NSMutableDictionary dictionaryWithDictionary:HTTPURLResponse.allHeaderFields];
    NSCachedURLResponse *cachedResponse = nil;
    NSHTTPURLResponse *cachedURLResponse = nil;
    
    NSDate *responseDate = [responseHTTPHeader rbe_Date];
    
    if (!responseHTTPHeader) {
        return cachedResponse;
    }
    
    //check response header cache-control whether is no-cache
    if (!responseHTTPHeader.rbe_isCacheable) {
        return cachedResponse;
    }
    
    //check use cutom or not
    if ([RBEFireworkAdapter sharedInstance].customCachedURLResponse) {
        return [RBEFireworkAdapter sharedInstance].customCachedURLResponse(proposedResponse);
    }
    
    //check response have any required headers
    if (!responseHTTPHeader.rbe_hasHTTPCacheHeaders) {
        RBELog(@"RBENetWork : HTTP Response header have not any Cache-Control or Etag or Last-modified or Expires, this mode of Cache would provide a default expiration duration, in this case, you should try any other mode of cache");
        
        NSDate *expireDate = [responseDate dateByAddingTimeInterval:RBEDefalutCacheFreshness];
        [responseHTTPHeader setValue:[expireDate rbe_RFC1123String] forKey:@"Expires"];
        
        cachedURLResponse = [[NSHTTPURLResponse alloc] initWithURL:HTTPURLResponse.URL statusCode:HTTPURLResponse.statusCode HTTPVersion:@"HTTP/1.1" headerFields:responseHTTPHeader];
        cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:cachedURLResponse data:proposedResponse.data userInfo:proposedResponse.userInfo storagePolicy:proposedResponse.storagePolicy];
        return cachedResponse;
    }
    
    if (!responseHTTPHeader.rbe_cacheExpireDate) {
        RBELog( @"RBENetwork : HTTP Response header have not any Max-Age or Expires, if response header provide Last-Modified, this framework will adopt LM-Factor algorithm to caculate expire date, otherwise default expiration");
        
        NSDate *lastModifiedDate = [NSDate rbe_dateFromRFC1123:[responseHTTPHeader rbe_objectForInsensitiveKey:@"Last-Modified"]];
        if (lastModifiedDate) {
            NSTimeInterval lastModifiedSince1970 = [lastModifiedDate timeIntervalSince1970];
            NSTimeInterval responseSince1970 = [responseDate timeIntervalSince1970];
            NSTimeInterval cacheDuration = responseSince1970 - lastModifiedSince1970;
            cacheDuration *= LM_Factor;
            if (cacheDuration > RBECacheMaxDuration) {
                cacheDuration = RBECacheMaxDuration;
            }
            if (cacheDuration < RBECacheMinDuration) {
                cacheDuration = RBECacheMinDuration;
            }
            NSDate *expireDate = [responseDate dateByAddingTimeInterval:cacheDuration];
            
            [responseHTTPHeader setValue:[expireDate rbe_RFC1123String] forKey:@"Expires"];
        } else {
            NSDate *expireDate = [responseDate dateByAddingTimeInterval:RBEDefalutCacheFreshness];
            [responseHTTPHeader setValue:[expireDate rbe_RFC1123String] forKey:@"Expires"];
        }
    }
    
    cachedURLResponse = [[NSHTTPURLResponse alloc] initWithURL:HTTPURLResponse.URL statusCode:HTTPURLResponse.statusCode HTTPVersion:@"HTTP/1.1" headerFields:responseHTTPHeader];
    cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:cachedURLResponse data:proposedResponse.data userInfo:proposedResponse.userInfo storagePolicy:proposedResponse.storagePolicy];
    return cachedResponse;
}

- (RBEFirework *)retrieveCachedFireworkWithFirework:(RBEFirework *)firework {
    //compare use age to freshness lifetime
    NSDate *diskModificationDate = [self.responseObjectCache diskCacheModificationDateWithKey:@([firework hash])];
    if (!diskModificationDate) {
        return nil;
    }
    
    NSDate *expireDate = [diskModificationDate dateByAddingTimeInterval:firework.cacheFreshnessInSecond];
    if ([expireDate compare:[NSDate date]] == NSOrderedDescending) {
        firework.responseObject = self.responseObjectCache[@([firework hash])];
        return firework;
    }
    
    return nil;
}

- (void)cacheFirework:(RBEFirework *)firework {
    //this frameWrok do not cache image, because you may use other framework to cache image, and cache image in memory is easy to cost a memory warning, normally app only possess 500MB Memory of iphone, give or take
    if ([firework.responseHTTPHeaders rbe_isContentTypeImage]) {
        return;
    }
    
    //this framework do not cache customRequest and do not cache resumable download task
    if (firework.customRequest || [firework isMemberOfClass:[RBEDownloadFirework class]]) {
        return;
    }
    
    if (firework.cachePattern == RBECachePatternFreshness) {
        self.responseObjectCache[@([firework hash])] = firework.responseObject;
    }
}

@end
