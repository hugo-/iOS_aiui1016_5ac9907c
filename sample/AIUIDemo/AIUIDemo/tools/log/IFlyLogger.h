//
//  IFlyLogger.h
//
//
//  Created by JzProl.m.Qiezi on 2016/12/20.
//  Copyright © 2016年 iflytek. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 * 日志级别
 * DEBUG    100
 * INFO     200
 * WARNING  300
 * ERROR    400
 * FATAL    500
 */
#define LOG_LEVEL_DEBUG     100
#define LOG_LEVEL_INFO      200
#define LOG_LEVEL_WARN      300
#define LOG_LEVEL_ERROR     400
#define LOG_LEVEL_FATAL     500

@interface IFlyLogger : NSObject

/**
 * 日志是否在调试窗口显示
 */
@property (nonatomic, assign) BOOL isShow;

/**
 * 日志是否写入到文件
 */
@property (nonatomic, assign) BOOL isWrite;

#pragma mark - init

/**
 * 初始化函数
 * @param fileName 日志文件名,包含路径
 */
- (instancetype)initLogWithName:(NSString *)fileName ;

/**
 * 初始化函数
 * @param fileName 日志文件名,包含路径
 */
- (instancetype)initLogWithName:(NSString *)fileName logLevel:(int)logLevel ;

/**
 * 初始化函数
 * @param fileName 日志文件名,包含路径
 * @param logLevel 日志打印级别
 * @param maxLogSize 最大日志大小
 */
- (instancetype)initLogWithName:(NSString *)fileName logLevel:(int)logLevel maxLogSize:(unsigned long long)maxLogSize ;

#pragma mark - print

/**
 * 打印debug级别的日志
 * @param format 日志格式化串
 * @param ... 格式化数据
 */
- (void)debug:(NSString *)format, ... ;

/**
 * 打印info级别的日志
 * @param format 日志格式化串
 * @param ... 格式化数据
 */
- (void)info:(NSString *)format, ... ;

/**
 * 打印warning级别的日志
 * @param format 日志格式化串
 * @param ... 格式化数据
 */
- (void)warn:(NSString *)format, ... ;

/**
 * 打印error级别的日志
 * @param format 日志格式化串
 * @param ... 格式化数据
 */
- (void)error:(NSString *)format, ... ;

/**
 * 打印fatal级别的日志
 * @param format 日志格式化串
 * @param ... 格式化数据
 */
- (void)fatal:(NSString *)format, ... ;

#pragma mark - tools

/**
 * 返回指定日志级别的级别描述
 */
+ (NSString *)getLogLevelName:(int)logLevel ;

/**
 * 返回指定日志级别
 * @param levelName 日志级别名
 * @return 返回日志级别名对应的日志级别
 */
+ (int)getLogLevel:(NSString *)levelName defLevel:(int)defLevel ;


@end
