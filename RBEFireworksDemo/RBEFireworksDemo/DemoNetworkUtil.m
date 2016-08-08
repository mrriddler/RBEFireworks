//
//  DemoNetworkUtil.m
//  RBEFireworkPerformance
//
//  Created by Robbie on 16/8/2.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "DemoNetworkUtil.h"

@interface DemoURLFilter : NSObject <RBEURLAdapterProtocol>

@end

@implementation DemoURLFilter

- (NSString *)adaptedURL:(NSString *)originURL {
    if ([originURL hasPrefix:@"demo"]) {
        return [originURL stringByAppendingString:@"/v1"];
    } else {
        return originURL;
    }
}

@end

@interface DemoParametersFilter : NSObject <RBEParametersAdapterProtocol>

@end

@implementation DemoParametersFilter

- (id)adaptedParametersWithOriginalParameters:(id)parameters {
    if (parameters) {
        NSMutableDictionary *paraDic = parameters;
        [paraDic setObject:@(1) forKey:@"type"];
        parameters = paraDic;
    }else {
        parameters = [[NSMutableDictionary alloc] init];
        [parameters setObject:@(1) forKey:@"type"];
    }
    
    return parameters;
}

@end

@implementation DemoNetworkUtil

+ (void)configureNetworkAdpater {
    RBEFireworkAdapter *adapter = [RBEFireworkAdapter sharedInstance];
    adapter.baseURL = @"DemoProjectBaseURL";
    adapter.CDNURL = @"DemoProjectCDNURL";
    adapter.allowInvalidCertificates = YES;
    
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    
    //For Freshness Cache
    NSString *freshnessCacheDir = [cacheDirectory stringByAppendingPathComponent:@"FreshnessCache"];
    [adapter enableCacheWithFreshnessCachePatternDirectory:freshnessCacheDir freshnessMemoryCount:20 freshnessDiskCapacity:10 * 1024 * 1024];
    
    //For HTTP Cache
    NSString *HTTPCacheDir = [cacheDirectory stringByAppendingPathComponent:@"HTTPCache"];
    [adapter enableCacheWithHTTPCachePatternDirectory:HTTPCacheDir HTTPMemoryCapacity:2 * 1024 * 1024 HTTPDiskCapacity:10 * 1024 * 1024];
    
    //clear memory cache
    [adapter purgeInMemoryCache];
    //clear memory cache and disk cache
    [adapter purgeAllCache];
    
    //Adapte global Parameters
    DemoParametersFilter *paramFilter = [[DemoParametersFilter alloc] init];
    [adapter addParamterAdapters:paramFilter];
    
    //Adapte URL
    DemoURLFilter *URLFilter = [[DemoURLFilter alloc] init];
    [adapter addURLAdapters:URLFilter];
    
    //Global response call back
    adapter.validateBlock = ^(RBEFirework *responseFirework) {
        RBEFireworkResponseType responseType = RBEFireworkResponseTypeSuccess;
        
        NSDictionary *responseDic = responseFirework.responseObject;
        if (responseDic) {
            NSNumber *code = responseDic[@"code"];
            
            if ([code isEqualToNumber:@0]) {
                //success
            } else if ([code isEqualToNumber:@1]) {
                responseType = RBEFireworkResponseTypeFailure;
            } else {
                responseType = RBEFireworkResponseTypeIgnore;
            }
        }
        return responseType;
    };
    
    //AFNetworking Configuration
    adapter.requestSerializerType = RBEFireworkRequestSerializerTypeHTTP;
    adapter.responseSerializerType = RBEFireworkResponseSerializerTypeJSON;
    adapter.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
    
    [adapter setCookieWithCookieDomain:@".demo.com"
                       cookieOriginUrl:nil
                            cookieName:@"demo"
                           cookieValue:@"demo_value"
                            cookiePath:@"/"
                         cookieVersion:nil
                         cookieExpires:nil];
    NSHTTPCookie *cookie = [adapter cookieWithcookieName:@"demo"];
    if (cookie) {
        //cookie to do...
    }
    
    //cancel all request, see more from NSURLSession finishTasksAndInvalidate API invalidateAndCancel API
    [adapter cancelAllRBEFireworkInConfigurationTpye:RBESessionConfigurationTypeDefault allowOutstandingTaskFinish:YES];
}

@end
