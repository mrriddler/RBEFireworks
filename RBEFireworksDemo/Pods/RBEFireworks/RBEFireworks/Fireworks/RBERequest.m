//
//  RBEDecoupleRequest.m
//  RBENetWork
//
//  Created by Robbie on 15/11/18.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import "RBERequest.h"
#import "NSString+RBEAdditions.h"
#import "RBEFireworkAdapter.h"
#import "RBEMarco.h"

static void *RBERequestObserveContext = @"RBERequestObserveContext";

static NSArray *RBERequestObservedKeyPaths() {
    static NSArray *_RBERequestObservedKeyPaths = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _RBERequestObservedKeyPaths = @[NSStringFromSelector(@selector(timeoutInterval)), NSStringFromSelector(@selector(networkServiceType)), NSStringFromSelector(@selector(allowsCellularAccess)), NSStringFromSelector(@selector(HTTPShouldHandleCookies)), NSStringFromSelector(@selector(HTTPShouldUsePipelining)), NSStringFromSelector(@selector(cacheFreshnessInSecond))];
    });
    
    return _RBERequestObservedKeyPaths;
}

@implementation RBERequest {
    NSMutableSet *_internalChangedObserveKeyPaths;
    NSMutableDictionary *_internalHTTPHeaders;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"RBERequest must be initialized with design initializer initWithRelativeUrl:withMethod: Or initWithRelativeUrl Or initWithRelativeUrl:withParamteres:withMethod:"
                                 userInfo:nil];
    return [self initWithRelativeURL:@""];
}

- (instancetype)initWithRelativeURL:(NSString *)relativeURL {
    return [self initWithRelativeURL:relativeURL HTTPMethod:RBEHTTPMethodGet];
}

- (instancetype)initWithRelativeURL:(NSString *)relativeURL HTTPMethod:(RBEHTTPMethod)HTTPMethod {
    NSParameterAssert(relativeURL);
    NSParameterAssert(HTTPMethod);
    
    return [self initWithRelativeURL:relativeURL parameters:nil HTTPMethod:HTTPMethod];
}

- (instancetype)initWithRelativeURL:(NSString *)relativeURL parameters:(id)paramteres HTTPMethod:(RBEHTTPMethod)HTTPMethod {
    NSParameterAssert(relativeURL);
    NSParameterAssert(HTTPMethod);
    
    self = [super init];
    if (self) {
        self.relativeURL = relativeURL;
        if (paramteres) {
            self.parameters = [paramteres mutableCopy];
        }
        self.HTTPMethod = HTTPMethod;
        
        _internalHTTPHeaders = [[NSMutableDictionary alloc] init];
        
        _internalChangedObserveKeyPaths = [NSMutableSet set];
        [RBERequestObservedKeyPaths() enumerateObjectsUsingBlock:^(NSString *keyPath, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([self respondsToSelector:NSSelectorFromString(keyPath)]) {
                [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:RBERequestObserveContext];
            }
        }];
        
        self.cachePattern = RBECachePatternNone;
    }
    return self;
}

- (void)dealloc {    
    [RBERequestObservedKeyPaths() enumerateObjectsUsingBlock:^(NSString *keyPath, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self respondsToSelector:NSSelectorFromString(keyPath)]) {
            [self removeObserver:self forKeyPath:keyPath context:RBERequestObserveContext];
        }
    }];
}

- (NSUInteger)hash {
    NSString *HTTPMethodString= nil;
    switch (self.HTTPMethod) {
        case RBEHTTPMethodGet:
            HTTPMethodString = @"GET";
            break;
        case RBEHTTPMethodPost:
            HTTPMethodString = @"POST";
            break;
        case RBEHTTPMethodPut:
            HTTPMethodString = @"PUT";
            break;
        case RBEHTTPMethodDelete:
            HTTPMethodString = @"DELETE";
            break;
        case RBEHTTPMethodHead:
            HTTPMethodString = @"HEAD";
            break;
        case RBEHTTPMethodPatch:
            HTTPMethodString = @"PATCH";
            break;
    }
    
    NSMutableString *hashString = [self.URL mutableCopy];
    [hashString appendString:HTTPMethodString];
    if (self.parameters) {
        NSString *parametersString = [NSString rbe_URLParametersStringFromParameters:self.parameters];
        [hashString appendString:parametersString];
    }
    
    [_internalHTTPHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull HTTPHeaderField, id  _Nonnull value, BOOL * _Nonnull stop) {
        if ([HTTPHeaderField isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]]) {
            [hashString appendString:HTTPHeaderField];
            [hashString appendString:value];
        } else {
            RBELog(@"RBENetWork Error: class of key/value in headerField Dictionary should be NSString.");
        }
    }];
    
    return [hashString hash];
}

- (BOOL)isEqualToRequest:(RBERequest *)request {
    if (self == request) {
        return YES;
    }
    
    //To prevent hash collision, check every property that identifier a request
    if ([self hash] != [request hash]) {
        return NO;
    }
    
    if (![self.URL isEqualToString:request.URL]) {
        return NO;
    }
    
    if (self.HTTPMethod != request.HTTPMethod) {
        return NO;
    }
    
    if (self.parameters) {
        if (![self.parameters isEqual:request.parameters]) {
            return NO;
        }
    }
    
    if (self.HTTPHeaders) {
        if (![self.HTTPHeaders isEqualToDictionary:request.HTTPHeaders]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    return [self isEqualToRequest:object];
}

//employee KVO to set property have default value
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == RBERequestObserveContext) {
        if ([change[NSKeyValueChangeNewKey] isEqual:[NSNull null]]) {
            [_internalChangedObserveKeyPaths removeObject:keyPath];
        } else {
            [_internalChangedObserveKeyPaths addObject:keyPath];
        }
    }
}

#pragma mark - Setter And Getter

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    [self willChangeValueForKey:NSStringFromSelector(@selector(timeoutInterval))];
    _timeoutInterval = timeoutInterval;
    [self didChangeValueForKey:NSStringFromSelector(@selector(timeoutInterval))];
}

- (void)setNetworkServiceType:(NSURLRequestNetworkServiceType)networkServiceType {
    [self willChangeValueForKey:NSStringFromSelector(@selector(networkServiceType))];
    _networkServiceType = networkServiceType;
    [self didChangeValueForKey:NSStringFromSelector(@selector(networkServiceType))];
}

- (void)setAllowsCellularAccess:(BOOL)allowsCellularAccess {
    [self willChangeValueForKey:NSStringFromSelector(@selector(allowsCellularAccess))];
    _allowsCellularAccess = allowsCellularAccess;
    [self didChangeValueForKey:NSStringFromSelector(@selector(allowsCellularAccess))];
}

- (void)setHTTPShouldHandleCookies:(BOOL)HTTPShouldHandleCookies {
    [self willChangeValueForKey:NSStringFromSelector(@selector(HTTPShouldHandleCookies))];
    _HTTPShouldHandleCookies = HTTPShouldHandleCookies;
    [self didChangeValueForKey:NSStringFromSelector(@selector(HTTPShouldHandleCookies))];
}

- (void)setHTTPShouldUsePipelining:(BOOL)HTTPShouldUsePipelining {
    [self willChangeValueForKey:NSStringFromSelector(@selector(HTTPShouldUsePipelining))];
    _HTTPShouldUsePipelining = HTTPShouldUsePipelining;
    [self didChangeValueForKey:NSStringFromSelector(@selector(HTTPShouldUsePipelining))];
}

- (void)setCacheFreshnessInSecond:(NSUInteger)cacheFreshnessInSecond {
    [self willChangeValueForKey:NSStringFromSelector(@selector(cacheFreshnessInSecond))];
    _cacheFreshnessInSecond = cacheFreshnessInSecond;
    [self didChangeValueForKey:NSStringFromSelector(@selector(cacheFreshnessInSecond))];
}

- (void)setAuthenticationHeaderFieldWithUserName:(NSString *)userName password:(NSString *)password {
    [_internalHTTPHeaders addEntriesFromDictionary:@{[NSString rbe_Base64EncodedStringFromString:userName] : [NSString rbe_Base64EncodedStringFromString:password]}];
}

- (void)setHeaderField:(NSDictionary *)headerField {
    __block BOOL shouldAdd = true;
    [headerField enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull HTTPHeaderField, id  _Nonnull value, BOOL * _Nonnull stop) {
        if (![HTTPHeaderField isKindOfClass:[NSString class]] || ![value isKindOfClass:[NSString class]]) {
            RBELog(@"RBENetWork Error: class of key/value in headerField Dictionary should be NSString.");
            shouldAdd = false;
            *stop = true;
        }
    }];
    
    if (shouldAdd) {
        [_internalHTTPHeaders addEntriesFromDictionary:headerField];
    }
}

- (NSString *)URL {
    if (!_URL) {
        if ([_relativeURL hasPrefix:@"http"]) {
            return [_relativeURL copy];
        }
        
        if ([RBEFireworkAdapter sharedInstance].CDNURL.length > 0) {
            _URL = [[RBEFireworkAdapter sharedInstance].CDNURL stringByAppendingString:_relativeURL];
        } else {
            _URL = [[RBEFireworkAdapter sharedInstance].baseURL stringByAppendingString:_relativeURL];
        }
        
        NSArray *adpaters = [RBEFireworkAdapter sharedInstance].URLAdapters;
        [adpaters enumerateObjectsUsingBlock:^(id<RBEURLAdapterProtocol> adpater, NSUInteger idx, BOOL * _Nonnull stop) {
            _URL = [adpater adaptedURL:_URL];
        }];
    }
    return _URL;
}
- (NSSet *)changedObserveKeyPaths {
    return [_internalChangedObserveKeyPaths copy];
}

- (NSDictionary *)HTTPHeaders {
    return [_internalHTTPHeaders copy];
}

@end
