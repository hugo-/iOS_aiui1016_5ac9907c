//
//  Definition.h
//  AIUIDemo
//
//  Created on: 2018年1月1日
//      Author: 讯飞开放平台（http://aiui.xfyun.cn）
//

#import <Foundation/Foundation.h>
#define Margin  5
#define Padding 10
#define iOS7TopMargin 64
#define IOS7_OR_LATER   ( [[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending )
#define ButtonHeight 44
#define NavigationBarHeight 44

/* 应用APPID*/
#define APPID_VALUE           @"5ac9907c"



#ifdef __IPHONE_6_0
# define IFLY_ALIGN_CENTER NSTextAlignmentCenter
#else
# define IFLY_ALIGN_CENTER UITextAlignmentCenter
#endif

#ifdef __IPHONE_6_0
# define IFLY_ALIGN_LEFT NSTextAlignmentLeft
#else
# define IFLY_ALIGN_LEFT UITextAlignmentLeft
#endif
