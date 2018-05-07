//
//  UnderstandViewController.h
//  AIUIDemo
//
//  Created on: 2018年1月1日
//      Author: 讯飞开放平台（http://aiui.xfyun.cn）
//

#import <UIKit/UIKit.h>
#import "IFLYAIUI/AIUI.h"
#import "IFLYAIUI/AIUIConstant.h"
#import "IFlyPcmRecorder.h"

@class PopupView;


/**
 *demo of Natural Language Understanding (NLP)
 *
 */
@interface UnderstandViewController : UIViewController<IFlyPcmRecorderDelegate>

@property (nonatomic,weak)   UITextView *resultView;
@property (nonatomic,strong) PopupView  *popUpView;
@property (nonatomic, copy)  NSString * defaultText;

@property (nonatomic) BOOL isRecord;
@property (nonatomic,strong) NSString *result;

@property (nonatomic,strong)IFlyPcmRecorder *m_recorder;

/* 创建Agent */
@property (weak, nonatomic) IBOutlet UIButton *createAgentBtn;

/* 语音识别、语义理解内容view*/
@property (weak, nonatomic) IBOutlet UITextView *textView;

/* 开始语音识别和语义理解 */
@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;

/* 停止语音识别和语义理解 */
@property (weak, nonatomic) IBOutlet UIButton *stopRecordBtn;

/* 上传联系人 */
@property (weak, nonatomic) IBOutlet UIButton *upContactsBtn;

/* 打包（上传联系人结果）查询*/
@property (weak, nonatomic) IBOutlet UIButton *packQueryBtn;

/* 销魂Agent */
@property (weak, nonatomic) IBOutlet UIButton *destroyAgentBtn;

/*停止录音机录音（开发者可选用改接口配合唤醒SDK自己实现oneShot交互控制）*/
-(void) stop;
@end

