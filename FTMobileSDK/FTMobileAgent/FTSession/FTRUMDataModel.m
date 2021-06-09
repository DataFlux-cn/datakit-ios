//
//  FTRUMDataModel.m
//  FTMobileAgent
//
//  Created by 胡蕾蕾 on 2021/5/25.
//  Copyright © 2021 hll. All rights reserved.
//

#import "FTRUMDataModel.h"


@implementation FTRUMSessionModel

-(instancetype)initWithSessionID:(NSString *)sessionid{
    self = [super init];
    if (self) {
        self.session_id = sessionid;
        self.session_type = @"user";
    }
    return  self;
}

@end
@implementation FTRUMDataModel
-(instancetype)initWithType:(FTRUMDataType)type time:(NSDate *)time{
    self = [super init];
    if (self) {
        self.time = time;
        self.type = type;
    }
    return self;
}
@end
@implementation FTRUMViewModel
-(instancetype)initWithViewID:(NSString *)viewid viewName:(NSString *)viewName viewReferrer:(NSString *)viewReferrer{
    self = [super init];
    if (self) {
        self.view_id = viewid;
        self.view_name = viewName;
        self.view_referrer = viewReferrer;
    }
    return self;
}

@end
@implementation FTRUMActionModel

-(instancetype)initWithActionID:(NSString *)actionid actionName:(NSString *)actionName actionType:(nonnull NSString *)actionType{
    self = [super init];
    if (self) {
        self.action_id = actionid;
        self.action_name = actionName;
        self.action_type = actionType;
    }
    return self;
}

@end
@implementation FTRUMResourceDataModel

-(instancetype)initWithType:(FTRUMDataType)type identifier:(NSString *)identifier{
    self = [super initWithType:type time:[NSDate date]];
    if (self) {
        self.identifier = identifier;
    }
    return self;
}
    
@end
@implementation FTRUMLaunchDataModel
-(instancetype)initWithType:(FTRUMDataType)type duration:(NSNumber *)duration{
    self = [super initWithType:type time:[NSDate date]];
    if (self) {
        self.duration = duration;
    }
    return self;
}
@end

@implementation FTRUMWebViewData

-(instancetype)initWithMeasurement:(NSString *)measurement tm:(long long )tm{
    self = [super initWithType:FTRUMDataWebViewJSBData time:[NSDate date]];
    if (self) {
        self.measurement = measurement;
        self.tm = tm;
    }
    return self;
}

@end
