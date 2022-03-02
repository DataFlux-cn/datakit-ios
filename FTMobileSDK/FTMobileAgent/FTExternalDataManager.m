//
//  FTExternalResourceManager.m
//  FTMobileAgent
//
//  Created by 胡蕾蕾 on 2021/11/22.
//  Copyright © 2021 DataFlux-cn. All rights reserved.
//

#import "FTExternalDataManager.h"
#import "FTTraceHandler.h"
#import "FTGlobalRumManager.h"
#import "FTRUMManager.h"
#import "FTNetworkTraceManager.h"
#import "FTResourceContentModel.h"
@interface FTExternalDataManager()
@property (nonatomic, strong) NSMutableDictionary<NSString *,FTTraceHandler *> *traceHandlers;
@property (nonatomic, strong) dispatch_semaphore_t lock;
@end
@implementation FTExternalDataManager
+ (instancetype)sharedManager{
    static dispatch_once_t onceToken;
    static FTExternalDataManager *sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[FTExternalDataManager alloc]init];
    });
    return sharedManager;
}
-(instancetype)init{
    self = [super init];
    if (self) {
        self.lock = dispatch_semaphore_create(1);
        self.traceHandlers = [NSMutableDictionary new];
    }
    return self;
}
#pragma mark - Tracing -

- (NSDictionary *)getTraceHeaderWithKey:(NSString *)key url:(NSURL *)url{
    FTTraceHandler *handler = [self getTraceHandler:key];
    if (!handler) {
        handler = [[FTTraceHandler alloc]initWithUrl:url identifier:key];
        [self setTraceHandler:handler forKey:key];
    }
    return handler.getTraceHeader;
}
- (void)setTraceHandler:(FTTraceHandler *)handler forKey:(NSString *)key{
    dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
    [self.traceHandlers setValue:handler forKey:key];
    dispatch_semaphore_signal(self.lock);
}
- (FTTraceHandler *)getTraceHandler:(NSString *)key{
    FTTraceHandler *handler = nil;
    dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
    if ([self.traceHandlers.allKeys containsObject:key]) {
      handler = self.traceHandlers[key];
    }
    dispatch_semaphore_signal(self.lock);
    return handler;
}
- (void)removeTraceHandlerWithKey:(NSString *)key{
    dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
    [self.traceHandlers removeObjectForKey:key];
    dispatch_semaphore_signal(self.lock);
}
- (void)traceWithKey:(NSString *)key content:(FTResourceContentModel *)content{
    FTTraceHandler *handler = [self getTraceHandler:key];
    if (handler) {
        [handler tracingWithModel:content];
        [self removeTraceHandlerWithKey:key];
    }
}

#pragma mark - Rum -

-(void)startViewWithName:(NSString *)viewName  loadDuration:(NSNumber *)loadDuration{
    [FTGlobalRumManager.sharedInstance.rumManger startViewWithName:viewName loadDuration:loadDuration];
}
-(void)stopView{
    [FTGlobalRumManager.sharedInstance.rumManger stopView];

}
- (void)addActionWithName:(NSString *)actionName actionType:(NSString *)actionType{
    if ([actionType isEqualToString:@"click"]) {
        [FTGlobalRumManager.sharedInstance.rumManger addClickActionWithName:actionName];
    }
}
- (void)addErrorWithType:(NSString *)type message:(NSString *)message stack:(NSString *)stack{
    [FTGlobalRumManager.sharedInstance.rumManger addErrorWithType:type  message:message stack:stack];
}
-(void)addLongTaskWithStack:(NSString *)stack duration:(NSNumber *)duration{
    [FTGlobalRumManager.sharedInstance.rumManger addLongTaskWithStack:stack duration:duration];
}
- (void)startResourceWithKey:(NSString *)key{
    [FTGlobalRumManager.sharedInstance.rumManger startResource:key];
}
- (void)addResourceWithKey:(NSString *)key metrics:(nullable FTResourceMetricsModel *)metrics content:(FTResourceContentModel *)content{
    
    [FTGlobalRumManager.sharedInstance.rumManger addResource:key metrics:metrics content:content];
}
- (void)stopResourceWithKey:(nonnull NSString *)key {
    [FTGlobalRumManager.sharedInstance.rumManger stopResource:key];
}
@end
