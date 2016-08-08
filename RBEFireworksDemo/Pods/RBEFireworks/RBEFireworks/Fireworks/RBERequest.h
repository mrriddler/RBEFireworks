//
//  RBERequest.h
//  RBENetWork
//
//  Created by Robbie on 15/11/18.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RBEHTTPMethod) {
    RBEHTTPMethodGet = 1,
    RBEHTTPMethodPost,
    RBEHTTPMethodHead,
    RBEHTTPMethodPut,
    RBEHTTPMethodDelete,
    RBEHTTPMethodPatch,
};

typedef NS_ENUM(NSInteger, RBEDataSource) {
    RBEDataSourceNewtWork = 1,
    RBEDataSourceCache,
};

typedef NS_ENUM(NSInteger, RBECachePattern) {
    RBECachePatternNone = 1,
    RBECachePatternHTTP,
    RBECachePatternFreshness,
};

@interface RBERequest : NSObject

@property (nonatomic, strong) NSString *URL;
@property (nonatomic, strong) id parameters;
@property (nonatomic, assign) RBEHTTPMethod HTTPMethod;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *HTTPHeaders;

@property (nonatomic, strong) NSString *relativeURL;

//see more from Apple document
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) NSURLRequestNetworkServiceType networkServiceType;
@property (nonatomic, assign) BOOL allowsCellularAccess;
@property (nonatomic, assign) BOOL HTTPShouldHandleCookies;
@property (nonatomic, assign) BOOL HTTPShouldUsePipelining;

@property (nullable, nonatomic, readonly, strong) NSSet *changedObserveKeyPaths;

@property (nonatomic, assign) RBECachePattern cachePattern;
//must not manully set zero, if dont need cache, set cachePattern none
@property (nonatomic, assign) NSUInteger cacheFreshnessInSecond;

@property (nonatomic, assign) RBEDataSource dataSource;

//create a custom request
@property (nonatomic, strong) NSURLRequest *customRequest;

@property (nonatomic, assign) NSInteger tag;
@property (nullable, nonatomic, strong) NSDictionary *userInfo;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithRelativeURL:(NSString *)relativeURL;

- (instancetype)initWithRelativeURL:(NSString *)relativeURL HTTPMethod:(RBEHTTPMethod)HTTPMethod;

- (instancetype)initWithRelativeURL:(NSString *)relativeURL parameters:(nullable id)parameters HTTPMethod:(RBEHTTPMethod)HTTPMethod NS_DESIGNATED_INITIALIZER;

- (void)setAuthenticationHeaderFieldWithUserName:(NSString *)userName password:(NSString *)password;

- (void)setHeaderField:(NSDictionary<NSString *, NSString *> *)headerField;

- (BOOL)isEqualToRequest:(RBERequest *)request;

@end

NS_ASSUME_NONNULL_END
