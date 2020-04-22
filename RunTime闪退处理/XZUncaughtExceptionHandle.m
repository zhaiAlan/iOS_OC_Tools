//
//  XZUncaughtExceptionHandle.m
//  APP起死回生
//
//  Created by Alan on 4/22/20.
//  Copyright © 2020 zhaixingzhi. All rights reserved.
//

#import "XZUncaughtExceptionHandle.h"
#import <UIKit/UIKit.h>
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#include <stdatomic.h>

//异常名称
NSString * const XZUncaughtExceptionHandlerSignalExceptionName = @"XZUncaughtExceptionHandlerSignalExceptionName";
//崩溃原因
NSString * const XZUncaughtExceptionHandlerSignalExceptionReason = @"XZUncaughtExceptionHandlerSignalExceptionReason";
NSString * const XZUncaughtExceptionHandlerSignalKey = @"XZUncaughtExceptionHandlerSignalKey";
NSString * const XZUncaughtExceptionHandlerAddressesKey = @"XZUncaughtExceptionHandlerAddressesKey";
NSString * const XZUncaughtExceptionHandlerFileKey = @"XZUncaughtExceptionHandlerFileKey";
NSString * const XZUncaughtExceptionHandlerCallStackSymbolsKey = @"XZUncaughtExceptionHandlerCallStackSymbolsKey";


atomic_int      XZUncaughtExceptionCount = 0;
const int32_t   XZUncaughtExceptionMaximum = 8;
const NSInteger XZUncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger XZUncaughtExceptionHandlerReportAddressCount = 5;


@implementation XZUncaughtExceptionHandle
+ (void)installUncaughtSignalExceptionHandler
{
    //注册一个回调函数
    NSSetUncaughtExceptionHandler(&XZExceptionHandlers);
}
void XZExceptionHandlers(NSException *exception) {
    NSLog(@"%s",__func__);
    // 收集 - 上传
    int32_t exceptionCount = atomic_fetch_add_explicit(&XZUncaughtExceptionCount,1,memory_order_relaxed);
    if (exceptionCount > XZUncaughtExceptionMaximum) {
        return;
    }
    // 获取堆栈信息 - model 编程思想
    NSArray *callStack = [XZUncaughtExceptionHandle xz_backtrace];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setObject:exception.name forKey:XZUncaughtExceptionHandlerSignalExceptionName];
    [userInfo setObject:exception.reason forKey:XZUncaughtExceptionHandlerSignalExceptionReason];
    [userInfo setObject:callStack forKey:XZUncaughtExceptionHandlerAddressesKey];
    [userInfo setObject:exception.callStackSymbols forKey:XZUncaughtExceptionHandlerCallStackSymbolsKey];
    [userInfo setObject:@"XZException" forKey:XZUncaughtExceptionHandlerFileKey];
    
    [[[XZUncaughtExceptionHandle alloc] init]
     performSelectorOnMainThread:@selector(xz_handleException:)
     withObject:
     [NSException
      exceptionWithName:[exception name]
      reason:[exception reason]
      userInfo:userInfo]
     waitUntilDone:YES];
    

}
//起死回生
- (void)xz_handleException:(NSException *)exception{
    
    NSDictionary *dict = [exception userInfo];
    
    [self saveCrash:exception file:[dict objectForKey:XZUncaughtExceptionHandlerFileKey]];
    
    // 网络上传 - flush
    // 用户奔溃
    // runloop 起死回生
    
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    // 跑圈依赖 - mode
    CFArrayRef allmodes  = CFRunLoopCopyAllModes(runloop);
    
//    SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindowWidth:300.0f];
//
//    [alert addButton:@"请你奔溃" actionBlock:^{
//        self.dismissed = YES;
//    }];
//
//    [alert showSuccess:exception.name subTitle:exception.reason closeButtonTitle:nil duration:0.0f];
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"应用出现问题" message:@"为了保障您的继续使用，请点击确认退出应用" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ac = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.dismissed = YES;
    }];
    [alertVC addAction:ac];
    
    UIViewController *vc = [[UIApplication sharedApplication].windows.lastObject rootViewController];
    [vc presentViewController:alertVC animated:YES completion:nil];
    // 起死回生
    while (!self.dismissed) {
        for (NSString *mode in (__bridge NSArray *)allmodes) {
            CFRunLoopRunInMode((CFStringRef)mode, 0.0001, false);
        }
    }
    
    
    CFRelease(runloop);

}
-(void)showAlert
{
//     UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"应用出现问题" message:@"为了保障您的继续使用，请点击确认退出应用" preferredStyle:UIAlertControllerStyleAlert];


}
/// 保存奔溃信息或者上传
- (void)saveCrash:(NSException *)exception file:(NSString *)file{
    
    NSArray *stackArray = [[exception userInfo] objectForKey:XZUncaughtExceptionHandlerCallStackSymbolsKey];// 异常的堆栈信息
    NSString *reason = [exception reason];// 出现异常的原因
    NSString *name = [exception name];// 异常名称
    
    // 或者直接用代码，输入这个崩溃信息，以便在console中进一步分析错误原因
    // NSLog(@"crash: %@", exception);
    
    NSString * _libPath  = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:file];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_libPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:_libPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDate *dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a=[dat timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%f", a];
    
    NSString * savePath = [_libPath stringByAppendingFormat:@"/error%@.log",timeString];
    
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@",name, reason, stackArray];
    
    BOOL sucess = [exceptionInfo writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"保存崩溃日志 sucess:%d,%@",sucess,savePath);
    
}


/// 获取函数堆栈信息
+ (NSArray *)xz_backtrace{
    
    void* callstack[128];
    int frames = backtrace(callstack, 128);//用于获取当前线程的函数调用堆栈，返回实际获取的指针个数
    char **strs = backtrace_symbols(callstack, frames);//从backtrace函数获取的信息转化为一个字符串数组
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (i = XZUncaughtExceptionHandlerSkipAddressCount;
         i < XZUncaughtExceptionHandlerSkipAddressCount+XZUncaughtExceptionHandlerReportAddressCount;
         i++)
    {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    return backtrace;
}


-(UIViewController *)currentViewController{
    UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
    NSLog(@"window level: %.0f", window.windowLevel);
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow * tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }
    
    //从根控制器开始查找
    UIViewController *rootVC = window.rootViewController;
    UIViewController *activityVC = nil;
    
    while (true) {
        if ([rootVC isKindOfClass:[UINavigationController class]]) {
            activityVC = [(UINavigationController *)rootVC visibleViewController];
        } else if ([rootVC isKindOfClass:[UITabBarController class]]) {
            activityVC = [(UITabBarController *)rootVC selectedViewController];
        } else if (rootVC.presentedViewController) {
            activityVC = rootVC.presentedViewController;
        }else {
            break;
        }
        
        rootVC = activityVC;
    }
    
    return activityVC;
}
@end
