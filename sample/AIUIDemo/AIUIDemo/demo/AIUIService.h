//
//  AIUIService.h
//  AIUIDemo
//
//  Created on: 2018年1月1日
//      Author: 讯飞开放平台（http://aiui.xfyun.cn）
//

#ifndef AIUIService_h
#define AIUIService_h

#include <string>
#include "UnderstandViewController.h"

#import "IFLYAIUI/AIUI.h"
#import "IFLYAIUI/AIUIConstant.h"

using namespace aiui;
using namespace std;

/**
 *IAIUIListener回调接口实现
 */
class TestListener : public IAIUIListener
{
public:
    /* 事件回调 */
    void onEvent(const IAIUIEvent& event) const;
    
    /* 创建Agent */
    void createAgent();
    
    /* 唤醒 */
    void wakeUp();
    
    /* 销毁Agent */
    void destroyAgent();
    
    /* 上传联系人 */
    void syncContacts();
    
    /* 打包查询 */
    void packQuery();
    
    /* 文本语义理解 */
    void sendTextMessage(string question);
    
    /* 获取Agent */
    IAIUIAgent* getAgent();
    
    UnderstandViewController *m_controller;
    
    void onSetController(UnderstandViewController *param);
    
};

/* sid全局变量 */
static string g_sid;

/*
 * 初始化设置
 */
void initAIUISetting();

/*
 * 获取音频数据，写入AIUI SDK
 */
void sendAudioBuffer(const void *buffer ,int size , bool isEnd);


#endif /* AIUIService_h */

