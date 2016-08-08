//
//  RBEFireworkAdapter.m
//  RBENetWork
//
//  Created by Robbie on 15/11/18.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import "RBEFireworkAdapter.h"
#import "RBEFireworkAdapter+Internal.h"
#import "NSString+RBEAdditions.h"
#import <objc/runtime.h>

@implementation RBEFireworkAdapter {
    NSMutableArray *_URLAdapters;
    id<RBEParametersAdapterProtocol> _parameterAdapters;
    NSString *_internalFreshnessCacheDirectory;
    NSString *_internalHTTPCacheDirectory;
    NSUInteger _internalFreshnessMemoryCount;
    NSUInteger _internalFreshnessDiskCapacity;
    NSUInteger _internalHTTPMemoryCapacity;
    NSUInteger _internalHTTPDiskCapacity;
}

+ (RBEFireworkAdapter *)sharedInstance {
    static id shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    return shareInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _URLAdapters = [[NSMutableArray alloc] init];
        self.allowInvalidCertificates = NO;
    }
    return self;
}

- (void)enableCacheWithHTTPCachePatternDirectory:(NSString *)HTTPCacheDirectory
                              HTTPMemoryCapacity:(NSUInteger)HTTPMemoryCapacity
                                HTTPDiskCapacity:(NSUInteger)HTTPDiskCapacity
{
    NSParameterAssert(HTTPCacheDirectory);
    
    _internalHTTPCacheDirectory = HTTPCacheDirectory;
    _internalHTTPMemoryCapacity = HTTPMemoryCapacity;
    _internalHTTPDiskCapacity = HTTPDiskCapacity;
}

- (void)enableCacheWithFreshnessCachePatternDirectory:(NSString *)freshnessCacheDirectory
                                 freshnessMemoryCount:(NSUInteger)fresshnessMemoryCount
                                freshnessDiskCapacity:(NSUInteger)freshnessDiskCapacity
{
    NSParameterAssert(freshnessCacheDirectory);
    
    _internalFreshnessCacheDirectory = freshnessCacheDirectory;
    _internalFreshnessMemoryCount = fresshnessMemoryCount;
    _internalFreshnessDiskCapacity = freshnessDiskCapacity;

}

- (void)purgeInMemoryCache {
    [self.delegate purgeInMemoryCache];
}

- (void)purgeAllCache {
    [self.delegate purgeAllCache];
}

- (void)cancelAllRBEFireworkInConfigurationTpye:(RBESessionConfigurationType)configurationType allowOutstandingTaskFinish:(BOOL)isAllow {
    [self.delegate cancelAllRBEFireworkInConfigurationTpye:configurationType allowOutstandingTaskFinish:isAllow];
}

- (void)setCookieWithProperties:(NSDictionary<NSString *, id> *)properties {
    NSHTTPCookie *cookie = [[NSHTTPCookie alloc] initWithProperties:properties];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
}

- (void)setCookieWithCookieDomain:(NSString *)domain cookieOriginUrl:(NSString *)originUrl cookieName:(NSString *)name cookieValue:(NSString *)value cookiePath:(NSString *)path cookieVersion:(NSString *)version cookieExpires:(NSDate *)expires {
    
    NSMutableDictionary *cookieDictionary = [[NSMutableDictionary alloc] init];
    if (domain) {
        [cookieDictionary setObject:domain forKey:NSHTTPCookieDomain];
    }
    if (originUrl) {
        [cookieDictionary setObject:originUrl forKey:NSHTTPCookieOriginURL];
    }
    [cookieDictionary setObject:name forKey:NSHTTPCookieName];
    [cookieDictionary setObject:value forKey:NSHTTPCookieValue];
    if (path) {
        [cookieDictionary setObject:path forKey:NSHTTPCookiePath];
    }
    if (version) {
        [cookieDictionary setObject:version forKey:NSHTTPCookieVersion];
    }
    if (expires) {
        [cookieDictionary setObject:expires forKey:NSHTTPCookieExpires];
    }
    
    NSHTTPCookie *cookie = [[NSHTTPCookie alloc] initWithProperties:cookieDictionary];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
}

- (NSHTTPCookie *)cookieWithcookieName:(NSString *)name {
    __block NSHTTPCookie *cookie = nil;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [cookieJar.cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:name]) {
            cookie = obj;
            *stop = YES;
        }
    }];
    
    return cookie;
}

- (void)addURLAdapters:(id<RBEURLAdapterProtocol>)adpaters {
    [_URLAdapters addObject:adpaters];
}

- (void)addParamterAdapters:(id<RBEParametersAdapterProtocol>)adapters {
    _parameterAdapters = adapters;
}

#pragma mark - Getters

- (NSArray<id<RBEURLAdapterProtocol>> *)URLAdapters {
    return [_URLAdapters copy];
}

- (id<RBEParametersAdapterProtocol>)paramterAdapters {
    return _parameterAdapters;
}

- (NSString *)freshnessCacheDirectory {
    return _internalFreshnessCacheDirectory;
}

- (NSString *)HTTPCacheDirectory {
    return _internalHTTPCacheDirectory;
}

- (NSUInteger)freshnessMemoryCount {
    return _internalFreshnessMemoryCount;
}

- (NSUInteger)HTTPMemoryCapacity {
    return _internalHTTPMemoryCapacity;
}

- (NSUInteger)freshnessDiskCapacity {
    return _internalFreshnessDiskCapacity;
}

- (NSUInteger)HTTPDiskCapacity {
    return _internalHTTPDiskCapacity;
}

@end

@implementation RBEFireworkAdapter (AFNetWorkingAdditions)

@dynamic requestSerializerType;
@dynamic responseSerializerType;
@dynamic acceptableContentTypes;
@dynamic allowInvalidCertificates;

- (void)setRequestSerializerType:(RBEFireworkRequestSerializerType)requestSerializerType {
    NSNumber *requestSerializerNum = [NSNumber numberWithInteger:requestSerializerType];
    objc_setAssociatedObject(self, @selector(requestSerializerType), requestSerializerNum, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (RBEFireworkRequestSerializerType)requestSerializerType {
    NSNumber *requestSerializerNum = objc_getAssociatedObject(self, @selector(requestSerializerType));
    return [requestSerializerNum integerValue];
}

- (void)setResponseSerializerType:(RBEFireworkResponseSerializerType)responseSerializerType {
    NSNumber *responseSerializerNum = [NSNumber numberWithInteger:responseSerializerType];
    objc_setAssociatedObject(self, @selector(responseSerializerType), responseSerializerNum, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (RBEFireworkResponseSerializerType)responseSerializerType {
    NSNumber *responseSerializerNum = objc_getAssociatedObject(self, @selector(responseSerializerType));
    return [responseSerializerNum integerValue];
}

- (void)setAcceptableContentTypes:(NSSet<NSString *> *)acceptableContentTypes {
    objc_setAssociatedObject(self, @selector(acceptableContentTypes), acceptableContentTypes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSSet<NSString *> *)acceptableContentTypes {
    return objc_getAssociatedObject(self, @selector(acceptableContentTypes));
}

- (void)setAllowInvalidCertificates:(BOOL)allowInvalidCertificates {
    NSNumber *allowInvalidCertificatesNumber = [NSNumber numberWithBool:allowInvalidCertificates];
    objc_setAssociatedObject(self, @selector(allowInvalidCertificates), allowInvalidCertificatesNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)allowInvalidCertificates {
    NSNumber *allowInvalidCertificatesNumber = objc_getAssociatedObject(self, @selector(allowInvalidCertificates));
    return [allowInvalidCertificatesNumber boolValue];
}

@end

