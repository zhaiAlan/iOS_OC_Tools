//
//  NSMutableArray+ErrorHandle.m
//  APP起死回生
//
//  Created by Alan on 4/22/20.
//  Copyright © 2020 zhaixingzhi. All rights reserved.
//

#import "NSMutableArray+ErrorHandle.h"
#import "NSObject+XZSwizzleMethod.h"
#import <objc/runtime.h>

@implementation NSMutableArray (ErrorHandle)
+(void)load{
    [super load];
    //无论怎样 都要保证方法只交换一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //交换NSMutableArray中的方法
        [objc_getClass("__NSArrayM") SystemSelector:@selector(objectAtIndex:) swizzledSelector:@selector(xz_objectAtIndex:) error:nil];
        //交换NSMutableArray中的方法
        [objc_getClass("__NSArrayM") SystemSelector:@selector(objectAtIndexedSubscript:) swizzledSelector:@selector(xz_objectAtIndexedSubscript:) error:nil];
    });
}
- (id)xz_objectAtIndex:(NSUInteger)index{
    if (index < self.count) {
        return [self xz_objectAtIndex:index];
    }else{

        NSLog(@" 你的NSMutableArray数组已经越界 帮你处理好了%ld   %ld   %@", index, self.count, [self class]);
        return nil;
    }
}
- (id)xz_objectAtIndexedSubscript:(NSUInteger)index{
    if (index < self.count) {

        return [self xz_objectAtIndexedSubscript:index];
    }else{
        NSLog(@" 你的NSMutableArray数组已经越界 帮你处理好了%ld   %ld   %@", index, self.count, [self class]);
        return nil;
    }
}
/**
 *  数组中插入数据
 */
- (void)insertObjectVerify:(id)object atIndex:(NSInteger)index{
    if (index < self.count && object) {
        [self insertObject:object atIndex:index];
    }
}
/**
 *  数组中添加数据
 */
- (void)addObjectVerify:(id)object{
    if (object) {
        [self addObject:object];
    }
}
@end
