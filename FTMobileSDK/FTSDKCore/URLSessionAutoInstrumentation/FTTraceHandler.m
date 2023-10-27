//
//  FTTraceHandler.m
//  FTMobileAgent
//
//  Created by 胡蕾蕾 on 2021/10/13.
//  Copyright © 2021 DataFlux-cn. All rights reserved.
//

#import "FTTraceHandler.h"
#import "FTDateUtil.h"
#import "FTTracerProtocol.h"
#import "FTResourceContentModel.h"
#import "FTResourceMetricsModel.h"
@interface FTTraceHandler ()
@end
@implementation FTTraceHandler
-(instancetype)init{
    return [self initWithIdentifier:[NSUUID UUID].UUIDString];
}
-(instancetype)initWithIdentifier:(NSString *)identifier{
    self = [super init];
    if(self){
        _identifier = identifier;
    }
    return self;
}
- (void)taskReceivedData:(NSData *)data{
    if(!self.data){
        self.data = [NSMutableData dataWithData:data];
    }else{
        [self.data appendData:data];
    }
}
- (void)taskReceivedMetrics:(NSURLSessionTaskMetrics *)metrics{
    FTResourceMetricsModel *metricsModel = nil;
    if (metrics) {
        metricsModel = [[FTResourceMetricsModel alloc]initWithTaskMetrics:metrics];
    }
    self.metricsModel = metricsModel;
}
- (void)taskCompleted:(NSURLSessionTask *)task error:(NSError *)error{
    self.error = error;
    self.response = task.response;
    NSHTTPURLResponse *response =(NSHTTPURLResponse *)task.response;
    FTResourceContentModel *model = [[FTResourceContentModel alloc]initWithRequest:task.currentRequest response:response data:self.data error:error];
    self.contentModel = model;
}
@end
