//
//  IFlyLoggerManager.m
//
//
//  Created by JzProl.m.Qiezi on 2016/12/20.
//  Copyright © 2016年 iflytek. All rights reserved.
//

#import "IFlyLoggerManager.h"

@implementation IFlyLoggerManager

+ (instancetype) sharedInstance {
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        
    });
    return sharedInstance ;
}

-(instancetype)init{
    if(self=[super init]){
        [self initLogger];
    }
    return self;
}

/**
 * 初始化日志
 */
- (void) initLogger {
    NSDictionary *dic = [[NSBundle mainBundle] infoDictionary];
    
    // 1. 获取日志文件名，如果没有配置，使用程序名称
    NSString *logName = [dic objectForKey:@"AppLogFileName"];
    
    if (!logName) {
        logName = @"demo_iOS";
    }
    
    // 2. 获取日志路径，把日志放在cache目录下面，并得到包含路径日志文件名
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [cachePaths objectAtIndex:0];
    NSString *logFileName = [NSString stringWithFormat:@"%@/%@.log", cachePath, logName];
    
    // 3. 日志打印级别
    NSString *sLogLevel = [dic objectForKey:@"AppLogLevel"];
    int logLevel = [IFlyLogger getLogLevel:sLogLevel defLevel:LOG_LEVEL_DEBUG];
    
    // 4. 最大日志大小
    unsigned long long maxLogSize = [[dic objectForKey:@"AppMaxLogLevel"] unsignedLongLongValue];
    if (0 == maxLogSize) maxLogSize = 1048576;
    
    [self initLogger:logFileName byLogLevel:logLevel andMaxLogSize:maxLogSize];
}

/**
 * 初始化日志
 */
- (void) initLogger:(NSString *)logFileName byLogLevel:(int)logLevel andMaxLogSize:(unsigned long long)maxLogSize {
    _logger = [[IFlyLogger alloc] initLogWithName:logFileName logLevel:logLevel maxLogSize:maxLogSize];
}

@end
