//
//  FTUITabBarRecorder.m
//  FTMobileSDK
//
//  Created by hulilei on 2023/8/24.
//  Copyright © 2023 DataFlux-cn. All rights reserved.
//

#import "FTUITabBarRecorder.h"
#import "FTSRWireframe.h"
#import "FTViewAttributes.h"
#import "FTSRWireframesBuilder.h"
#import "FTSRUtils.h"
#import "FTViewTreeRecordingContext.h"
#import "FTViewTreeRecorder.h"
#import "FTUIImageViewRecorder.h"
#import "FTUILabelRecorder.h"
#import "FTUIViewRecorder.h"
#import <CoreGraphics/CGImage.h>
#import "FTSystemColors.h"
@implementation UIImage(FTTabBarRecorder)
- (NSString *)uniqueDescription{
    if(self.CGImage){
        CGImageRef cgImage = self.CGImage;
        return [NSString stringWithFormat:@"%zux%zux-%zux%zu-%zu-%u",CGImageGetWidth(cgImage),CGImageGetHeight(cgImage),CGImageGetBitsPerComponent(cgImage),CGImageGetBitsPerPixel(cgImage),CGImageGetBytesPerRow(cgImage),CGImageGetBitmapInfo(cgImage)];
    }
    return nil;
}
@end
@interface FTUITabBarRecorder()
@property (nonatomic, strong) FTViewTreeRecorder *subtreeRecorder;
@end
@implementation FTUITabBarRecorder
-(instancetype)init{
    self = [super init];
    if(self){
        _identifier = [[NSUUID UUID] UUIDString];
    }
    return self;
}
-(FTSRNodeSemantics *)recorder:(UIView *)view attributes:(FTViewAttributes *)attributes context:(FTViewTreeRecordingContext *)context{
    if(![view isKindOfClass:[UITabBar class]]){
        return nil;
    }
    UITabBar *tabBar = (UITabBar *)view;
    FTUITabBarBuilder *builder = [[FTUITabBarBuilder alloc]init];
    builder.color = [self inferTabBarColor:tabBar];
    builder.wireframeID = [context.viewIDGenerator SRViewID:tabBar nodeRecorder:self];
    builder.wireframeRect = [self inferBarFrame:tabBar context:context];
    builder.attributes = attributes;
    NSMutableArray *records = [NSMutableArray arrayWithArray:@[builder]];
    NSMutableArray *resources = [NSMutableArray array];
    [self recordSubtree:tabBar records:records resources:resources context:context];
    FTSpecificElement *element = [[FTSpecificElement alloc]initWithSubtreeStrategy:NodeSubtreeStrategyIgnore];
    element.nodes = records;
    element.resources = resources;
    return element;
}
- (void)recordSubtree:(UITabBar *)tabBar records:(NSMutableArray *)records resources:(NSMutableArray *)resources context:(FTViewTreeRecordingContext *)context{
    if(!self.subtreeRecorder){
        FTViewTreeRecorder *viewTreeRecorder = [[FTViewTreeRecorder alloc]init];
        FTUIImageViewRecorder *imageViewRecorder = [[FTUIImageViewRecorder alloc]init];
        imageViewRecorder.tintColorProvider = ^UIColor * _Nullable(UIImageView * _Nonnull imageView) {
            if(imageView.image){
                UITabBarItem *currentItemInSelectedState = nil;
                NSString *uniqueDescription = tabBar.items.firstObject.selectedImage.uniqueDescription;
                if(uniqueDescription){
                    currentItemInSelectedState = [uniqueDescription isEqualToString:imageView.image.uniqueDescription]?tabBar.items.firstObject:nil;
                }
                if(currentItemInSelectedState == nil || tabBar.selectedItem != currentItemInSelectedState){
                    return tabBar.unselectedItemTintColor?tabBar.unselectedItemTintColor:[[UIColor systemGrayColor] colorWithAlphaComponent:0.5];
                }
                return tabBar.tintColor?: [UIColor systemBlueColor];
            }
            return nil;
        };
        viewTreeRecorder.nodeRecorders = @[
            imageViewRecorder,
            [[FTUILabelRecorder alloc] init],
            [[FTUIViewRecorder alloc] init],
        ];
        self.subtreeRecorder = viewTreeRecorder;
    }
    [self.subtreeRecorder record:records resources:resources view:tabBar context:context];
}
- (CGColorRef )inferTabBarColor:(UITabBar *)bar{
    if(bar.backgroundColor){
        return bar.backgroundColor.CGColor;
    }
    if (@available(iOS 13.0, *)) {
        switch ([UITraitCollection currentTraitCollection].userInterfaceStyle) {
            case UIUserInterfaceStyleLight:
                return [UIColor whiteColor].CGColor;
            case UIUserInterfaceStyleDark:
                return [UIColor blackColor].CGColor;
            default:
                return [UIColor whiteColor].CGColor;
        }
    }
    return UIColor.whiteColor.CGColor;
}

- (CGRect)inferBarFrame:(UITabBar *)bar context:(FTViewTreeRecordingContext *)context{
    CGRect newRect = bar.frame;
    for (UIView *view in bar.subviews) {
        CGRect subViewRect = [view convertRect:view.bounds toCoordinateSpace:context.coordinateSpace];
        newRect = CGRectUnion(newRect, subViewRect);
    }
    return newRect;
}
@end

@implementation FTUITabBarBuilder
- (NSArray<FTSRWireframe *> *)buildWireframes{
    FTSRShapeWireframe *wireframe = [[FTSRShapeWireframe alloc]initWithIdentifier:self.wireframeID frame:self.wireframeRect backgroundColor:[FTSRUtils colorHexString:self.color] cornerRadius:@(self.attributes.layerCornerRadius) opacity:@(self.attributes.alpha)];
    wireframe.border = [[FTSRShapeBorder alloc]initWithColor:[FTSRUtils colorHexString:[[UIColor lightGrayColor] colorWithAlphaComponent:0.5].CGColor] width:0.5];
    return @[wireframe];
}
@end
