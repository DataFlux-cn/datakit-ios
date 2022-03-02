//
//  FTTraceHandlerManager.h
//  FTMobileAgent
//
//  Created by hulilei on 2022/3/2.
//  Copyright © 2022 DataFlux-cn. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class FTResourceContentModel,FTResourceMetricsModel;

@interface FTTraceHandlerManager : NSObject


+ (instancetype)sharedManager;
/**
 * 获取 trace 请求头
 * @param key 请求标识
 */
- (NSDictionary *)getTraceHeaderWithKey:(NSString *)key url:(NSURL *)url;
/**
 * trace 数据添加
 * @param key 请求标识
 * @param content 请求相关数据
 */
- (void)traceWithKey:(NSString *)key content:(FTResourceContentModel *)content;
@end

NS_ASSUME_NONNULL_END
