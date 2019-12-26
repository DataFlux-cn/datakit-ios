//
//  FTNetworkTests.m
//  ft-sdk-iosTestUnitTests
//
//  Created by 胡蕾蕾 on 2019/12/24.
//  Copyright © 2019 hll. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ZYUploadTool.h>
#import <FTMobileAgent/FTMobileAgent.h>
#import <ZYDataBase/ZYTrackerEventDBTool.h>
#import <ZYBaseInfoHander.h>
#import <RecordModel.h>
#import "OHHTTPStubs.h"
@interface FTNetworkTests : XCTestCase
@property (nonatomic, strong) ZYUploadTool *upTool;

@end

@implementation FTNetworkTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
       FTMobileConfig *config = [FTMobileConfig new];
       config.enableRequestSigning = YES;
       config.akSecret = @"accsk";
       config.akId = @"accid";
       config.isDebug = YES;
       config.enableAutoTrack = YES;
       config.metricsUrl = @"http://10.100.64.106:19457/v1/write/metrics";
       long  tm =[ZYBaseInfoHander getCurrentTimestamp];
       self.upTool = [[ZYUploadTool alloc]initWithConfig:config];
//       [self setOHHTTPStubs];
       [[ZYTrackerEventDBTool sharedManger] deleteItemWithTm:tm];
       for (NSInteger i=0; i<100; i++) {
           NSDictionary *data= @{
               @"op" : @"cstm",
               @"opdata" :@{
                       @"field" :@"pushFile",
                       @"tags":@{
                               @"pushVC":@"Test4ViewController",
                   },
               @"values":@{
                          @"event" :@"Gesture",
                   },
               },
           } ;
           RecordModel *model = [RecordModel new];
           model.tm = [ZYBaseInfoHander getCurrentTimestamp];
           model.data =[ZYBaseInfoHander convertToJsonData:data];
           [[ZYTrackerEventDBTool sharedManger] insertItemWithItemData:model];
           
           NSDictionary *data2 = @{
               @"cpn":@"Test4ViewController",
               @"op": @"click",
               @"opdata":@{
                       @"vtp": @"UIWindow[7]/UITransitionView[6]/UIDropShadowView[5]/UILayoutContainerView[4]/UINavigationTransitionView[3]/UIViewControllerWrapperView[2]/UIView[1]/UITableView[0]",
               },
               @"rpn":@"UINavigationController",
           };
           RecordModel *model2 = [RecordModel new];
           model2.tm = [ZYBaseInfoHander getCurrentTimestamp];
           model2.data =[ZYBaseInfoHander convertToJsonData:data2];
           [[ZYTrackerEventDBTool sharedManger] insertItemWithItemData:model2];
       }
       NSInteger count =  [[ZYTrackerEventDBTool sharedManger] getDatasCount];
       NSLog(@"Record Count == %ld",(long)count);
}
- (void)setOHHTTPStubs{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
      return [request.URL.host isEqualToString:@"10.100.64.106"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
      // Stub all those requests with "Hello World!" string
      NSData* stubData = [@"Hello World!" dataUsingEncoding:NSUTF8StringEncoding];
      return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:nil];
    }];
}
- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
          [self.upTool upload];
        // Put the code you want to measure the time of here.
    }];
}

@end
