//
//  RBEFirework.m
//  RBENetWork
//
//  Created by Robbie on 15/11/18.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import "RBEFirework.h"
#import "RBEFirework+Internal.h"
#import "RBEChainFirework+Internal.h"
#import "RBEFireworkHost.h"
#import "RBEFireworkAdapter.h"
#import "NSDictionary+RBEAddition.h"
#import "RBEMarco.h"
#import "RBEChainFirework.h"

@implementation RBEFirework

- (void)resume {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(fireworkWillResume:)]) {
            [obj fireworkWillResume:self];
        }
    }];
    
    if (self.state == NSURLSessionTaskStateSuspended) {
        [self.dataTask resume];
        return;
    }
    
    [[RBEFireworkHost sharedInstance] resumeFirework:self];
}

- (void)cancel {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(fireworkWillCancel:)]) {
            [obj fireworkWillCancel:self];
        }
    }];
    
    [[RBEFireworkHost sharedInstance] cancelFirework:self];
}

- (void)suspend {
    [self.accessories enumerateObjectsUsingBlock:^(id<RBEFireworkAccessoryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(fireworkWillSuspend:)]) {
            [obj fireworkWillSuspend:self];
        }
    }];
    
    [self.dataTask suspend];
}

- (void)setSuccessBlock:(SuccessBlock)successBlock failureBlock:(FailureBlock)failureBlock {
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
}

- (void)resumeWithSuccessBlock:(SuccessBlock)successBlock failureBlock:(FailureBlock)failureBlock {
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    [self resume];
}

- (void)clearRetainCycle {
    self.successBlock= nil;
    self.failureBlock = nil;
    self.internalDelegate = nil;
}

- (void)addAccessory:(id<RBEFireworkAccessoryProtocol>)accessory {
    [self.accessories addObject:accessory];
}

- (id)cachedObject {
    RBEFirework *cachedFirework = nil;
    
    if (self.cachePattern == RBECachePatternFreshness) {
        cachedFirework = [[RBEFireworkHost sharedInstance] retrieveCachedFireworkWithFirework:self];
        if (cachedFirework) {
            return cachedFirework.responseObject;
        }
    } else if (self.cachePattern == RBECachePatternHTTP) {
        NSError *serializationError = nil;
        NSString *HTTPMethod = nil;
        id requestSerializer = nil;
        
        if ([RBEFireworkAdapter sharedInstance].requestSerializerType == 0) {
            [RBEFireworkAdapter sharedInstance].requestSerializerType = RBEFireworkRequestSerializerTypeHTTP;
        }
        
        switch ([RBEFireworkAdapter sharedInstance].requestSerializerType) {
            case RBEFireworkRequestSerializerTypeHTTP:
                requestSerializer = [AFHTTPRequestSerializer serializer];
                break;
            case RBEFireworkRequestSerializerTypeJSON:
                requestSerializer = [AFJSONRequestSerializer serializer];
                break;
            case RBEFireworkRequestSerializerTypePList:
                requestSerializer = [AFPropertyListRequestSerializer serializer];
        }
        
        switch (self.HTTPMethod) {
            case RBEHTTPMethodGet:
                HTTPMethod = @"GET";
                break;
            case RBEHTTPMethodPost:
                HTTPMethod = @"POST";
                break;
            case RBEHTTPMethodPut:
                HTTPMethod = @"PUT";
                break;
            case RBEHTTPMethodPatch:
                HTTPMethod = @"PATCH";
                break;
            case RBEHTTPMethodDelete:
                HTTPMethod = @"DELETE";
                break;
            case RBEHTTPMethodHead:
                HTTPMethod = @"HEAD";
                break;
        }
        
        NSMutableURLRequest *request = [requestSerializer requestWithMethod:HTTPMethod URLString:self.URL parameters:self.parameters error:&serializationError];
        if (serializationError) {
            RBELog(@"RBEFireWork Request Serialization Error occur : %@", serializationError);
            return nil;
        }
        
        id responseSerializer = nil;
        
        if ([RBEFireworkAdapter sharedInstance].responseSerializerType == 0) {
            [RBEFireworkAdapter sharedInstance].responseSerializerType = RBEFireworkResponseSerializerTypeJSON;
        }
        
        switch ([RBEFireworkAdapter sharedInstance].responseSerializerType) {
            case RBEFireworkResponseSerializerTypeHTTP:
                responseSerializer = [AFHTTPResponseSerializer serializer];
                break;
            case RBEFireworkResponseSerializerTypeJSON:
                responseSerializer = [AFJSONResponseSerializer serializer];
                break;
            case RBEFireworkResponseSerializerTypeXML:
                responseSerializer = [AFXMLParserResponseSerializer serializer];
                break;
            case RBEFireworkResponseSerializerTypePList:
                responseSerializer = [AFPropertyListResponseSerializer serializer];
                break;
            case RBEFireworkResponseSerializerTypeImage:
                responseSerializer = [AFImageResponseSerializer serializer];
                break;
        }
        
        NSCachedURLResponse *cachedURLResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
        id cachedObject = [responseSerializer responseObjectForResponse:cachedURLResponse.response data:cachedURLResponse.data error:&serializationError];
        if (serializationError) {
            RBELog(@"RBEFireWork Response Serialization Error occur : %@", serializationError);
            return nil;
        }
        
        return cachedObject;
    }
    
    return nil;
}

- (BOOL)isEqualToFirework:(RBEFirework *)firework {
    return [super isEqualToRequest:firework];
}

- (NSString *)description {
    NSMutableString *displayString = [NSMutableString stringWithString:@"\n-------\n"];
    NSString *HTTPMethodString = nil;
    switch (self.HTTPMethod) {
        case RBEHTTPMethodGet:
            HTTPMethodString = @"GET  ";
            break;
        case RBEHTTPMethodPost:
            HTTPMethodString = @"POST  ";
            break;
        case RBEHTTPMethodPut:
            HTTPMethodString = @"PUT  ";
            break;
        case RBEHTTPMethodDelete:
            HTTPMethodString = @"DELETE  ";
            break;
        case RBEHTTPMethodHead:
            HTTPMethodString = @"HEAD  ";
            break;
        case RBEHTTPMethodPatch:
            HTTPMethodString = @"PATCH  ";
            break;
    }
    [displayString appendString:HTTPMethodString];
    [displayString appendString:self.URL];
    [displayString appendString:[NSString stringWithFormat:@"  %ld", (long)self.responseStatusCode]];
    [displayString appendString:@"\n--------\n"];
    
    return displayString;
}

#pragma mark - Getter And Setter

- (NSURLSessionTaskState)state {
    return _dataTask.state;
}

- (NSInteger)responseStatusCode {
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)_dataTask.response;
    return HTTPResponse.statusCode;
}

- (NSDictionary *)responseHttpHeaders {
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)_dataTask.response;
    return [HTTPResponse.allHeaderFields copy];
}

- (NSMutableArray<id<RBEFireworkAccessoryProtocol>> *)accessories {
    if (!_accessories) {
        _accessories = [[NSMutableArray alloc] init];
    }
    return _accessories;
}

@end

@implementation RBEFirework (ChainFireworkAddition)

- (void)breakChain {
    id<RBEFireworkInternalDelegate> internalDelegate = self.internalDelegate;
    if ([internalDelegate isKindOfClass:[RBEChainFirework class]]) {
        RBEChainFirework *chain = (RBEChainFirework *)internalDelegate;
        [chain cancelAfterwardFirework];
    }
}

@end
