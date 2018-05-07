//
//  IFlyLoggerManager.h
//
//
//  Created by JzProl.m.Qiezi on 2016/12/20.
//  Copyright © 2016年 iflytek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFlyLogger.h"

#define IFlyLOGGER [[IFlyLoggerManager sharedInstance] logger]

/**
 * 日志管理器
 */
@interface IFlyLoggerManager : NSObject

/**
 * 日志打印对象
 */
@property (nonatomic, strong) IFlyLogger* logger;

/**
 * 单例
 */
+ (instancetype) sharedInstance ;

/**
 * 初始化日志
 */
- (void) initLogger ;

/**
 * 初始化日志
 * @param logFileName 日志文件名,包含路径
 * @param logLevel 日志打印级别
 * @param maxLogSize 最大日志大小
 */
- (void) initLogger:(NSString *)logFileName byLogLevel:(int)logLevel andMaxLogSize:(unsigned long long)maxLogSize ;

@end

