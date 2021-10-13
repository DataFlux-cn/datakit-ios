//
//  FTMonitorManager.m
//  FTMobileAgent
//
//  Created by 胡蕾蕾 on 2020/4/14.
//  Copyright © 2020 hll. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif
#import "FTMonitorManager.h"
#import "FTBaseInfoHander.h"
#import "FTMobileConfig.h"
#import "FTURLProtocol.h"
#import "FTLog.h"
#import "FTMonitorUtils.h"
#import "FTConstants.h"
#import "FTURLProtocol.h"
#import "FTMobileAgent+Private.h"
#import "NSURLRequest+FTMonitor.h"
#import "NSURLResponse+FTMonitor.h"
#import "NSString+FTAdd.h"
#import "FTDateUtil.h"
#import "FTWKWebViewHandler.h"
#import "FTANRDetector.h"
#import "FTJSONUtil.h"
#import "FTCallStack.h"
#import "FTWeakProxy.h"
#import "FTPingThread.h"
#import "FTNetworkTrace.h"
#import "FTTaskInterceptionModel.h"
#import "FTWKWebViewJavascriptBridge.h"
#import "FTTrack.h"
#import "UIViewController+FTAutoTrack.h"
#import "FTUncaughtExceptionHandler.h"
#import "FTAppLifeCycle.h"
@interface FTMonitorManager ()<FTHTTPProtocolDelegate,FTANRDetectorDelegate,FTWKWebViewTraceDelegate,FTAppLifeCycleDelegate>
@property (nonatomic, strong) FTWKWebViewHandler *webViewHandler;
@property (nonatomic, strong) FTPingThread *pingThread;
@property (nonatomic, strong) FTNetworkTrace *trace;
@property (nonatomic, strong) FTMobileConfig *config;
@property (nonatomic, strong) FTTraceConfig *traceConfig;
@property (nonatomic, strong) FTRumConfig *rumConfig;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) FTWKWebViewJavascriptBridge *jsBridge;
@property (nonatomic, strong) FTTrack *track;
@property (nonatomic, assign) CFTimeInterval launch;
@property (nonatomic, strong) NSDate *launchTime;
@end

@implementation FTMonitorManager{
    BOOL _appRelaunched;          // App 从后台恢复
    //进入非活动状态，比如双击 home、系统授权弹框
    BOOL _applicationWillResignActive;
    BOOL _applicationLoadFirstViewController;
    
}
static FTMonitorManager *sharedInstance = nil;
static dispatch_once_t onceToken;
-(instancetype)init{
    self = [super init];
    if (self) {
        _running = NO;
        _appRelaunched = NO;
        _launchTime = [NSDate date];
        _track = [[FTTrack alloc]init];
        [self startMonitorNetwork];
        [[FTAppLifeCycle sharedInstance] addAppLifecycleDelegate:self];
    }
    return self;
}
+ (instancetype)sharedInstance {
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });
    return sharedInstance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return self;
}
-(void)setMobileConfig:(FTMobileConfig *)config{
    _config = config;
}
-(void)setRumConfig:(FTRumConfig *)rumConfig{
    _rumConfig = rumConfig;
    if (self.rumConfig.appid.length<=0) {
        ZYErrorLog(@"RumConfig appid 数据格式有误，未能开启 RUM");
        return;
    }
    self.rumManger = [[FTRUMManager alloc]initWithRumConfig:rumConfig];
    if(rumConfig.enableTrackAppCrash){
        [FTUncaughtExceptionHandler sharedHandler];
    }
    //采集view、resource、jsBridge
    dispatch_async(dispatch_get_main_queue(), ^{
        if (rumConfig.enableTrackAppFreeze) {
            [self startPingThread];
        }else{
            [self stopPingThread];
        }
        if (rumConfig.enableTrackAppANR) {
            [FTANRDetector sharedInstance].delegate = self;
            [[FTANRDetector sharedInstance] startDetecting];
        }else{
            [[FTANRDetector sharedInstance] stopDetecting];
        }
    });
    
}
-(void)setTraceConfig:(FTTraceConfig *)traceConfig{
    self.trace = [[FTNetworkTrace alloc]initWithType:traceConfig.networkTraceType];
    _traceConfig = traceConfig;
    [FTWKWebViewHandler sharedInstance].enableTrace = YES;
}
-(FTPingThread *)pingThread{
    if (!_pingThread || _pingThread.isCancelled) {
        _pingThread = [[FTPingThread alloc]init];
        __weak typeof(self) weakSelf = self;
        _pingThread.block = ^(NSString * _Nonnull stackStr, NSDate * _Nonnull startDate, NSDate * _Nonnull endDate) {
            [weakSelf trackAppFreeze:stackStr duration:[FTDateUtil nanosecondtimeIntervalSinceDate:startDate toDate:endDate]];
        };
    }
    return _pingThread;
}
-(void)startPingThread{
    if (!self.pingThread.isExecuting) {
        [self.pingThread start];
    }
}
-(void)stopPingThread{
    if (_pingThread && _pingThread.isExecuting) {
        [self.pingThread cancel];
    }
}
- (void)trackAppFreeze:(NSString *)stack duration:(NSNumber *)duration{
    NSMutableDictionary *fields = @{@"duration":duration}.mutableCopy;
    
    fields[@"long_task_stack"] = stack;
    [self.rumManger addLongTask:@{} field:fields];
}
-(void)stopMonitor{
    [FTURLProtocol stopMonitor];
    [self stopPingThread];
}
- (void)startMonitorNetwork{
    [FTURLProtocol startMonitor];
    FTWeakProxy *weakProxy = [FTWeakProxy proxyWithTarget:self];
    [FTURLProtocol setDelegate:weakProxy];
    //js
    [FTWKWebViewHandler sharedInstance].traceDelegate = self;
}
#pragma mark ==========FTHTTPProtocolDelegate 时间/错误率 ==========
- (void)ftTaskCreateWith:(FTTaskInterceptionModel *)taskModel{
    [self.rumManger resourceStart:taskModel.identifier];
}
- (void)ftTaskInterceptionCompleted:(FTTaskInterceptionModel *)taskModel{
    @try {
        // network trace
        if ([FTBaseInfoHander randomSampling:self.traceConfig.samplerate]) {
            [self networkTraceWithTask:taskModel.task didFinishCollectingMetrics:taskModel.metrics didCompleteWithError:taskModel.error];
        }
        // rum resourc
        if (self.rumManger) {
            if (self.traceConfig.enableLinkRumData && self.traceConfig.networkTraceType == FTNetworkTraceTypeDDtrace) {
                [taskModel.task.originalRequest ft_getNetworkTraceingDatas:^(NSString * _Nonnull traceId, NSString * _Nonnull spanID, BOOL sampled) {
                    if(traceId && spanID){
                        NSDictionary *linkTag = @{@"span_id":spanID,
                                                  @"trace_id":traceId
                        };
                        taskModel.linkTags = linkTag;
                    }
                }];
            }
            [self.rumManger ftResourceCompleted:taskModel];
        }
    }@catch (NSException *exception) {
        ZYErrorLog(@"exception %@",exception);
    }
}
// 网络请求信息采集 链路追踪
- (void)networkTraceWithTask:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics didCompleteWithError:(NSError *)error{
    __block NSString *trace,*span;
    __block BOOL sampling;
    [self.trace  getTraceingDatasWithRequestHeaderFields:task.originalRequest.allHTTPHeaderFields handler:^(NSString * _Nonnull traceId, NSString * _Nonnull spanID, BOOL sampled) {
        trace = traceId;
        span = spanID;
        sampling = sampled;
    }];
    if(!trace||!span||!sampling){
        return;
    }
    NSURLSessionTaskTransactionMetrics *taskMes = [metrics.transactionMetrics lastObject];
    
    FTStatus status = FTStatusOk;
    NSDictionary *responseDict = @{};
    if (error) {
        status = FTStatusError;
        NSString *errorDescription=[[error.userInfo allKeys] containsObject:@"NSLocalizedDescription"]?error.userInfo[@"NSLocalizedDescription"]:@"";
        NSNumber *errorCode = [task.response ft_getResponseStatusCode]?[task.response ft_getResponseStatusCode]:[NSNumber numberWithInteger:error.code];
        
        responseDict = @{FT_NETWORK_HEADERS:@{},
                         FT_NETWORK_ERROR:@{@"errorCode":[NSNumber numberWithInteger:error.code],
                                            
                                            @"errorDomain":error.domain,
                                            
                                            @"errorDescription":errorDescription,
                                            
                         },
                         FT_NETWORK_CODE:errorCode,
        };
    }else{
        if( [[task.response ft_getResponseStatusCode] integerValue] >=400){
            status = FTStatusError;
        }
        responseDict = task.response?[task.response ft_getResponseDict]:@{};
    }
    NSString *statusStr = [FTBaseInfoHander statusStrWithStatus:status];
    
    NSMutableDictionary *request = [task.currentRequest ft_getRequestContentDict].mutableCopy;
    NSDictionary *response = responseDict?responseDict:@{};
    NSDictionary *content = @{
        FT_NETWORK_RESPONSE_CONTENT:response,
        FT_NETWORK_REQUEST_CONTENT:request
    };
    NSString *opreation = [task.originalRequest ft_getOperationName];
    NSMutableDictionary *tags = @{FT_KEY_OPERATION:opreation,
                                  FT_TRACING_STATUS:statusStr,
                                  FT_KEY_SPANTYPE:FT_SPANTYPE_ENTRY,
                                  FT_TYPE_RESOURCE:opreation,
                                  FT_TYPE:@"custom",
                                  
    }.mutableCopy;
    NSDictionary *field = @{FT_KEY_DURATION:[NSNumber numberWithInt:[metrics.taskInterval duration]*1000000]};
    
    [tags setValue:trace forKey:FT_FLOW_TRACEID];
    [tags setValue:span forKey:FT_KEY_SPANID];
    [[FTMobileAgent sharedInstance] tracing:[FTJSONUtil convertToJsonData:content] tags:tags field:field tm:[FTDateUtil dateTimeNanosecond:taskMes.requestStartDate]];
}
#pragma mark == FTWKWebViewDelegate ==
/**
 * KWebView  网络请求信息采集
 * wkwebview 使用loadRequest 与 reload 发起的请求
 */
- (void)ftWKWebViewTraceRequest:(NSURLRequest *)request response:(NSURLResponse *)response startDate:(NSDate *)start taskDuration:(NSNumber *)duration error:(NSError *)error{
    __block NSString *trace,*span;
    __block BOOL sampling;
    [self.trace  getTraceingDatasWithRequestHeaderFields:request.allHTTPHeaderFields handler:^(NSString * _Nonnull traceId, NSString * _Nonnull spanID, BOOL sampled) {
        trace = traceId;
        span = spanID;
        sampling = sampled;
    }];
    if(!trace||!span||!sampling){
        return;
    }
    FTStatus status = FTStatusOk;
    NSDictionary *responseDict = @{};
    if (error) {
        status = FTStatusError;
        NSString *errorDescription=[[error.userInfo allKeys] containsObject:@"NSLocalizedDescription"]?error.userInfo[@"NSLocalizedDescription"]:@"";
        NSNumber *errorCode = [NSNumber numberWithInteger:error.code];
        responseDict = @{FT_NETWORK_HEADERS:@{},
                         FT_NETWORK_BODY:@{},
                         FT_NETWORK_ERROR:@{@"errorCode":[NSNumber numberWithInteger:error.code],
                                            @"errorDomain":error.domain,
                                            @"errorDescription":errorDescription,
                         },
                         FT_NETWORK_CODE:errorCode,
        };
    }else{
        if( [[response ft_getResponseStatusCode] integerValue] >=400){
            status = FTStatusError;
        }
        responseDict = response?[response ft_getResponseDict]:responseDict;
    }
    NSString *statusStr = [FTBaseInfoHander statusStrWithStatus:status];
    NSMutableDictionary *requestDict = [request ft_getRequestContentDict].mutableCopy;
    NSDictionary *responseDic = responseDict?responseDict:@{};
    NSDictionary *content = @{
        FT_NETWORK_RESPONSE_CONTENT:responseDic,
        FT_NETWORK_REQUEST_CONTENT:requestDict
    };
    NSString *opreation = [request ft_getOperationName];
    NSMutableDictionary *tags = @{FT_KEY_OPERATION:opreation,
                                  FT_TRACING_STATUS:statusStr,
                                  FT_KEY_SPANTYPE:FT_SPANTYPE_ENTRY,
                                  FT_TYPE_RESOURCE:opreation,
                                  FT_TYPE:@"custom",
    }.mutableCopy;
    NSDictionary *field = @{FT_KEY_DURATION:duration};
    [tags setValue:trace forKey:FT_FLOW_TRACEID];
    [tags setValue:span forKey:FT_KEY_SPANID];
    [[FTMobileAgent sharedInstance] tracing:[FTJSONUtil convertToJsonData:content] tags:tags field:field tm:[FTDateUtil dateTimeNanosecond:start]];
}
#pragma mark ========== jsBridge ==========
-(void)ftAddScriptMessageHandlerWithWebView:(WKWebView *)webView{
    if (![webView isKindOfClass:[WKWebView class]]) {
        return;
    }
    self.jsBridge = [FTWKWebViewJavascriptBridge bridgeForWebView:webView];
    [self.jsBridge registerHandler:@"sendEvent" handler:^(id data, WVJBResponseCallback responseCallback) {
        [self dealReceiveScriptMessage:data callBack:responseCallback];
    }];
}
- (void)dealReceiveScriptMessage:(id )message callBack:(WVJBResponseCallback)callBack{
    @try {
        NSDictionary *messageDic = [FTJSONUtil dictionaryWithJsonString:message];
        if (![messageDic isKindOfClass:[NSDictionary class]]) {
            ZYErrorLog(@"Message body is formatted failure from JS SDK");
            return;
        }
        NSString *name = messageDic[@"name"];
        if ([name isEqualToString:@"rum"]||[name isEqualToString:@"track"]||[name isEqualToString:@"log"]||[name isEqualToString:@"trace"]) {
            NSDictionary *data = messageDic[@"data"];
            NSString *measurement = data[@"measurement"];
            NSDictionary *tags = data[@"tags"];
            NSDictionary *fields = data[@"fields"];
            long long time = [data[@"time"] longLongValue];
            time = time>0?:[FTDateUtil currentTimeNanosecond];
            if (measurement && fields.count>0) {
                if ([name isEqualToString:@"rum"]) {
                    [self.rumManger addWebviewData:measurement tags:tags fields:fields tm:time];
                }else if([name isEqualToString:@"track"]){
                }else if([name isEqualToString:@"log"]){
                    //数据格式需要调整
                }else if([name isEqualToString:@"trace"]){
                    
                }
            }
        }
    } @catch (NSException *exception) {
        ZYErrorLog(@"%@ error: %@", self, exception);
    }
}
#pragma mark ========== FTANRDetectorDelegate ==========
- (void)onMainThreadSlowStackDetected:(NSString*)slowStack{
    NSMutableDictionary *fields = @{@"duration":[NSNumber numberWithLongLong:MXRMonitorRunloopOneStandstillMillisecond*MXRMonitorRunloopStandstillCount*1000000]}.mutableCopy;
    fields[@"long_task_stack"] = slowStack;
    [self.rumManger addLongTask:@{} field:fields];
}
#pragma mark ========== FTNetworkTrace ==========
- (BOOL)isTraceUrl:(NSURL *)url{
    if (self.config.metricsUrl) {
        return ![url.host isEqualToString:[NSURL URLWithString:self.config.metricsUrl].host];
    }
    return NO;
}
- (NSDictionary *)getTraceHeaderWithUrl:(NSURL *)url{
    if ([self isTraceUrl:url]) {
        BOOL sample = [FTBaseInfoHander randomSampling:self.traceConfig.samplerate];
        return [self.trace networkTrackHeaderWithSampled:sample url:url];
    }else{
        return nil;
    }
}
- (void)tracingWithContent:(NSString *)content tags:(NSDictionary *)tags fields:(NSDictionary *)fields headerFields:(NSDictionary *)headerFields time:(NSDate *)time{
    if (!headerFields) {
        return;
    }
    __block NSString *trace,*span;
    __block BOOL sampling;
    [self.trace  getTraceingDatasWithRequestHeaderFields:headerFields handler:^(NSString * _Nonnull traceId, NSString * _Nonnull spanID, BOOL sampled) {
        trace = traceId;
        span = spanID;
        sampling = sampled;
    }];
    if(trace&&span&&sampling){
        NSMutableDictionary *newTags = [NSMutableDictionary dictionaryWithDictionary:tags];
        [newTags setValue:trace forKey:FT_FLOW_TRACEID];
        [newTags setValue:span forKey:FT_KEY_SPANID];
        [[FTMobileAgent sharedInstance] tracing:content tags:newTags field:fields tm:[FTDateUtil dateTimeNanosecond:time]];
    }
}
#pragma mark ========== AUTO TRACK ==========
- (void)applicationWillEnterForeground{
    if (_appRelaunched){
        self.launchTime = [NSDate date];
    }
}
- (void)applicationDidBecomeActive{
    @try {
        if (_applicationWillResignActive) {
            _applicationWillResignActive = NO;
            return;
        }
        _running = YES;
        if (!_applicationLoadFirstViewController) {
            return;
        }
        NSString *viewid = [NSUUID UUID].UUIDString;
        self.currentController.ft_viewUUID = viewid;
        [self.rumManger startView:self.currentController];
        
        [self.rumManger addLaunch:_appRelaunched duration:[FTDateUtil nanosecondtimeIntervalSinceDate:self.launchTime toDate:[NSDate date]]];
        
    }
    @catch (NSException *exception) {
        ZYErrorLog(@"exception %@",exception);
    }
}
- (void)applicationDidEnterBackground{
    if (!_applicationWillResignActive) {
        return;
    }
    _running = NO;
    [self.rumManger startView:self.currentController];
    _applicationWillResignActive = NO;
}
- (void)applicationWillResignActive{
    @try {
        _applicationWillResignActive = YES;
    }
    @catch (NSException *exception) {
        ZYErrorLog(@"applicationWillResignActive exception %@",exception);
    }
}
- (void)applicationWillTerminateNotification{
    @try {
        [self.rumManger stopView:self.currentController];
        [self.rumManger applicationWillTerminate];
        
    }@catch (NSException *exception) {
        ZYErrorLog(@"applicationWillResignActive exception %@",exception);
    }
}
- (void)trackViewDidAppear:(UIViewController *)viewController{
    
    [self.rumManger startView:viewController];
    //记录冷启动 是在第一个页面显示出来后
    if (!_applicationLoadFirstViewController) {
        _applicationLoadFirstViewController = YES;
        [self.rumManger addLaunch:_appRelaunched duration:[FTDateUtil nanosecondtimeIntervalSinceDate:self.launchTime toDate:[NSDate date]]];
        _appRelaunched = YES;
    }
}
- (void)trackViewDidDisappear:(UIViewController *)viewController{
    if(self.currentController == viewController){
        [self.rumManger stopView:viewController];
    }
}

#pragma mark ========== 注销 ==========
- (void)resetInstance{
    _config = nil;
    _rumManger = nil;
    onceToken = 0;
    sharedInstance =nil;
    [FTWKWebViewHandler sharedInstance].enableTrace = NO;
    [[FTANRDetector sharedInstance] stopDetecting];
    [self stopMonitor];
}
@end
