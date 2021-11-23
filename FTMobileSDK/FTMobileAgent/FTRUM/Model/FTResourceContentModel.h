//
//  FTResourceContentModel.h
//  FTMobileAgent
//
//  Created by 胡蕾蕾 on 2021/10/27.
//  Copyright © 2021 DataFlux-cn. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FTResourceContentModel : NSObject
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSDictionary *requestHeader;
@property (nonatomic, strong) NSDictionary *responseHeader;
@property (nonatomic, copy) NSString *resourceMethod;
@property (nonatomic, copy) NSString *responseBody;
@property (nonatomic, assign) NSInteger httpStatusCode;

@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSNumber *duration;
@end

NS_ASSUME_NONNULL_END
