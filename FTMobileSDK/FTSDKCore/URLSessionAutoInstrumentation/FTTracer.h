//
//  FTTracer.h
//  FTMobileAgent
//
//  Created by 胡蕾蕾 on 2021/3/17.
//  Copyright © 2021 hll. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTTracerProtocol.h"
#import "FTEnumConstant.h"
NS_ASSUME_NONNULL_BEGIN

/// 具体实现 trace 功能，请求头添加参数实现
@interface FTTracer : NSObject<FTTracerProtocol>
/// 设置 trace 配置
/// - Parameters:
///   - sampleRate: 采样率
///   - traceType: 链路追踪类型
///   - link: 是否关联 rum
- (void)startWithSampleRate:(int)sampleRate traceType:(NetworkTraceType)traceType enableLinkRumData:(BOOL)link;
- (void)shutDown;
#if FTSDKUNITTEST
-(NSUInteger)getSkywalkingSeq;
#endif

@end

NS_ASSUME_NONNULL_END
