//
//  ft_sdk_iosTestUITests.m
//  ft-sdk-iosTestUITests
//
//  Created by 胡蕾蕾 on 2019/12/25.
//  Copyright © 2019 hll. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FTMobileAgent/FTMobileAgent.h>
#import <ZYTrackerEventDBTool.h>
@interface ft_sdk_iosTestUITests : XCTestCase

@end

@implementation ft_sdk_iosTestUITests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
      self.continueAfterFailure = NO;
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
   
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}
- (void)testExample {
   
    // UI tests must launch the application that they test.
    XCUIApplication *app = [[XCUIApplication alloc] init];
    
    [app launch];
    [[ZYTrackerEventDBTool sharedManger] getDatasCount];
    NSLog(@"ZYTrackerEventDBTool == %ld", (long)[[ZYTrackerEventDBTool sharedManger] getDatasCount]);
    
    XCUIElement *element = [[[[[[[[app childrenMatchingType:XCUIElementTypeWindow] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element;
    [[element childrenMatchingType:XCUIElementTypeButton].element tap];
    [element tap];
    [[[app.tables childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:1].staticTexts[@"来点我呀"] tap];
    
    XCUIElementQuery *segmentedControlsQuery = app/*@START_MENU_TOKEN@*/.segmentedControls/*[[".scrollViews.segmentedControls",".segmentedControls"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/;
    [segmentedControlsQuery.buttons[@"第一个"] tap];
    [segmentedControlsQuery.buttons[@"第二个"] tap];
    [segmentedControlsQuery.buttons[@"第三个"] tap];
    
    XCUIElement *labelButton = app.buttons[@"这是一个可以点击的 Label"];
    [labelButton tap];
    [labelButton tap];
    [labelButton tap];
    [labelButton tap];
    /*@START_MENU_TOKEN@*/[labelButton pressForDuration:0.6];/*[["labelButton","["," tap];"," pressForDuration:0.6];"],[[[-1,0,1]],[[1,3],[1,2]]],[0,0]]@END_MENU_TOKEN@*/
    
    XCUIElementQuery *tablesQuery = app.tables;
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"Section: 0, Row: 0"]/*[[".cells.staticTexts[@\"Section: 0, Row: 0\"]",".staticTexts[@\"Section: 0, Row: 0\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"Section: 0, Row: 1"]/*[[".cells.staticTexts[@\"Section: 0, Row: 1\"]",".staticTexts[@\"Section: 0, Row: 1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
    [[app.scrollViews childrenMatchingType:XCUIElementTypeImage].element tap];
  
        
    
    
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"Section: 0, Row: 5"]/*[[".cells.staticTexts[@\"Section: 0, Row: 5\"]",".staticTexts[@\"Section: 0, Row: 5\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
    
    XCUIElement *section0Row6StaticText = tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"Section: 0, Row: 6"]/*[[".cells.staticTexts[@\"Section: 0, Row: 6\"]",".staticTexts[@\"Section: 0, Row: 6\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/;
    [section0Row6StaticText tap];
    [section0Row6StaticText tap];
    
     [[ZYTrackerEventDBTool sharedManger] getDatasCount];
     NSLog(@"end ZYTrackerEventDBTool == %ld", (long)[[ZYTrackerEventDBTool sharedManger] getDatasCount]);
    

   
    
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}
- (void)testBtnClick{
    

}

- (void)testLaunchPerformance {
    if (@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)) {
        // This measures how long it takes to launch your application.
        [self measureWithMetrics:@[XCTOSSignpostMetric.applicationLaunchMetric] block:^{
            [[[XCUIApplication alloc] init] launch];
        }];
    }
}

@end
