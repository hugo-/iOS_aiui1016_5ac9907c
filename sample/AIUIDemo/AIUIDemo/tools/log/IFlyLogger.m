//
//  IFlyLogger.m
//
//
//  Created by JzProl.m.Qiezi on 2016/12/20.
//  Copyright © 2016年 iflytek. All rights reserved.
//

#import "IFlyLogger.h"

/*!
 *  去除获取文件的路径和文件名后缀
 *
 *  @param filePath 文件路径
 *
 *  @return 文件名（无后缀）
 */
NSString* IFlyLoggerTrimFilePath(char* filePath);
NSString* IFlyLoggerTrimFilePath(char* filePath){
    NSString* fileName = [NSString stringWithFormat:@"%s", filePath];
    return  [[fileName lastPathComponent] stringByDeletingPathExtension];
}


@interface IFlyLogger()

@property (nonatomic, strong) NSString* logFileName;                    // 日志文件名,包含路径;
@property (nonatomic, assign) int logLevel;                             // 日志打印级别
@property (nonatomic, assign) unsigned long long maxLogSize;            // 最大日志大小
@property (nonatomic, strong) dispatch_queue_t logQueue;                // 打印日志的线程队列

@end


@implementation IFlyLogger

#pragma mark 初始化函数

/**
 * 初始化函数
 * @param logFileName 日志文件名,包含路径
 * @param logLevel 日志打印级别
 */
- (instancetype)initLogWithName:(NSString *)fileName {
    return [self initLogWithName:fileName logLevel:LOG_LEVEL_ERROR];
}

/**
 * 初始化函数
 * @param logFileName 日志文件名,包含路径
 * @param logLevel 日志打印级别
 */
- (instancetype)initLogWithName:(NSString *)fileName logLevel:(int)logLevel {
    return [self initLogWithName:fileName logLevel:logLevel maxLogSize:1048576]; // 默认1M大小
}

/**
 * 初始化函数
 * @param logFileName 日志文件名,包含路径
 * @param logLevel 日志打印级别
 * @param maxLogSize 最大日志大小
 */
- (instancetype)initLogWithName:(NSString *)fileName logLevel:(int)logLevel maxLogSize:(unsigned long long)maxLogSize {
    if (self = [super init]) {
        _logFileName = fileName;
        _logLevel = logLevel;
        _maxLogSize = maxLogSize;
        _isShow=YES;
        _isWrite=YES;
        _logQueue = dispatch_queue_create("com.iflytek.sc.log.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark 日志打印函数

/**
 * 打印debug级别的日志
 * @param format 日志格式化串
 * @param ... 格式化数据
 */
- (void)debug:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *logInfo = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self writeLog:LOG_LEVEL_DEBUG logInfo:logInfo];
}

/**
 * 打印info级别的日志
 * @param format 日志格式化串
 * @param ... 格式化数据
 */
- (void)info:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *logInfo = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self writeLog:LOG_LEVEL_INFO logInfo:logInfo];
}

/**
 * 打印warning级别的日志
 * @param format 日志格式化串
 * @param ... 格式化数据
 */
- (void)warn:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *logInfo = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self writeLog:LOG_LEVEL_WARN logInfo:logInfo];
}

/**
 * 打印error级别的日志
 * @param format 日志格式化串
 * @param ... 格式化数据
 */
- (void)error:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *logInfo = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self writeLog:LOG_LEVEL_ERROR logInfo:logInfo];
}

/**
 * 打印fatal级别的日志
 * @param format 日志格式化串
 * @param ... 格式化数据
 */
- (void)fatal:(NSString *)format, ...{
    va_list args;
    va_start(args, format);
    NSString *logInfo = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self writeLog:LOG_LEVEL_FATAL logInfo:logInfo];
}

/**
 * 打印日志
 * @param logLevel 日志级别
 * @param format 日志格式化串
 * @param args 格式化数据
 */
- (void)writeLog:(int)logLevel logInfo:(NSString *)logInfo {
    
    // 如果日志级别不够,不要打印日志了
    if (_logLevel > logLevel) return;
    
    // 在日志打印队列中处理日志打印
    __weak __typeof(self) weakSelf = self;
    dispatch_async(_logQueue, ^{
         __typeof(&*weakSelf) strongSelf = weakSelf;
        // 格式化日志
        NSDate *now = [NSDate date];
        NSDateFormatter *fformatter = [[NSDateFormatter alloc] init] ;
        [fformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSSSS"];
        
        NSDateFormatter *tformatter = [[NSDateFormatter alloc] init] ;
        [tformatter setDateFormat:@"HH:mm:ss.SSSSSS"];
        
        NSString* fformatInfo = [NSString stringWithFormat:@"[%@]<%@> %@\n", [fformatter stringFromDate:now], [IFlyLogger getLogLevelName:logLevel], logInfo];
        
        NSString* tformatInfo = [NSString stringWithFormat:@"[%@]<%@> %@\n", [tformatter stringFromDate:now], [IFlyLogger getLogLevelName:logLevel], logInfo];
        
        if (strongSelf.isWrite) {
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            
            // 如果文件不存在，创建文件
            if (![fileMgr fileExistsAtPath:strongSelf.logFileName]) {
                [fileMgr createFileAtPath:strongSelf.logFileName contents:nil attributes:nil];
            }
            
            // 获取文件大小
            NSDictionary *fileAttributes = [fileMgr attributesOfItemAtPath:strongSelf.logFileName error:nil];
            unsigned long long fileSize = [fileAttributes fileSize];
            
            if (fileSize >= strongSelf.maxLogSize) {
                NSString *newFileName = [NSString stringWithFormat:@"%@.backup", strongSelf.logFileName];
                if ([fileMgr fileExistsAtPath:newFileName]) {
                    [fileMgr removeItemAtPath:newFileName error:nil];
                }
                // 文件更名
                [fileMgr moveItemAtPath:strongSelf.logFileName toPath:newFileName error:nil];
                // 重新创建新文件
                [fileMgr createFileAtPath:strongSelf.logFileName contents:nil attributes:nil];
            }
            
            // 写入文件
            NSFileHandle *fileHdr = [NSFileHandle fileHandleForWritingAtPath:strongSelf.logFileName];
            [fileHdr seekToEndOfFile];
            [fileHdr writeData:[fformatInfo dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHdr closeFile];
        }
        
        
        if (strongSelf.isShow) {
            printf("[Demo] %s",[tformatInfo UTF8String]);
        }

    });
}

#pragma mark 辅助函数

/**
 * 返回指定日志级别的级别描述
 */
+ (NSString *)getLogLevelName:(int)logLevel {
    switch(logLevel) {
        case LOG_LEVEL_DEBUG:
            return @"DEBUG";
        case LOG_LEVEL_FATAL:
            return @"FATAL";
        case LOG_LEVEL_INFO:
            return @"INFO";
        case LOG_LEVEL_WARN:
            return @"WARNING";
        case LOG_LEVEL_ERROR:
            return @"ERROR";
        default:
            return @"N/A";
    }
}

/**
 * 返回指定日志级别
 * @param levelName 日志级别名
 * @return 返回日志级别名对应的日志级别
 */
+ (int) getLogLevel:(NSString *)levelName defLevel:(int)defLevel {
    if (levelName == nil) return defLevel;
    
    if ([@"DEBUG" isEqualToString:levelName]) return LOG_LEVEL_DEBUG;
    if ([@"INFO" isEqualToString:levelName]) return LOG_LEVEL_INFO;
    if ([@"WARN" isEqualToString:levelName]) return LOG_LEVEL_WARN;
    if ([@"ERROR" isEqualToString:levelName]) return LOG_LEVEL_ERROR;
    if ([@"FATAL" isEqualToString:levelName]) return LOG_LEVEL_FATAL;
    return defLevel;
}

@end
