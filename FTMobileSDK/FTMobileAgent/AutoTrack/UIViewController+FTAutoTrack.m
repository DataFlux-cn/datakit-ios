//
//  UIViewController+FT_RootVC.m
//  FTAutoTrack
//
//  Created by 胡蕾蕾 on 2019/12/2.
//  Copyright © 2019 hll. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif
#import "UIViewController+FTAutoTrack.h"
#import <objc/runtime.h>
#import "FTConstants.h"
#import "BlacklistedVCClassNames.h"
#import "FTLog+Private.h"
#import "FTTrack.h"
#import "NSDate+FTUtil.h"
#import "FTBaseInfoHandler.h"
static char *viewLoadStartTimeKey = "viewLoadStartTimeKey";
static char *viewControllerUUID = "viewControllerUUID";
static char *viewLoadDuration = "viewLoadDuration";
static char *ignoredLoad = "ignoredLoad";

@implementation UIViewController (FTAutoTrack)
-(void)setFt_viewLoadStartTime:(NSDate*)viewLoadStartTime{
    objc_setAssociatedObject(self, &viewLoadStartTimeKey, viewLoadStartTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(NSDate *)ft_viewLoadStartTime{
    return objc_getAssociatedObject(self, &viewLoadStartTimeKey);
}
-(NSNumber *)ft_loadDuration{
    return objc_getAssociatedObject(self, &viewLoadDuration);
}
-(void)setFt_loadDuration:(NSNumber *)ft_loadDuration{
    objc_setAssociatedObject(self, &viewLoadDuration, ft_loadDuration, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSString *)ft_viewControllerName{
    return NSStringFromClass([self class]);
}
-(NSString *)ft_viewUUID{
    return objc_getAssociatedObject(self, &viewControllerUUID);
}
-(void)setFt_viewUUID:(NSString *)ft_viewUUID{
    objc_setAssociatedObject(self, &viewControllerUUID, ft_viewUUID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (BOOL)isBlackListContainsViewController{
    static NSSet * blacklistedClasses  = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            NSArray *blacklistedViewControllerClassNames =[BlacklistedVCClassNames ft_blacklistedViewControllerClassNames];
            blacklistedClasses = [NSSet setWithArray:blacklistedViewControllerClassNames];
            
        } @catch(NSException *exception) {  // json加载和解析可能失败
            FTInnerLogError(@"error: %@",exception);
        }
    });
    
    __block BOOL isContains = NO;
    [blacklistedClasses enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *blackClassName = (NSString *)obj;
        Class blackClass = NSClassFromString(blackClassName);
        if (blackClass && [self isKindOfClass:blackClass]) {
            isContains = YES;
            *stop = YES;
        }
    }];
    return isContains;
}
- (void)ft_viewDidLoad{
    self.ft_viewLoadStartTime =[NSDate date];
    [self ft_viewDidLoad];
}
-(void)ft_viewDidAppear:(BOOL)animated{
    [self ft_viewDidAppear:animated];
    if(![self isBlackListContainsViewController]){
        // 预防撤回侧滑
        if ([FTTrack sharedInstance].currentRUMView != self) {
            if ([self ft_parentViewControllerIsContainer]) {
                return;
            }
            [FTTrack sharedInstance].currentRUMView = self;
            if(self.ft_viewLoadStartTime){
                NSNumber *loadTime = [self.ft_viewLoadStartTime ft_nanosecondTimeIntervalToDate:[NSDate date]];
                self.ft_loadDuration = loadTime;
                self.ft_viewLoadStartTime = nil;
            }else{
                NSNumber *loadTime = @0;
                self.ft_loadDuration = loadTime;
            }
            self.ft_viewUUID = [FTBaseInfoHandler randomUUID];
            if([FTTrack sharedInstance].addRumDatasDelegate){
                if([[FTTrack sharedInstance].addRumDatasDelegate respondsToSelector:@selector(onCreateView:loadTime:)]){
                    [[FTTrack sharedInstance].addRumDatasDelegate onCreateView:self.ft_viewControllerName loadTime:self.ft_loadDuration];
                }
                if([[FTTrack sharedInstance].addRumDatasDelegate respondsToSelector:@selector(startViewWithViewID:viewName:property:)]){
                    [[FTTrack sharedInstance].addRumDatasDelegate startViewWithViewID:self.ft_viewUUID viewName:self.ft_viewControllerName property:nil];
                }
                
            }
        }
    }
}
-(void)ft_viewDidDisappear:(BOOL)animated{
    [self ft_viewDidDisappear:animated];
    if([self isBlackListContainsViewController]){
        return;
    }
    if ([FTTrack sharedInstance].currentRUMView == self) {
        if([FTTrack sharedInstance].addRumDatasDelegate && [[FTTrack sharedInstance].addRumDatasDelegate respondsToSelector:@selector(stopViewWithViewID:property:)]){
            [[FTTrack sharedInstance].addRumDatasDelegate stopViewWithViewID:self.ft_viewUUID property:nil];
        }
    }
}

-(BOOL)ft_parentViewControllerIsContainer{
    UIViewController *parent = self.parentViewController;
    while (parent != nil) {
        if ([parent isKindOfClass:UIPageViewController.class] || [parent isKindOfClass:UISplitViewController.class]) {
            return YES;
        }else{
            parent = parent.parentViewController;
        }
    }
    return NO;
}
@end
