//
//  IFlyLoggerPrefix.h
//
//
//  Created by JzProl.m.Qiezi on 2016/12/20.
//  Copyright © 2016年 iflytek. All rights reserved.
//

#ifndef IFlyLoggerPrefix_h
#define IFlyLoggerPrefix_h
#import "IFlyLoggerManager.h"


//#define IFly_LOGGER_NEED_SHOW_FILE_LINE
//#define IFly_LOGGER_NEED_SHOW_FUNC

extern NSString* IFlyLoggerTrimFilePath(char* filePath);

#ifdef IFly_LOGGER_NEED_SHOW_FILE_LINE

    #ifdef IFly_LOGGER_NEED_SHOW_FUNC

        #define IFlyLogD(fmt, ...) [IFlyLOGGER debug:(@"[%@:%d] %s " fmt), IFlyLoggerTrimFilePath(__FILE__),__LINE__,__func__,##__VA_ARGS__]

        #define IFlyLogI(fmt, ...) [IFlyLOGGER info:(@"[%@:%d] %s " fmt), IFlyLoggerTrimFilePath(__FILE__),__LINE__,__func__,##__VA_ARGS__]

        #define IFlyLogW(fmt, ...) [IFlyLOGGER warn:(@"[%@:%d] %s " fmt), IFlyLoggerTrimFilePath(__FILE__),__LINE__,__func__,##__VA_ARGS__]

        #define IFlyLogE(fmt, ...) [IFlyLOGGER error:(@"[%@:%d] %s " fmt), IFlyLoggerTrimFilePath(__FILE__),__LINE__,__func__,##__VA_ARGS__]

        #define IFlyLogF(fmt, ...) [IFlyLOGGER fatal:(@"[%@:%d] %s " fmt), IFlyLoggerTrimFilePath(__FILE__),__LINE__,__func__,##__VA_ARGS__]

    #else

        #define IFlyLogD(fmt, ...) [IFlyLOGGER debug:(@"[%@:%d] " fmt), IFlyLoggerTrimFilePath(__FILE__),__LINE__,##__VA_ARGS__]

        #define IFlyLogI(fmt, ...) [IFlyLOGGER info:(@"[%@:%d] " fmt), IFlyLoggerTrimFilePath(__FILE__),__LINE__,##__VA_ARGS__]

        #define IFlyLogW(fmt, ...) [IFlyLOGGER warn:(@"[%@:%d] " fmt), IFlyLoggerTrimFilePath(__FILE__),__LINE__,##__VA_ARGS__]

        #define IFlyLogE(fmt, ...) [IFlyLOGGER error:(@"[%@:%d] " fmt), IFlyLoggerTrimFilePath(__FILE__),__LINE__,##__VA_ARGS__]

        #define IFlyLogF(fmt, ...) [IFlyLOGGER fatal:(@"[%@:%d] " fmt), IFlyLoggerTrimFilePath(__FILE__),__LINE__,##__VA_ARGS__]

    #endif /*IFly_LOGGER_NEED_SHOW_FUNC*/



#else

    #ifdef IFly_LOGGER_NEED_SHOW_FUNC

        #define IFlyLogD(fmt, ...) [IFlyLOGGER debug:(@"%s " fmt), __func__,##__VA_ARGS__]

        #define IFlyLogI(fmt, ...) [IFlyLOGGER info:(@"%s " fmt), __func__,##__VA_ARGS__]

        #define IFlyLogW(fmt, ...) [IFlyLOGGER warn:(@"%s " fmt), __func__,##__VA_ARGS__]

        #define IFlyLogE(fmt, ...) [IFlyLOGGER error:(@"%s " fmt), __func__,##__VA_ARGS__]

        #define IFlyLogF(fmt, ...) [IFlyLOGGER fatal:(@"%s " fmt), __func__,##__VA_ARGS__]

    #else

        #define IFlyLogD(fmt, ...) [IFlyLOGGER debug:fmt, ##__VA_ARGS__]

        #define IFlyLogI(fmt, ...) [IFlyLOGGER info:fmt, ##__VA_ARGS__]

        #define IFlyLogW(fmt, ...) [IFlyLOGGER warn:fmt, ##__VA_ARGS__]

        #define IFlyLogE(fmt, ...) [IFlyLOGGER error:fmt, ##__VA_ARGS__]

        #define IFlyLogF(fmt, ...) [IFlyLOGGER fatal:fmt, ##__VA_ARGS__]

    #endif /*IFly_LOGGER_NEED_SHOW_FUNC*/


#endif /*IFly_LOGGER_NEED_SHOW_FILE_LINE*/

#endif /* IFlyLoggerPrefix.h */
