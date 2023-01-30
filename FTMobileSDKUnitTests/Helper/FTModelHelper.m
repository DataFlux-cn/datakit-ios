//
//  FTModelHelper.m
//  FTMobileSDKUnitTests
//
//  Created by hulilei on 2022/4/14.
//  Copyright © 2022 DataFlux-cn. All rights reserved.
//

#import "FTModelHelper.h"
#import <FTConstants.h>
#import <FTDateUtil.h>
#import <FTEnumConstant.h>
#import <FTMobileConfig.h>
#import "FTExternalDataManager.h"

@implementation FTModelHelper
+ (FTRecordModel *)createLogModel{
    return  [FTModelHelper createLogModel:[FTDateUtil currentTimeGMT]];
}
+ (FTRecordModel *)createLogModel:(NSString *)message{
    NSDictionary *filedDict = @{FT_KEY_MESSAGE:message,
    };
    NSDictionary *tagDict = @{FT_KEY_STATUS:FTStatusStringMap[FTStatusInfo]};

    FTRecordModel *model = [[FTRecordModel alloc]initWithSource:FT_LOGGER_SOURCE op:FT_DATA_TYPE_LOGGING tags:tagDict fields:filedDict tm:[FTDateUtil currentTimeNanosecond]];
    return model;
}
+ (FTRecordModel *)createRumModel{
    NSDictionary *field = @{ FT_RUM_KEY_ERROR_MESSAGE:@"rum_model_create",
                             FT_RUM_KEY_ERROR_STACK:@"rum_model_create",
    };
    NSDictionary *tags = @{
        FT_RUM_KEY_ERROR_TYPE:@"ios_crash",
        FT_RUM_KEY_ERROR_SOURCE:@"logger",
        FT_RUM_KEY_ERROR_SITUATION:AppStateStringMap[AppStateRun],
        FT_RUM_KEY_SESSION_ID:[NSUUID UUID].UUIDString,
        FT_RUM_KEY_SESSION_TYPE:@"user",
    };
    FTRecordModel *model = [[FTRecordModel alloc]initWithSource:FT_MEASUREMENT_RUM_ERROR op:FT_DATA_TYPE_RUM tags:tags fields:field tm:[FTDateUtil currentTimeNanosecond]];
    return model;
}
+ (FTRecordModel *)createWrongFormatRumModel{
    NSDictionary *tags = @{
        FT_RUM_KEY_ERROR_TYPE:@"ios_crash",
        FT_RUM_KEY_ERROR_SOURCE:@"logger",
        FT_RUM_KEY_ERROR_SITUATION:AppStateStringMap[AppStateRun],
        FT_RUM_KEY_SESSION_ID:[NSUUID UUID].UUIDString,
        FT_RUM_KEY_SESSION_TYPE:@"user",
    };
    FTRecordModel *model = [[FTRecordModel alloc]initWithSource:FT_MEASUREMENT_RUM_ERROR op:FT_DATA_TYPE_RUM tags:tags fields:nil tm:[FTDateUtil currentTimeNanosecond]];
    return model;
}
+ (void)startView{
    [FTModelHelper startView:nil];
}
+ (void)startView:(NSDictionary *)context{
    NSString *viewName = [NSString stringWithFormat:@"view%@",[NSUUID UUID].UUIDString];
    [[FTExternalDataManager sharedManager] onCreateView:viewName loadTime:@1000000000];
    [[FTExternalDataManager sharedManager] startViewWithName:viewName property:context];
}

+ (void)stopView{
    [[FTExternalDataManager sharedManager] stopView];
}
+ (void)stopView:(NSDictionary *)context{
    [[FTExternalDataManager sharedManager] stopViewWithProperty:context];
}
+ (void)addAction{
    [[FTExternalDataManager sharedManager] addClickActionWithName:@"testActionClick" property:nil];
}
+ (void)addActionWithType:(NSString *)type{
    [[FTExternalDataManager sharedManager] addActionName:@"testActionClick2" actionType:type property:nil];
}
+ (void)addActionWithContext:(NSDictionary *)context{
    [[FTExternalDataManager sharedManager] addClickActionWithName:@"testActionWithContext" property:context];
}
@end
