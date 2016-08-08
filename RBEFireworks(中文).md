# RBEFireworks(中文)

RBEFireworks是一个功能丰富、灵活的框架。它将网络组件共通的需求进行处理，使你编写网络请求更加轻松。它在AFNetworking3.x(NSURLSession)的基础上做了更高的抽象。并且它从YTKNetwork借鉴了些很有启发的思想。

感谢[AFNetworking](https://github.com/AFNetworking/AFNetworking)和[YTKNetwork](https://github.com/yuantiku/YTKNetwork)，你们的开源对于社区是笔无尽的财富。

RBEFireworks架构的设计原则就是一切从简，让你使用起来更加顺手。并且更加像Apple的原生框架，只要对NSURLSession和NSURLRequest用过接触，就可以很快理解框架。它对网络请求抽象成新的对象，提供更高的表达能力，方便于复用和提供更多的功能。

希望你的网络请求像烟火一样，绽放之后留下永恒的回忆。

### 主要功能

- 取消和暂停请求。
- 断点续传下载。
- 上传请求，提供更友好的API发起上传请求。
- 上传和下载的进度回调
- 链式请求，一组相互之间有依赖关系的请求。
- 并发请求，一组相互之间独立的请求。
- 新鲜度缓存，高性能缓存包括内存和数据库，使用LRU淘汰算法。
- 统一预处理请求参数，比如向请求中添加设备类型
- 统一处理请求结果，比如根据业务逻辑判断请求的成败
- 统一设置、处理请求的URL，比如添加后端API版本
- 检查返回数据类型的合法性。
- 支持block和Delegate的回调方式。
- 对请求可以进行拓展，比如加入等候Loading，请求时间打点等。
- 统一处理NSHTTPCookie和NSURLCache。


### 支持

iOS8.0+

### 需要引入的库

libsqlite3.tbd

### 安装

```objective-c
$ pod RBEFireworks
```

------

### 基本配置

使用RBEFireworks前要进行URL基本配置。你可以直接配置服务器的BaseURL，或者服务器使用了CDN的话配置CDN的URL。

```objective-c
    [RBEFireworkAdapter sharedInstance].baseURL = @"DemoProjectBaseURL";
    [RBEFireworkAdapter sharedInstance].CDNURL = @"DemoProjectCDNURL";
```

------

### 基本使用

发起一个GET请求，这里提供的URL是相对URL。

```
    RBEFirework *firework = [[RBEFirework alloc] initWithRelativeURL:@"demo"];
    [firework resume];
```

发起一个POST请求，发起不同的HTTP方法的请求只要使用不同的枚举值就可以了。

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

发起一个链式请求，提供一个请求的数组就可以，链式请求会依数组顺序请求。如果其中的一个请求失败了，后续请求就不会再执行了。

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

发起一个并发请求，除了传递一个请求的数组，还要决定如果一个请求失败，其他请求是否取消，默认为不取消。

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

也可以用下组Delegate回调：

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

### 统一配置

你可以对URL进行统一的过滤，只要实现*RBEURLAdapterProtocol*的*adaptedURL*:方法。

你也可以对请求的参数进行统一的过滤，只要实现*RBEParametersAdapterProtocol*的*adaptedParametersWithOriginalParameters:*方法。

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

然后这样使用：

```objective-c
    //Adapte Parameters
    DemoParametersFilter *paramFilter = [[DemoParametersFilter alloc] init];
    [[RBEFireworkAdapter sharedInstance] addParamterAdapters:paramFilter];
    
    //Adapte URL
    DemoURLFilter *URLFilter = [[DemoURLFilter alloc] init];
    [[RBEFireworkAdapter sharedInstance] addURLAdapters:URLFilter];
```

你还可以统一设置请求的回调成败。根据具体逻辑返回成功、失败或忽略。忽略的话，请求不会调用成功或者失败回调。

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

你还可以通过RBEFireworkAdapter设置Cookie和取出Cookie。

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

### 缓存

RBEFireworks的缓存分为2种，一种为HTTP缓存，一种为Freshness缓存，你可以通过*cachePattern*属性来设置。HTTP缓存是由NSURLCache提供的，基本上就是根据HTTP标准进行缓存。你也可以设置RBEFireworkAdapter的*customCachedURLResponse*来定义如何进行缓存。

Freshness缓存是由RBECache提供的，需要你再设置*cacheFreshnessInSecond*属性来指定缓存的生存时间，以秒为单位。如果缓存在你设置的生存时间内，那么缓存为新鲜的，将使用缓存。如果不在，则为不新鲜的，不会使用缓存。

或者你可以设置*RBECachePatternNone*来指定不使用缓存。默认为不使用缓存。

如果你要使用缓存需要在RBEFireworkAdapter来启用。你需要指定缓存的目录、缓存在内存中的容量、缓存在磁盘上的容量。注意，HTTP缓存在内存中的容量单位是字节，而Freshness缓存在内存中的容量单位为请求的个数。

```objective-c
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    
    //For Freshness Cache
    NSString *freshnessCacheDir = [cacheDirectory stringByAppendingPathComponent:@"FreshnessCache"];
    [[RBEFireworkAdapter sharedInstance] enableCacheWithFreshnessCachePatternDirectory:freshnessCacheDir freshnessMemoryCount:20 freshnessDiskCapacity:10 * 1024 * 1024];
    
    //For HTTP Cache
    NSString *HTTPCacheDir = [cacheDirectory stringByAppendingPathComponent:@"HTTPCache"];
    [[RBEFireworkAdapter sharedInstance] enableCacheWithHTTPCachePatternDirectory:HTTPCacheDir HTTPMemoryCapacity:2 * 1024 * 1024 HTTPDiskCapacity:10 * 1024 * 1024];
```

清除全部缓存或者清除内存缓存。

```objective-c
    //clear memory cache
    [[RBEFireworkAdapter sharedInstance] purgeInMemoryCache];
    //clear memory cache and disk cache
    [[RBEFireworkAdapter sharedInstance] purgeAllCache];
```

你也可以调用RBEFirework的*cachedObject*方法提前取出请求的缓存。

```
    RBEFirework *demoOne = [[RBEFirework alloc] initWithRelativeURL:@"demoOne"];
    id cachedObject = demoOne.cachedObject;
    if (cachedObject) {
        //cache to do...
    }
```

------

### 上传与下载

上传可以直接使用RBEUploadFirework。RBEUploadFirework初始化提供的URL不是相对URL，就是完整的上传URL。上传使用的是AFNetworking实现的mutipart/form-data方式上传。

你可以通过提供文件的URL、上传数据的NSInputStream、上传的NSData、构成multipart/form-data的请求体来上传。

```objective-c
    RBEUploadFirework *upload = [[RBEUploadFirework alloc] initWithUploadURL:@"demo"];
                           [upload uploadWithFileURL:[NSURL URLWithString:@"demoURL"] 
                                                name:@"demo" 
                                            fileName:@"demoFileName" 
                                            mimeType:@"demoMimeType"];
```

下载可以直接使用RBEDownloadFirework。RBEDownloadFirework初始化提供的URL不是相对URL，就是完整的下载URL，并且要提供下载的目的地路径。

Apple原生支持的断点续传，必须要有以下几点要求：

- Get请求
- 服务器支持范围请求
- 请求响应必须提供E-Tag或者Last-Modified或者两者提供

RBEFireworks实现了不需要提供E-Tag或者Last-Modified的下载方式，但仍需要为Get请求和支持范围请求。

所以，你可以设置*isProvideETagOrLastModified*来指定下载方式，默认为YES。

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

成功后，调用*downloadedContentPath*来获得实际的下载下来的路径。如果无法将数据写到你提供的目的路径，就会移动到一个中间临时路径。所以，*downloadedContentPath*返回的路径不一定是你设置的目的路径。

上传和下载都可以通过*progressBlock*来设置进度的回调。

```objective-c
firework.progressBlock = ^(NSProgress *progress) {
        //progress to do...
    };
```

------

### 更多功能

请求的暂停和挂起。

```objective-c
    [firework suspend];
    [firework cancel];
```

如果你想在链式请求中打断链式请求，可以调用*breakChain*方法：

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

你通过*responseValidator*验证服务器端返回数据类型是否与预期相符。将数据名称和数据类型映射起来，如果不符，请求就会失败。

```objective-c
    firework.responseValidator = @[@{@"demoId" : [NSString class],
                                    @"demoTime" : [NSNumber class],
                                    @"demoStuff" : @{
                                            @"demoStuffId" : [NSString class],
                                       @"demoStuffContent" : [NSString class]
                                            }
                                    }];
```

你还可以在请求发出之前、取消之前、挂起之前、执行CompletionBlock之前和执行CompletionBlock之后加入你想做的事情。你要实现*RBEFireworkAccessoryProtocol*协议的任何方法。比如展示Loading：

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

然后这样使用：

```objective-c
    DemoFireworkAccessory *accessory = [DemoFireworkAccessory accessory];
    [firework addAccessory:accessory];
```

你还可以通过*customRequest*创建一个自定义的NSURLRequest来发起请求，这会忽略你对RBEFirework除成功和失败的回调的其他设置。

```objective-c
    firework.customRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"firework"]];
```

你可以通过RBEFireworkAdapter取消掉所有请求。这会调用相应ConfigurationType的NSURLSession的*finishTasksAndInvalidate*方法或invalidateAndCancel方法。

```objective-c
- (void)cancelAllRBEFireworkInConfigurationTpye:(RBESessionConfigurationType)configurationType  allowOutstandingTaskFinish:(BOOL)isAllow;
```

还有一些，你可以控制AFNetworking的设置。

```objective-c
@property (nonatomic, assign) RBEFireworkRequestSerializerType requestSerializerType;

@property (nonatomic, assign) RBEFireworkResponseSerializerType responseSerializerType;

//Default is application/json text/json text/javascript
@property (nonatomic, strong) NSSet<NSString *> *acceptableContentTypes;

//Default is No
@property (nonatomic, assign) BOOL allowInvalidCertificates;
```

第一个是请求序列化的类型，默认为HTTP类型。第二个是相应序列化的类型，默认为JSON。第三个是响应可接受的Content-Type，默认为application/json、text/json、text/javascript。第四个是是否允许无效证书，默认为否。

每个请求还可以有更多的属性可以设置，他们都是直接作用于NSMutableURLRequest。

```objective-c
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) NSURLRequestNetworkServiceType networkServiceType;
@property (nonatomic, assign) BOOL allowsCellularAccess;
@property (nonatomic, assign) BOOL HTTPShouldHandleCookies;
@property (nonatomic, assign) BOOL HTTPShouldUsePipelining;
```

 还可以设置Configuration的类型，请求对应的NSURLSessionConfiguration。

```objective-c
@property (nonatomic, assign) RBESessionConfigurationType sessionConfigurationType;
```

还可以添加Tag

```objective-c
@property (nonatomic, assign) NSInteger tag;
@property (nullable, nonatomic, strong) NSDictionary *userInfo;
```

还可以添加HTTP header

```objective-c
- (void)setAuthenticationHeaderFieldWithUserName:(NSString *)userName password:(NSString *)password;

- (void)setHeaderField:(NSDictionary<NSString *, NSString *> *)headerField;
```

想知道请求的基本信息，直接用NSLog打印RBEFirework就可以。

------

上述代码都可以在项目Demo中找到。

最重要的，玩的愉快！

