//
//  RBEFireworkAdapter.h
//  RBENetWork
//
//  Created by Robbie on 15/11/18.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RBEFirework.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RBEFireworkRequestSerializerType) {
    RBEFireworkRequestSerializerTypeHTTP = 1,
    RBEFireworkRequestSerializerTypeJSON,
    RBEFireworkRequestSerializerTypePList,
};

typedef NS_ENUM(NSInteger, RBEFireworkResponseSerializerType) {
    RBEFireworkResponseSerializerTypeHTTP = 1,
    RBEFireworkResponseSerializerTypeJSON,
    RBEFireworkResponseSerializerTypeXML,
    RBEFireworkResponseSerializerTypePList,
    RBEFireworkResponseSerializerTypeImage,
};

typedef NS_ENUM(NSInteger, RBEFireworkResponseType) {
    RBEFireworkResponseTypeSuccess = 1,
    RBEFireworkResponseTypeFailure,
    RBEFireworkResponseTypeIgnore,
};

typedef RBEFireworkResponseType(^ValidateResponseBlock)(RBEFirework *responseFirework);
typedef  NSCachedURLResponse* _Nonnull (^CustomCachedURLResponse)(NSCachedURLResponse *proposedResponse);

@protocol RBEURLAdapterProtocol <NSObject>

- (NSString *)adaptedURL:(NSString *)originURL;

@end

@protocol RBEParametersAdapterProtocol <NSObject>

- (id)adaptedParametersWithOriginalParameters:(id)parameters;

@end

@interface RBEFireworkAdapter : NSObject

@property (nullable, nonatomic, strong) NSString *baseURL;
@property (nullable, nonatomic, strong) NSString *CDNURL;

@property (nullable, nonatomic, readonly, strong) NSString *freshnessCacheDirectory;
@property (nonnull, nonatomic, readonly, strong) NSString *HTTPCacheDirectory;
@property (nonatomic, readonly, assign) NSUInteger freshnessMemoryCount;
@property (nonatomic, readonly, assign) NSUInteger freshnessDiskCapacity;
@property (nonatomic, readonly, assign) NSUInteger HTTPMemoryCapacity;
@property (nonatomic, readonly, assign) NSUInteger HTTPDiskCapacity;

//determine call successBlock or failureBlock according to responseObjct
//for example, you could manage to call failureBlock, even for a bussiness failure not a HTTP failure
@property (nonatomic, copy) ValidateResponseBlock validateBlock;

//set a cutom block to modify HTTP response for HTTP cache
@property (nonatomic, copy) CustomCachedURLResponse customCachedURLResponse;

@property (nullable, nonatomic, readonly, strong) NSArray<id<RBEURLAdapterProtocol>> *URLAdapters;
@property (nullable, nonatomic, readonly, strong) id<RBEParametersAdapterProtocol> paramterAdapters;

+ (RBEFireworkAdapter *)sharedInstance;

- (void)enableCacheWithHTTPCachePatternDirectory:(NSString *)HTTPCacheDirectory
                                   HTTPMemoryCapacity:(NSUInteger)HTTPMemoryCapacity
                                     HTTPDiskCapacity:(NSUInteger)HTTPDiskCapacity;

- (void)enableCacheWithFreshnessCachePatternDirectory:(NSString *)freshnessCacheDirectory
                                 freshnessMemoryCount:(NSUInteger)fresshnessMemoryCount
                                freshnessDiskCapacity:(NSUInteger)freshnessDiskCapacity;


//clear firework cacahe in memory
- (void)purgeInMemoryCache;

//clear all firework cache including disk cache, heavy operation!
- (void)purgeAllCache;

//cancel NSURLSession task in particular NSURLSessionConfiguration with whether cancel unfinished task, see more from Apple NSURLSession Document
- (void)cancelAllRBEFireworkInConfigurationTpye:(RBESessionConfigurationType)configurationType  allowOutstandingTaskFinish:(BOOL)isAllow;

- (void)addURLAdapters:(id<RBEURLAdapterProtocol>)adapters;

- (void)addParamterAdapters:(id<RBEParametersAdapterProtocol>)adapters;

- (void)setCookieWithProperties:(NSDictionary<NSString *, id> *)properties;

//cookieDomain and cookieOriginUrl must pass one at least, name and value is not an option, the rest of parameter are option
- (void)setCookieWithCookieDomain:(nullable NSString *)domain
                  cookieOriginUrl:(nullable NSString *)originUrl
                       cookieName:(NSString *)name
                      cookieValue:(NSString *)value
                       cookiePath:(NSString *)path
                    cookieVersion:(nullable NSString *)version
                    cookieExpires:(nullable NSDate *)expires;

- (NSHTTPCookie *)cookieWithcookieName:(NSString *)name;

@end

@interface RBEFireworkAdapter (AFNetWorkingAdditions)

@property (nonatomic, assign) RBEFireworkRequestSerializerType requestSerializerType;

@property (nonatomic, assign) RBEFireworkResponseSerializerType responseSerializerType;

//Default is application/json text/json text/javascript
@property (nonatomic, strong) NSSet<NSString *> *acceptableContentTypes;

//Default is No
@property (nonatomic, assign) BOOL allowInvalidCertificates;

@end

NS_ASSUME_NONNULL_END
