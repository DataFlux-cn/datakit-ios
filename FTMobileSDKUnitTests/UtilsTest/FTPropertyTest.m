//
//  FTPropertyTest.m
//  FTMobileSDKUnitTests
//
//  Created by 胡蕾蕾 on 2020/9/18.
//  Copyright © 2020 hll. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FTMobileAgent.h"
#import "FTTrackerEventDBTool.h"
#import "FTBaseInfoHandler.h"
#import "FTRecordModel.h"
#import "FTMobileAgent+Private.h"
#import "FTConstants.h"
#import "FTDateUtil.h"
#import <objc/runtime.h>
#import <FTJSONUtil.h>
#import "NSString+FTAdd.h"
#import "FTPresetProperty.h"
#import "FTTrackDataManager+Test.h"
#import "FTRequest.h"
#import "FTNetworkManager.h"
#import "FTModelHelper.h"
#import "FTGlobalRumManager.h"
#import "FTRUMManager.h"
@interface FTPropertyTest : XCTestCase
@property (nonatomic, strong) FTMobileConfig *config;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *appid;
@end

@implementation FTPropertyTest

- (void)setUp {
    /**
     * 设置 ft-sdk-iosTestUnitTests 的 Environment Variables
     * 额外 添加 isUnitTests = 1 防止 SDK 在 AppDelegate 启动 对单元测试造成影响
     */
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    self.url = [processInfo environment][@"ACCESS_SERVER_URL"];
    self.appid = [processInfo environment][@"APP_ID"];
    [[FTTrackerEventDBTool sharedManger] deleteItemWithTm:[FTDateUtil currentTimeNanosecond]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSetEmptyEnv{
    FTMobileConfig *config = [[FTMobileConfig alloc]initWithMetricsUrl:self.url];
    [FTMobileAgent startWithConfigOptions:config];
    NSDictionary *dict = [[FTMobileAgent sharedInstance].presetProperty rumPropertyWithTerminal:FT_TERMINAL_APP];
    NSString *env = dict[@"env"];
    XCTAssertTrue([env isEqualToString:@"prod"]);
    [[FTMobileAgent sharedInstance] resetInstance];
}
- (void)testSetEnv{
    FTMobileConfig *config = [[FTMobileConfig alloc]initWithMetricsUrl:self.url];
    config.env = FTEnvPre;
    [FTMobileAgent startWithConfigOptions:config];
    NSDictionary *dict = [[FTMobileAgent sharedInstance].presetProperty rumPropertyWithTerminal:FT_TERMINAL_APP];
    NSString *env = dict[@"env"];
    XCTAssertTrue([env isEqualToString:@"pre"]);
    [[FTMobileAgent sharedInstance] resetInstance];
}
/**
 * url 为 空字符串
 * 验证标准：url为空字符串时 FTMobileAgent 调用  - startWithConfigOptions： 会崩溃 为 true
 */
- (void)testSetEmptyUrl{
    FTMobileConfig *config = [[FTMobileConfig alloc]initWithMetricsUrl:@""];
    
    XCTAssertThrows([FTMobileAgent startWithConfigOptions:config]);
}
- (void)testIllegalUrl{
    XCTestExpectation *expect = [self expectationWithDescription:@"请求超时timeout!"];
    FTMobileConfig *config = [[FTMobileConfig alloc]initWithMetricsUrl:[NSString stringWithFormat:@"%@11",self.url]];
    [FTMobileAgent startWithConfigOptions:config];
    FTLoggerConfig *logger = [[FTLoggerConfig alloc]init];
    logger.enableCustomLog = YES;
    [[FTMobileAgent sharedInstance] startLoggerWithConfigOptions:logger];
    [[FTMobileAgent sharedInstance] logging:@"testIllegalUrl" status:FTStatusInfo];
    [[FTMobileAgent sharedInstance] syncProcess];
    [[FTTrackerEventDBTool sharedManger]insertCacheToDB];
    FTRecordModel *model = [[[FTTrackerEventDBTool sharedManger] getAllDatas] lastObject];
    FTRequest *request = [FTRequest createRequestWithEvents:@[model] type:FT_DATA_TYPE_LOGGING];
    [[FTNetworkManager sharedInstance] sendRequest:request completion:^(NSHTTPURLResponse * _Nonnull httpResponse, NSData * _Nullable data, NSError * _Nullable error) {
    
        NSInteger statusCode = httpResponse.statusCode;
        BOOL success = (statusCode >=200 && statusCode < 500);
        XCTAssertTrue(!success);
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:45 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}
/**
 * 设置 appid 后 Rum 开启
 * 验证： Rum 数据能正常写入
 */
- (void)testSetAppid{
    FTMobileConfig *config = [[FTMobileConfig alloc]initWithMetricsUrl:self.url];
    FTRumConfig *rumConfig = [[FTRumConfig alloc]initWithAppid:_appid];
    rumConfig.enableTraceUserAction = YES;
    [FTMobileAgent startWithConfigOptions:config];
    [[FTMobileAgent sharedInstance] startRumWithConfigOptions:rumConfig];
    [[FTTrackerEventDBTool sharedManger] deleteItemWithTm:[FTDateUtil currentTimeNanosecond]];
    NSArray *oldArray =[[FTTrackerEventDBTool sharedManger] getFirstRecords:10 withType:FT_DATA_TYPE_RUM];
    [self addRumData];
    [[FTGlobalRumManager sharedInstance].rumManager syncProcess];
    NSArray *newArray = [[FTTrackerEventDBTool sharedManger] getFirstRecords:10 withType:FT_DATA_TYPE_RUM];
    XCTAssertTrue(newArray.count>oldArray.count);
    [[FTMobileAgent sharedInstance] resetInstance];
}
/**
 * 未设置 appid  Rum 关闭
 * 验证： Rum 数据不能正常写入
 */
-(void)testSetEmptyAppid{
    FTMobileConfig *config = [[FTMobileConfig alloc]initWithMetricsUrl:self.url];
    FTRumConfig *rumConfig = [[FTRumConfig alloc]init];
    rumConfig.enableTraceUserAction = YES;
    [FTMobileAgent startWithConfigOptions:config];
    XCTAssertThrows([[FTMobileAgent sharedInstance] startRumWithConfigOptions:rumConfig]);
    [[FTTrackerEventDBTool sharedManger] deleteItemWithTm:[FTDateUtil currentTimeNanosecond]];
    NSArray *oldArray =[[FTTrackerEventDBTool sharedManger] getFirstRecords:10 withType:FT_DATA_TYPE_RUM];
    [self addRumData];
    [[FTGlobalRumManager sharedInstance].rumManager syncProcess];
    NSArray *newArray = [[FTTrackerEventDBTool sharedManger] getFirstRecords:10 withType:FT_DATA_TYPE_RUM];
    XCTAssertTrue(newArray.count == oldArray.count);
    [[FTMobileAgent sharedInstance] resetInstance];
}
- (void)addRumData{
    [FTModelHelper startView];
    [FTModelHelper addAction];
    [FTModelHelper addAction];
}
@end
