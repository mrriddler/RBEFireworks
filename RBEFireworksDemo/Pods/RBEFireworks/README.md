# RBEFireworks(En)

RBEFireworks is a feature rich and flexible library. It deals with common demands of network components, and makes the programming of network requests easier. Based on AFNetworking3.x(NSURLSession), it reaches a higher level of abstraction, and takes references of the enlightening ideas from YTKNetwork.

[AFNetworking](https://github.com/AFNetworking/AFNetworking) and [YTKNetwork](https://github.com/yuantiku/YTKNetwork) are greatly appreciated here, as the open resources of yours would be endless wealth for the community.

The principle of RBEFireworks's architecture design is simplicity, which allows you use it more easily. It feels like native Apple library, as long as you have knowledges on NSURLSession and NSURLRequest, this library could be comprehensive for you very quickly. It abstracts network requests into new objects, provides powerful expressibility, and is super convenient for reuse. 

RBEFireworks wish your network requests may bloom as fireworks, and could be left as eternal memories!

[天朝的同学可以看这里，RBEFireworks(中文)](https://github.com/robbie23/RBEFireworks/blob/master/RBEFireworks(%E4%B8%AD%E6%96%87).md)

### Features

- Cancel and resume request
- Resume Download request
- Upload request with much more friendly interface design
- Upload and download request progress call back
- Chain request, a group of request have dependent relationship each other.
- Batch request, a group of independent request.
- Freshness cache, high performance cache base on memory and disk, employ LRU algorithum.
- Uniformly preprocess request parameters, for instance, adding device type.
- Uniformly process request response, for instance, judging request whether success or failure according to business.
- Uniformly process request URL, for instance, adding service API version.
- Validate response data type whether meet your expectation.
- Support Block and Delegate call back.
- Expand request, for instance adding loading, count request duration.
- Uniformly handle NSHTTPCookie and NSURLCache.


### Requirements

iOS8.0+

### Link with required Library and frameworks

libsqlite3.tbd

### Installation

```objective-c
$ pod RBEFireworks
```

------

### Basic Configuration

Before using RBEFireworks, you need to configure URL setting. You could set BaseURL or you could set CDN URL.

```objective-c
    [RBEFireworkAdapter sharedInstance].baseURL = @"DemoProjectBaseURL";
    [RBEFireworkAdapter sharedInstance].CDNURL = @"DemoProjectCDNURL";
```

------

### Basic Usage

To resume a GET request, you should provide relative URL.

```
    RBEFirework *firework = [[RBEFirework alloc] initWithRelativeURL:@"demo"];
    [firework resume];
```

To resume a POST request. To resume different HTTP method request, you just provide different enum.

```objective-c
    RBEFirework *firework = [[RBEFirework alloc] initWithRelativeURL:@"demo" 
                                                          parameters:@{@"demo" : @"demo"} 
                                                          HTTPMethod:RBEHTTPMethodPost];
    [firework resumeWithSuccessBlock:^(RBEFirework * _Nonnull responseFirework) {
        //succes to do...
    } failureBlock:^(RBEFirework * _Nonnull responseFirework) {
        //failure to do...
    }];
```

To resume a Chain request, you should provide a array consist of requests. Chain request execute request on array sequence. If one request fail, the following request will not be executed.

```objective-c
    RBEFirework *demoOne = [[RBEFirework alloc] initWithRelativeURL:@"demoOne"];
    RBEFirework *demoTwo = [[RBEFirework alloc] initWithRelativeURL:@"demoTwo"];
    RBEFirework *demoThree = [[RBEFirework alloc] initWithRelativeURL:@"demoThree"];

    RBEChainFirework *chain = [[RBEChainFirework alloc] initWithFireworkArray:@[demoOne, demoTwo, demoThree]];
    [chain resumeWithSuccessBlock:^(RBEChainFirework * _Nonnull chainFirework) {
        RBEFirework *successOne = [chainFirework.fireworkArr firstObject];
        NSDictionary *successDicOne = successOne.responseObject;
        if (successDicOne) {
            //first successed...
        }
        
        RBEFirework *successTwo = chainFirework.fireworkArr[1];
        NSDictionary *successDicTwo = successTwo.responseObject;
        if (successDicTwo) {
            //second successed...
        }
        
        RBEFirework *successThree = [chainFirework.fireworkArr lastObject];
        NSDictionary *successDicThree = successThree.responseObject;
        if (successDicThree) {
            //third successed...
        }
        
    } failureBlock:^(RBEChainFirework * _Nonnull chainFirework, RBEFirework * _Nonnull failedFirework) {
        if ([failedFirework isEqualToFirework:[chainFirework.fireworkArr firstObject]]) {
            //first failed...
        } else if ([failedFirework isEqualToFirework:chainFirework.fireworkArr[1]]) {
            //second failed...
        } else {
            //third failed...
        }
    }];
```

To resume a batch request,  besides a request  array, you need to decide if one request fail, should cancel other request. Default is NO.

```objective-c
    RBEFirework *demoOne = [[RBEFirework alloc] initWithRelativeURL:@"demoOne"];
    RBEFirework *demoTwo = [[RBEFirework alloc] initWithRelativeURL:@"demoTwo"];
    RBEFirework *demoThree = [[RBEFirework alloc] initWithRelativeURL:@"demoThree"];
    
    [demoOne setSuccessBlock:^(RBEFirework * _Nonnull responseFirework) {
        //first successed...
    } failureBlock:^(RBEFirework * _Nonnull responseFirework) {
        //first failed...
    }];
    
    [demoTwo setSuccessBlock:^(RBEFirework * _Nonnull responseFirework) {
        //second successed...
    } failureBlock:^(RBEFirework * _Nonnull responseFirework) {
        //second failed...
    }];
    
    [demoThree setSuccessBlock:^(RBEFirework * _Nonnull responseFirework) {
        //third successed...
    } failureBlock:^(RBEFirework * _Nonnull responseFirework) {
        //third failed...
    }];
    
    RBEBatchFirework *batch = [[RBEBatchFirework alloc] initWithFireworkArray:@[demoOne, demoTwo, demoThree] shouldCancelAllFireworkIfOneFireworkFailed:NO];
    [batch resume];
```

If delegate is your preference callback, you could use this group protocol.

```objective-c
//Firework success
- (void)fireworkFinished:(RBEFirework *)firework {}
//Firework fail
- (void)fireworkFailed:(RBEFirework *)firework {}
//Chain Firework success
- (void)chainFireworkFinished:(RBEChainFirework *)chainFirework {}
//Chain Firework fail
- (void)chainFireworkFailed:(RBEChainFirework *)chainFirework failedFirework:(RBEFirework *)firework {}
//Batch Firework success
- (void)batchFireworkFinished:(RBEBatchFirework *)batchFirework {}
//Batch Firework fail
- (void)batchFireworkFailed:(RBEBatchFirework *)batchFirework failedFireworks:(NSArray<RBEFirework *> *)failedFireworks {}
```

------

### Uniformly Configuration

You could filter URL uniformly by conforming *RBEURLAdapterProtocol* and implementation *adaptedURL:* function.

You could also filter parameters uniformly by conforming *RBEParametersAdapterProtocol* and implementation *adaptedParametersWithOriginalParameters:* function.

```
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
```

Then write following code:

```objective-c
    //Adapte Parameters
    DemoParametersFilter *paramFilter = [[DemoParametersFilter alloc] init];
    [[RBEFireworkAdapter sharedInstance] addParamterAdapters:paramFilter];
    
    //Adapte URL
    DemoURLFilter *URLFilter = [[DemoURLFilter alloc] init];
    [[RBEFireworkAdapter sharedInstance] addURLAdapters:URLFilter];
```

You could also decide uniformly request call back success, failure or ignore. If you decide ignore request, request will not execute success completion block or failure completion block. 

```objective-c
    [RBEFireworkAdapter sharedInstance].validateBlock = ^(RBEFirework *responseFirework) {
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
```

You could set or get cookie by RBEFireworkAdapter.

```objective-c
    [[RBEFireworkAdapter sharedInstance] setCookieWithCookieDomain:@".demo.com"
                       cookieOriginUrl:nil
                            cookieName:@"demo"
                           cookieValue:@"demo_value"
                            cookiePath:@"/"
                         cookieVersion:nil
                         cookieExpires:nil];
    NSHTTPCookie *cookie = [[RBEFireworkAdapter sharedInstance] cookieWithcookieName:@"demo"];
```

------

### Cache

There are two pattern of cache in RBEFireworks. One is HTTP cache pattern, the other is Freshness cache Pattern. You could  change *cachePattern* property to affect cache pattern.

HTTP cache pattern employ NSURLCache to implement, basically it just cache request according to HTTP standard. You also could change RBEFireworkAdapter's *customCachedURLResponse* property to provide custom implementation.

Freshness cache pattern employ RBECache to implement, you need to change *cacheFreshnessInSecond* property to provide the survival duration of cache, in seconds. If cache is not out of survival duration. That mean cache is fresh , request will not actual resume. If cache is out of survival duration. That mean cache is stale, request will actual resume.

Or you could change *cachePattern* property to *RBECachePatternNone*, disable any pattern cache. Default is *RBECachePatternNone*.

You should enable any pattern cache by RBEFireworkAdapter. You need to provide the directory of cache, the capacity of cache both in memory and disk. Although, the unit of the capacity of HTTP cache pattern is byte, the unit of the capacity of Freshness cache pattern is amount of request your want to cache.

```objective-c
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    
    //For Freshness Cache
    NSString *freshnessCacheDir = [cacheDirectory stringByAppendingPathComponent:@"FreshnessCache"];
    [[RBEFireworkAdapter sharedInstance] enableCacheWithFreshnessCachePatternDirectory:freshnessCacheDir freshnessMemoryCount:20 freshnessDiskCapacity:10 * 1024 * 1024];
    
    //For HTTP Cache
    NSString *HTTPCacheDir = [cacheDirectory stringByAppendingPathComponent:@"HTTPCache"];
    [[RBEFireworkAdapter sharedInstance] enableCacheWithHTTPCachePatternDirectory:HTTPCacheDir HTTPMemoryCapacity:2 * 1024 * 1024 HTTPDiskCapacity:10 * 1024 * 1024];
```

Purge all cache or purge cache in memory.

```objective-c
    //clear memory cache
    [[RBEFireworkAdapter sharedInstance] purgeInMemoryCache];
    //clear memory cache and disk cache
    [[RBEFireworkAdapter sharedInstance] purgeAllCache];
```

You could also get cache of request by calling *cachedObject* function.

```
    RBEFirework *demoOne = [[RBEFirework alloc] initWithRelativeURL:@"demoOne"];
    id cachedObject = demoOne.cachedObject;
    if (cachedObject) {
        //cache to do...
    }
```

------

### Upload and download

Your employ RBEUploadFirework to upload data. The URL your provide to init RBEUploadFirework is not relative URL, is absolutely URL. RBEUploadFirework employ AFNetworking's implementation of mutipart/form-data upload.

You could provide the URL of file, the NSInputStream of data, the NSData of data, the body of multipart/form-data request to upload.

```objective-c
    RBEUploadFirework *upload = [[RBEUploadFirework alloc] initWithUploadURL:@"demo"];
                           [upload uploadWithFileURL:[NSURL URLWithString:@"demoURL"] 
                                                name:@"demo" 
                                            fileName:@"demoFileName" 
                                            mimeType:@"demoMimeType"];
```

You could employ RBEDownloadFirework to resume download. The URL your provide to init RBEDownloadFirework is not relative URL, is absolutely URL.

The native of Apple implementation of resume download must meet following conditions:

- Get request
- The server supports byte-range requests
- The server provides either the ETag or Last-Modified header (or both) in its response

RBEFireworks implement resume download that don't acquire  ETag or Last-Modified.

You could change *isProvideETagOrLastModified* property to specify. Default is YES.

```objective-c
    RBEDownloadFirework *download = [[RBEDownloadFirework alloc] initWithDownloadURL:@"demo" destinationPath:@"demoDestinationPath"];
    //Employ NSURLSession downloadTaskWithResumeData API or self-Implementaion
    download.isProvideETagOrLastModified = YES;
    [download resumeWithSuccessBlock:^(RBEFirework * _Nonnull responseFirework) {
        NSString *path = [download downloadedContentPath];
        if (path) {
            //Get path to do...
        }
    } failureBlock:^(RBEFirework * _Nonnull responseFirework) {
        //failure to do...
    }];
```

After Success, get actual downloaded content path by calling *downloadedContentPath*. If downloaded content could not write to your provided path. Downloaded content will write to a temp path. So the path of *downloadedContentPath* return could not be your provided path.

RBEUploadFirework and RBEDownloadFirework could get call back of progress by change *progressBlock* property.

```objective-c
firework.progressBlock = ^(NSProgress *progress) {
        //progress to do...
    };
```

------

### More Features

Suspend and cancel request.

```objective-c
    [firework suspend];
    [firework cancel];
```

You could break chain request by calling *breakChain* function.

```
    RBEFirework *demoOne = [[RBEFirework alloc] initWithRelativeURL:@"demoOne"];
    [demoOne setSuccessBlock:^(RBEFirework * _Nonnull responseFirework) {
       NSDictionary *respondeDic = responseFirework.responseObject;
       if (respondeDic[@"demo"]) {
           [responseFirework breakChain];
       }
    } failureBlock:^(RBEFirework * _Nonnull responseFirework) {
        //failure to do
    }];

    RBEFirework *demoTwo = [[RBEFirework alloc] initWithRelativeURL:@"demoTwo"];

    RBEChainFirework *chain = [[RBEChainFirework alloc] initWithFireworkArray:@[demoOne, demoThree]];
    [chain resume];
    
```

You could validate the response type of service return meet your expectation. The name of data should map to the type of data. If it does not meet, request will fail.

```objective-c
    firework.responseValidator = @[@{@"demoId" : [NSString class],
                                    @"demoTime" : [NSNumber class],
                                    @"demoStuff" : @{
                                            @"demoStuffId" : [NSString class],
                                       @"demoStuffContent" : [NSString class]
                                            }
                                    }];
```

You could do anything before request resume, before request cancel, before request suspend, before request execute completion block or after execute completion block. You just need to conform *RBEFireworkAccessoryProtocol* and implement any function. For instance, you could write following code to show loading:

```objective-c
@interface DemoFireworkAccessory : NSObject <RBEFireworkAccessoryProtocol>

@property (nonatomic, strong) UIActivityIndicatorView *indicator;

+ (instancetype)accessory;

- (void)fireworkWillResume:(RBEFirework *)firework;

- (void)fireworkWillComplete:(RBEFirework *)firework;

@end
  
@implementation DemoFireworkAccessory

+ (instancetype)accessory {
    DemoFireworkAccessory *accessory = [[DemoFireworkAccessory alloc] init];
    accessory.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    return accessory;
}

- (void)fireworkWillResume:(RBEFirework *)firework {
    [self.indicator startAnimating];
}

- (void)fireworkWillComplete:(RBEFirework *)firework {
    [self.indicator stopAnimating];
}

@end
```

Then write following code:

```objective-c
    DemoFireworkAccessory *accessory = [DemoFireworkAccessory accessory];
    [firework addAccessory:accessory];
```

You could resume custom request by change *customRequest* property, custom request you provide will ignore other RBEFirework configuration besides success and failure call back.

```objective-c
    firework.customRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"firework"]];
```

You could cancel all request by calling following function of RBEFireworkAdapter. This will lead NSURLSession corresponding configurationType to call finishTasksAndInvalidate or invalidateAndCancel function. 

```objective-c
- (void)cancelAllRBEFireworkInConfigurationTpye:(RBESessionConfigurationType)configurationType  allowOutstandingTaskFinish:(BOOL)isAllow;
```

Besides, you could still configure AFNetworking.

```objective-c
@property (nonatomic, assign) RBEFireworkRequestSerializerType requestSerializerType;

@property (nonatomic, assign) RBEFireworkResponseSerializerType responseSerializerType;

//Default is application/json text/json text/javascript
@property (nonatomic, strong) NSSet<NSString *> *acceptableContentTypes;

//Default is No
@property (nonatomic, assign) BOOL allowInvalidCertificates;
```

The first one is request serialization type, default is HTTP. The second one is response sterilization type., default is JSON. The third one is response acceptable content type, default is application/json,text/json,text/javascript. The fourth one is whether allow invalid certificates, default is NO.

There are still multiple property to configure, they all directly affect NSMutableURLRequest.

```objective-c
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) NSURLRequestNetworkServiceType networkServiceType;
@property (nonatomic, assign) BOOL allowsCellularAccess;
@property (nonatomic, assign) BOOL HTTPShouldHandleCookies;
@property (nonatomic, assign) BOOL HTTPShouldUsePipelining;
```

And configuration type, it affect request corresponding NSURLSessionConfiguration.

```objective-c
@property (nonatomic, assign) RBESessionConfigurationType sessionConfigurationType;
```

And Tag

```objective-c
@property (nonatomic, assign) NSInteger tag;
@property (nullable, nonatomic, strong) NSDictionary *userInfo;
```

And change HTTP header

```objective-c
- (void)setAuthenticationHeaderFieldWithUserName:(NSString *)userName password:(NSString *)password;

- (void)setHeaderField:(NSDictionary<NSString *, NSString *> *)headerField;
```

If you want to get information of request, just NSLog it.

------

Above code also demonstrate in demo.

Most of all, have fun!