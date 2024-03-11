//
//  FTLog.h
//  FTMobileAgent
//
//  Created by 胡蕾蕾 on 2020/5/19.
//  Copyright © 2020 hll. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/// SDK 内部调试日志
@interface FTLog : NSObject

/// 单例
+ (instancetype)sharedInstance;

/// 将调试日志写入文件。若未指定 logsDirectory ，那么将在应用程序的缓存目录中创建一个名为 'FTLogs' 的文件夹。
/// - Parameter logsDirectory: 存储日志文件的文件夹
- (void)registerInnerLogCacheToLogsDirectory:(nullable NSString *)logsDirectory;
@end

NS_ASSUME_NONNULL_END
