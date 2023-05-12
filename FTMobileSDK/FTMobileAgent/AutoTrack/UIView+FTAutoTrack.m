//
//  UIView+FTAutoTrack.m
//  FTAutoTrack
//
//  Created by 胡蕾蕾 on 2019/11/29.
//  Copyright © 2019 hll. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif
#import "UIView+FTAutoTrack.h"

@implementation UIView (FTAutoTrack)
-(NSString *)ft_actionName{
    NSString *viewTitle = @"";
    if ([self isKindOfClass:UIButton.class]) {
        UIButton *btn =(UIButton *)self;
        viewTitle = btn.currentTitle.length>0?[NSString stringWithFormat:@"[%@]",btn.currentTitle]:@"";
    }
    NSString *className = NSStringFromClass(self.class);
    NSString *actionName = [NSString stringWithFormat:@"[%@]%@",className,viewTitle];
    return actionName;
}
- (BOOL)isAlertView {
    UIResponder *responder = self;
    do {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        BOOL isUIAlertView = [responder isKindOfClass:UIAlertView.class];
        BOOL isUIActionSheet = [responder isKindOfClass:UIActionSheet.class];
#pragma clang diagnostic pop

        BOOL isUIAlertController = [responder isKindOfClass:UIAlertController.class];

    
        if (isUIAlertController || isUIAlertView || isUIActionSheet) {
            return YES;
        }
    } while ((responder = [responder nextResponder]));
    return NO;
}
/// 是否为弹框点击
- (BOOL)isAlertClick {
    if ([NSStringFromClass(self.class) isEqualToString:@"_UIInterfaceActionCustomViewRepresentationView"] || [NSStringFromClass(self.class) isEqualToString:@"_UIAlertControllerCollectionViewCell"]) { // 标记弹框
        return YES;
    }
    return NO;
}
@end
@implementation UISegmentedControl (FTAutoTrack)

-(NSString *)ft_actionName{
    NSString *title = [self titleForSegmentAtIndex:self.selected];
    return title?[NSString stringWithFormat:@"[%@]%@",NSStringFromClass(self.class),title]:super.ft_actionName;
}
@end

@implementation UIStepper (FTAutoTrack)
-(NSString *)ft_actionName{
    return [NSString stringWithFormat:@"[%@]%f",NSStringFromClass(self.class),self.value];
}
@end
@implementation UISlider (FTAutoTrack)

-(NSString *)ft_actionName{
    return [NSString stringWithFormat:@"[%@]%f",NSStringFromClass(self.class),self.value];
}

@end
@implementation UIPageControl (FTAutoTrack)

-(NSString *)ft_actionName{
    return [NSString stringWithFormat:@"[%@]%ld",NSStringFromClass(self.class),(long)self.currentPage];
}
@end
@implementation UISwitch (FTAutoTrack)

-(NSString *)ft_actionName{
    NSString *title = self.isOn?@"On":@"Off";
    return [NSString stringWithFormat:@"[%@]%@",NSStringFromClass(self.class),title];
}
@end
