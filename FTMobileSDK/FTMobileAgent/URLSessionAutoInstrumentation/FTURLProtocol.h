//
//  FTURLProtocol.h
//  FTMobileAgent
//
//  Created by 胡蕾蕾 on 2020/4/21.
//  Copyright © 2020 hll. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTURLSessionInterceptorProtocol.h"
NS_ASSUME_NONNULL_BEGIN
@interface FTURLProtocol : NSURLProtocol

/// 设置 url 拦截代理
/// - Parameter delegate: url 会话拦截代理
+ (void)setDelegate:(id<FTURLSessionInterceptorDelegate>)delegate;

+ (id<FTURLSessionInterceptorDelegate>)delegate;

/// 开始监控
+ (void)startMonitor;

/// 停止监控
+ (void)stopMonitor;
@end

NS_ASSUME_NONNULL_END
