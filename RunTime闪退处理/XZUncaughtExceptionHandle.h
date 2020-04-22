//
//  XZUncaughtExceptionHandle.h
//  APP起死回生
//
//  Created by Alan on 4/22/20.
//  Copyright © 2020 zhaixingzhi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XZUncaughtExceptionHandle : NSObject
//是否让程序进行退出
@property (nonatomic) BOOL dismissed;

//注册信息
+ (void)installUncaughtSignalExceptionHandler;

@end

NS_ASSUME_NONNULL_END
