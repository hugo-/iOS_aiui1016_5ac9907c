//
//  UnderstandViewController.mm
//  AIUIDemo
//
//  Created on: 2018年1月1日
//      Author: 讯飞开放平台（http://aiui.xfyun.cn）
//

#import "UnderstandViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "PopupView.h"

#import "IFlyPcmRecorder.h"
#import "IFlyAudioSession.h"

#import "IFLYAIUI/AIUI.h"
#import "IFLYAIUI/AIUIConstant.h"
#include "AIUIService.h"

class TestListener;

@implementation UnderstandViewController

extern TestListener m_listener;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    /* 添加textview边框 */
    _textView.layer.borderWidth = 0.5f;
    _textView.layer.borderColor = [[UIColor whiteColor] CGColor];
    [_textView.layer setCornerRadius:7.0f];
    
    _defaultText = NSLocalizedString(@"weather", nil);
    _textView.text = [NSString stringWithFormat:@"%@",self.defaultText];
    
    UIBarButtonItem *spaceBtnItem= [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem * hideBtnItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"hide", @"Hide") style:UIBarButtonItemStylePlain target:self action:@selector(onKeyBoardDown:)];
    [hideBtnItem setTintColor:[UIColor whiteColor]];
    
    UIToolbar * toolbar = [[ UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbar.barStyle = UIBarStyleBlackTranslucent;
    NSArray * array = [NSArray arrayWithObjects:spaceBtnItem,hideBtnItem, nil];
    [toolbar setItems:array];
    _textView.inputAccessoryView = toolbar;
    
    CGFloat posY = self.textView.frame.origin.y+self.textView.frame.size.height/6;
    _popUpView = [[PopupView alloc] initWithFrame:CGRectMake(100, posY, 0, 0) withParentView:self.view];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil];
    
    m_listener.onSetController(self);
}

- (void)viewWillAppear:(BOOL)animated
{
    [_startRecordBtn setEnabled:YES];
    
    [_stopRecordBtn setEnabled:YES];
    
    [super viewWillAppear:animated];
    
    m_listener.onSetController(self);
    
    NSLog(@"viewWillAppear");
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self stop];
    
    m_listener.onSetController(nil);
    
    [super viewWillDisappear:animated];
    
    NSLog(@"viewWillDisappear");
}

- (void)dealloc
{
    NSLog(@"dealloc");
    [self stop];
    m_listener.destroyAgent();
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)onTextBtnHandler:(id)sender
{
    
    m_listener.onSetController(self);
    
    if (m_listener.getAgent() != NULL)
    {
        
        _textView.text = NSLocalizedString(@"weather", nil);
    
        m_listener.sendTextMessage([_textView.text UTF8String]);
    }
    else
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
    }
}

/* 创建Agent */

- (IBAction)onCreateClick:(id)sender {
    m_listener.createAgent();
    m_listener.wakeUp();
}

/* 上传联系人 */

- (IBAction)onUpContactsClick:(id)sender {
    
    m_listener.syncContacts();
}

/* 打包（上传联系人结果）查询*/

- (IBAction)onPackQueryClick:(id)sender {
    
    m_listener.packQuery();
}

/* 开始语音识别和语义理解 */

- (IBAction)_startRecordBtnHandler:(id)sender
{
    
    if (m_listener.getAgent() == NULL)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    [_startRecordBtn setEnabled:NO];
    
    if (!_isRecord)
    {
        [IFlyAudioSession initRecordingAudioSession];
        
        self.m_recorder = [IFlyPcmRecorder sharedInstance];
        
        self.m_recorder.delegate = self;
        
        [self.m_recorder start];
        
        _isRecord = true;
        
        [_popUpView showText:NSLocalizedString(@"RecordStart", nil)];
    }
    else
    {
         [_popUpView showText:NSLocalizedString(@"RecordStarted", nil)];
    }
    
}

/* 停止语音识别和语义理解 */

- (IBAction)stopRecordBtnHandler:(id)sender
{
    
    if (m_listener.getAgent() == NULL)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    if (_isRecord)
    {
        [self stop];
        
        [_popUpView showText:NSLocalizedString(@"RecordStop", nil)];
    }
    else
    {
        [_popUpView showText:NSLocalizedString(@"RecordNoStart", nil)];
    }
}

/*停止录音机录音（开发者可选用改接口自己实现单次交互控制）*/

-(void) stop
{
    [_startRecordBtn setEnabled:YES];
    
    if(self.m_recorder)
    {
        [self.m_recorder stop];
        self.m_recorder.delegate = nil;
    }
    
    _isRecord = false;
    
    sendAudioBuffer(NULL,0 ,true);
    
    [_textView resignFirstResponder];
}


-(void)onKeyBoardDown:(id) sender
{
    [_textView resignFirstResponder];
}

- (void) onIFlyRecorderBuffer: (const void *)buffer bufferSize:(int)size
{
    if(buffer != NULL && size > 0)
    {
        sendAudioBuffer(buffer,size,false);
    }
}

- (void) onIFlyRecorderError:(IFlyPcmRecorder*)recoder theError:(int) error
{
    NSLog(@"Error=%d",error);
}

/* 销毁Agent */
- (IBAction)onDestroyClick:(id)sender {
     [self stop];
    m_listener.destroyAgent();
     _textView.text = NSLocalizedString(@"weather", nil);
}

- (void)applicationWillResignActive:(NSNotification *)notification

{
    [self stop];
    _textView.text = NSLocalizedString(@"weather", nil);
}

@end

