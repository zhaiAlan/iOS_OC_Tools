//
//  NSArray+ErrorHandle.m
//  APP起死回生
//
//  Created by Alan on 4/22/20.
//  Copyright © 2020 zhaixingzhi. All rights reserved.
//

#import "NSArray+ErrorHandle.h"
#import "NSObject+XZSwizzleMethod.h"
#import <objc/runtime.h>


@implementation NSArray (ErrorHandle)
+(void)load{
    [super load];
    //无论怎样 都要保证方法只交换一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //交换NSArray中的objectAtIndex方法
        [objc_getClass("__NSArrayI") SystemSelector:@selector(objectAtIndex:) swizzledSelector:@selector(xz_objectAtIndex:) error:nil];
        //交换NSArray中的objectAtIndexedSubscript方法
        [objc_getClass("__NSArrayI") SystemSelector:@selector(objectAtIndexedSubscript:) swizzledSelector:@selector(xz_objectAtIndexedSubscript:) error:nil];
    });
}

- (id)xz_objectAtIndexedSubscript:(NSUInteger)idx{
    if (idx < self.count) {
        return [self xz_objectAtIndexedSubscript:idx];
    }else{
        NSLog(@" 你的 NSArray数组已经越界了 但是已经帮你处理好了  %ld   %ld", idx, self.count);
        return nil;
    }
}

- (id)xz_objectAtIndex:(NSUInteger)index{
    if (index < self.count) {
        return [self xz_objectAtIndex:index];
    }else{
        NSLog(@" 你的 NSArray数组已经越界了 但是已经帮你处理好了  %ld   %ld", index, self.count);

        return nil;
    }
}
/**
 *  防止数组越界
 */
- (id)objectAtIndexVerify:(NSUInteger)index{
    if (index < self.count) {
        return [self objectAtIndex:index];
    }else{
        return nil;
    }
}
/**
 *  防止数组越界
 */
- (id)objectAtIndexedSubscriptVerify:(NSUInteger)idx{
    if (idx < self.count) {
        return [self objectAtIndexedSubscript:idx];
    }else{
        return nil;
    }
}
@end
