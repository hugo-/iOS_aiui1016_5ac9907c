//
//  AIUIService.m
//  AIUIDemo_UI
//  Created on: 2018年1月1日
//      Author: 讯飞开放平台（http://aiui.xfyun.cn）
//

#import <Foundation/Foundation.h>
#import "PopupView.h"

#include "IFlyLocationRequest.h"
#include "AIUIService.h"
#include "Definition.h"
#include "writer.h"
#include "reader.h"


IAIUIAgent          *m_agent;
TestListener        m_listener;
IFlyLocationRequest *m_locationRequest;

void initAIUISetting()
{
    m_locationRequest = [[IFlyLocationRequest alloc] init];
    [m_locationRequest locationAsynRequest];
    
    NSArray     *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString    *cachePath = [paths objectAtIndex:0];
    
    cachePath = [cachePath stringByAppendingString:@"/"];
    
    NSLog(@"cachePath=%@",cachePath);
    
    AIUISetting::setSaveDataLog(false);
    AIUISetting::setLogLevel(_info);
    AIUISetting::setAIUIDir([cachePath UTF8String]);
    AIUISetting::setMscDir([cachePath UTF8String]);
    AIUISetting::initLogger([cachePath UTF8String]);
}

void sendAudioBuffer(const void *buffer ,int size , bool isEnd)
{
    if (NULL == m_agent)
    {
        return;
    }
    if(isEnd)
    {
        IAIUIMessage * stopWrite = IAIUIMessage::create(AIUIConstant::CMD_STOP_WRITE,
                                                        0, 0, "data_type=audio,sample_rate=16000");
        m_agent->sendMessage(stopWrite);
        stopWrite->destroy();
    }
    else
    {
        Buffer* pcmBuffer = Buffer::alloc(size);
        memcpy(pcmBuffer->data(), buffer, size);
        
        NSString *params = [[NSString alloc] initWithFormat:@"data_type=audio,sample_rate=16000"];
    
        if(m_locationRequest)
        {
            CLLocation *location = [m_locationRequest getLocation];
            if(location)
            {
                NSNumber *lng = nil;
                NSNumber *lat = nil;
                
                CLLocationCoordinate2D clm = [location coordinate];
                
                lng = [[NSNumber alloc] initWithDouble:round(clm.longitude * 100000000) / 100000000];
                lat = [[NSNumber alloc] initWithDouble:round(clm.latitude * 100000000) / 100000000];
                
                params = [[NSString alloc] initWithFormat:@"%@,msc.lng=%@,msc.lat=%@",params,lng.stringValue,lat.stringValue];
            }
        }
        if(NULL != m_agent)
        {
            IAIUIMessage * writeMsg = IAIUIMessage::create(AIUIConstant::CMD_WRITE,0, 0, [params UTF8String], pcmBuffer);
            m_agent->sendMessage(writeMsg);
            writeMsg->destroy();
        }
    }
}

/* 创建Agent */

void TestListener::createAgent()
{
    if (NULL != m_agent)
    {
        if (m_controller)
        {
            if (m_controller.popUpView)
            {
                [m_controller.popUpView showText:NSLocalizedString(@"agentExist", nil)];
            }
        }
        return;
    }
    /* 读取aiui.cfg配置文件 */
    NSString *appPath = [[NSBundle mainBundle] resourcePath];
    NSString *cfgFilePath = [[NSString alloc] initWithFormat:@"%@/aiui.cfg",appPath];
    NSString *cfg = [NSString stringWithContentsOfFile:cfgFilePath encoding:NSUTF8StringEncoding error:nil];
    
    /* 读取设置vad资源 */
    NSString *vadFilePath = [[NSString alloc] initWithFormat:@"%@/meta_vad_16k.jet",appPath];
    NSString *cfgString  = [cfg stringByReplacingOccurrencesOfString:@"vad_res_path" withString:vadFilePath];
    const char* cfgBuffer = [cfgString UTF8String];
    
    VA::Json::Value cfgParam;
    VA::Json::Reader reader;
    VA::Json::FastWriter writer;
    
    if(!reader.parse(cfgBuffer, cfgParam,false))
    {
        NSLog(@"parse error!,cfgBuffer=%s",cfgBuffer);
        return;
    }
    
    NSString *appidBuffer = APPID_VALUE;
    const char *appid = [appidBuffer  UTF8String];
    cfgParam["login"]["appid"]= appid;

    string cfgStr = writer.write(cfgParam);
    
    m_agent = IAIUIAgent::createAgent(cfgStr.c_str(),&m_listener);
}

 /* 唤醒 */
void TestListener::wakeUp()
{
    if (NULL != m_agent)
    {
        IAIUIMessage * wakeupMsg = IAIUIMessage::create(AIUIConstant::CMD_WAKEUP);
        m_agent->sendMessage(wakeupMsg);
        wakeupMsg->destroy();
    }
    else
    {
        if (m_controller)
        {
            if (m_controller.popUpView)
            {
                [m_controller.popUpView showText:NSLocalizedString(@"agentNull", nil)];
                return;
            }
        }
    }
}

 /* 销毁Agent */
void  TestListener::destroyAgent()
{
    if (NULL != m_agent)
    {
        m_agent->destroy();
        m_agent = NULL;
    }
    else
    {
        if(m_controller)
        {
            if(m_controller.popUpView)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [m_controller.popUpView showText:NSLocalizedString(@"agentNull", nil)];
                });
            }
        }
    }
}

/* 上传联系人 */
void TestListener::syncContacts()
{
    if (NULL != m_agent)
    {
        /* 联系人（如下）信息的base64编码
         *{"name":"刘德华", "phoneNumber":"13512345671"}
         *{"name":"张学友", "phoneNumber":"13512345672"}
         *{"name":"张右兵", "phoneNumber":"13512345673"}
         *{"name":"吴秀波", "phoneNumber":"13512345674"}
         *{"name":"黎晓明", "phoneNumber":"13512345675"}
         */
        const string contactsData = "eyJuYW1lIjoi5YiY5b635Y2OIiwgInBob25lTnVtYmVyIjoiMTM1MTIzNDU2NzEifQp7Im5hbWUiOiLlvKDlrablj4siLCAicGhvbmVOdW1iZXIiOiIxMzUxMjM0NTY3MiJ9CnsibmFtZSI6IuW8oOWPs+WFtSIsICJwaG9uZU51bWJlciI6IjEzNTEyMzQ1NjczIn0KeyJuYW1lIjoi5ZC056eA5rOiIiwgInBob25lTnVtYmVyIjoiMTM1MTIzNDU2NzQifQp7Im5hbWUiOiLpu47mmZMiLCAicGhvbmVOdW1iZXIiOiIxMzUxMjM0NTY3NSJ9";
    
        VA::Json::Value paramJson;
        paramJson["id_name"] = "uid";
        paramJson["res_name"] = "IFLYTEK.telephone_contact";
        
        VA::Json::Value dataJson;
        dataJson["param"]=paramJson;
        dataJson["data"]= contactsData;
        
        VA::Json::FastWriter writer;
        string dataStr = writer.write(dataJson);
        
        Buffer* dataBuffer = Buffer::alloc(dataStr.length() + 1);
        dataStr.copy((char*) dataBuffer->data(), dataStr.length() + 1);
        
        VA::Json::Value param;
        param["tag"] = "abc";
        VA::Json::FastWriter paramWriter;
        string paramStr = paramWriter.write(param);
        
        IAIUIMessage* syncMsg=IAIUIMessage::create(AIUIConstant::CMD_SYNC,AIUIConstant::SYNC_DATA_SCHEMA,0, paramStr.c_str(), dataBuffer);
        
        m_agent->sendMessage(syncMsg);
    }
    else
    {
        if (m_controller)
        {
            if (m_controller.popUpView)
            {
                [m_controller.popUpView showText:NSLocalizedString(@"agentNull", nil)];
            }
        }
    }
}

/* 打包查询 */
void TestListener::packQuery()
{
    if ( NULL != m_agent)
    {
        if (g_sid.empty())
        {
            if(m_controller)
            {
                if(m_controller.textView)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        m_controller.textView.text = NSLocalizedString(@"syncNotYet", nil);
                        
                    });
                }
            }
            return;
        }
        
        VA::Json::Value queryJson;
        queryJson["sid"] = g_sid;
        VA::Json::FastWriter writer;
        string dataStr = writer.write(queryJson);
        
        IAIUIMessage* queryMsg=IAIUIMessage::create(AIUIConstant::CMD_QUERY_SYNC_STATUS,
                                                    AIUIConstant::SYNC_DATA_SCHEMA,0,dataStr.c_str(),NULL);
        
        m_agent->sendMessage(queryMsg);
    } else
    {
        if (m_controller)
        {
            if (m_controller.popUpView)
            {
                [m_controller.popUpView showText:NSLocalizedString(@"agentNull", nil)];
            }
        }
    }
}

void TestListener::onSetController(UnderstandViewController *param)
{
    m_controller = param;
}

/* 文本语义理解 */
void TestListener::sendTextMessage(string question)
{
    if (NULL != m_agent)
    {
        //wakeUp();
        
        Buffer* textData = Buffer::alloc(question.length());
        question.copy((char*) textData->data(), question.length());
        
        IAIUIMessage* writeMsg=IAIUIMessage::create(AIUIConstant::CMD_WRITE,0,0,"data_type=text",textData);
        m_agent->sendMessage(writeMsg);
        writeMsg->destroy();
    }
}


IAIUIAgent* TestListener::getAgent()
{
    return m_agent;
}

/* 事件回调 */
void TestListener::onEvent(const IAIUIEvent& event) const
{
    switch (event.getEventType())
    {
        case AIUIConstant::EVENT_CONNECTED_TO_SERVER:
        {
            if(m_controller){
                if(m_controller.popUpView)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [m_controller.popUpView showText:@"CONNECT TO SERVER"];
                    });
                }
            }
        }
            break;
        case AIUIConstant::EVENT_SERVER_DISCONNECTED:
        {
            if(m_controller){
                if(m_controller.popUpView)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [m_controller.popUpView showText:@"DISCONNECT TO SERVER"];
                    });
                }
            }
        }
            break;
        case AIUIConstant::EVENT_STATE:
        {
            switch (event.getArg1())
            {
                case AIUIConstant::STATE_IDLE:
                {
                    NSLog(@"EVENT_STATE IDLE");
                    if(m_controller){
                        if(m_controller.popUpView)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [m_controller.popUpView showText:@"EVENT_STATE IDLE"];
                            });
                        }
                    }
                }
                    break;
                    
                case AIUIConstant::STATE_READY:
                {
                    NSLog(@"EVENT_STATE READY");
                    if(m_controller)
                    {
                        if(m_controller.popUpView)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [m_controller.popUpView showText:@"EVENT_STATE READY"];
                            });
                        }
                    }
                }
                    break;
                    
                case AIUIConstant::STATE_WORKING:
                {
                    NSLog(@"EVENT_STATE WORKING");
                    if(m_controller)
                    {
                        if(m_controller.popUpView)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [m_controller.popUpView showText:@"EVENT_STATE WORKING"];
                            });
                        }
                    }
                }
                    break;
                default:
                    NSLog(@"EVENT_STATE event.getArg1()=%d",event.getArg1());
                    break;
            }
        } break;
            
        case AIUIConstant::EVENT_WAKEUP:
        {
            NSLog(@"EVENT_WAKEUP: arg1=%d arg2=%d,info=%s", event.getArg1(), event.getArg2(), event.getInfo());
        } break;
            
        case AIUIConstant::EVENT_SLEEP:
        {
            NSLog(@"EVENT_SLEEP: arg1=%d",event.getArg1());
        } break;
            
        case AIUIConstant::EVENT_VAD:
        {
            switch (event.getArg1())
            {
                case AIUIConstant::VAD_BOS:
                {
                    NSLog(@"EVENT_VAD VAD_BOS");
                } break;
                    
                case AIUIConstant::VAD_EOS:
                {
                    NSLog(@"EVENT_VAD VAD_EOS");
                } break;
                    
                case AIUIConstant::VAD_VOL:
                {
                    if(m_controller)
                    {
                        if(m_controller.popUpView)
                        {
                            NSString *volume = [[NSString alloc] initWithFormat:@"Volume:%d",event.getArg2()];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [m_controller.popUpView showText:volume];
                            });
                        }
                    }
                } break;
            }
        }break;
            
        case AIUIConstant::EVENT_RESULT:
        {
            NSLog(@"************EVENT_RESULT***************start");
            
            VA::Json::Value bizParamJson;
            VA::Json::Reader reader;
            
            if(!reader.parse(event.getInfo(), bizParamJson,false))
            {
                NSLog(@"parse error!,getinfo=%s",event.getInfo());
            }
            
            VA::Json::Value data = (bizParamJson["data"])[0];
            VA::Json::Value params = data["params"];
            VA::Json::Value content = (data["content"])[0];
            std::string sub =  params["sub"].asString();
            
            if(sub == "nlp")
            {
                VA::Json::Value empty;
                VA::Json::Value contentId = content.get("cnt_id", empty);
                
                if(contentId.empty())
                {
                    NSLog(@"Content Id is empty");
                    break;
                }
                
                string cnt_id = contentId.asString();
                
                Buffer *buffer = event.getData()->getBinary(cnt_id.c_str());
                
                if(NULL != buffer)
                {
                    
                    const char * resultStr = (char *) buffer->data();
                    if(resultStr == NULL)
                    {
                        return;
                    }
                    
                    NSLog(@"resultStr=%s",resultStr);
                    if(m_controller)
                    {
                        if(m_controller.textView)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSString *retInfo = [[NSString alloc] initWithUTF8String:resultStr];
                                if (retInfo.length > 20)
                                {
                                    
                                    m_controller.textView.text = retInfo;
                                    m_controller.textView.layoutManager.allowsNonContiguousLayout = NO;
                                    [m_controller.textView scrollRangeToVisible:NSMakeRange(m_controller.textView.text.length, 1)];
                                }
                            });
                        }
                    }
                }
            }
            
            const char *info  = event.getInfo();
            if(info != NULL)
            {
                NSLog(@"result info=%s",event.getInfo());
            }
            
        } break;
            
        case AIUIConstant::EVENT_ERROR:
        {
            NSString *retInfo = [[NSString alloc] initWithFormat:@"Error Message：%s\nError Code：%d",event.getInfo(),event.getArg1()];
            
            NSLog(@"EVENT_ERROR,info=%s,arg1=%d",event.getInfo(),event.getArg1());
            
            if(m_controller)
            {
                if(m_controller.textView)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        m_controller.textView.text = retInfo;
                    });
                }
            }
        } break;
            
        case AIUIConstant::EVENT_CMD_RETURN:
        {
            if(AIUIConstant::CMD_SYNC == event.getArg1())
            {
                int retcode = event.getArg2();
                int dtype =event.getData()->getInt("sync_dtype", -1);
                switch (dtype)
                {
                    case AIUIConstant::SYNC_DATA_SCHEMA:
                    {
                        string sid = event.getData()->getString("sid", "");
                        g_sid = sid;
                        
                        if (AIUIConstant::SUCCESS == retcode)
                        {
                            if(m_controller)
                            {
                                if(m_controller.textView)
                                {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        m_controller.textView.text = NSLocalizedString(@"syncSuccess", nil);;
                                        
                                    });
                                }
                            }
                        }
                        else
                        {
                            if(m_controller)
                            {
                                if(m_controller.textView)
                                {
                                    NSString *retCode = [[NSString alloc] initWithFormat:@"retcode:%d",retcode];
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        m_controller.textView.text = retCode;
                                    });
                                }
                            }
                        }
                        NSLog(@"sid=%s",sid.c_str());
                    } break;
                        
                    case AIUIConstant::SYNC_DATA_QUERY:
                    {
                        if (AIUIConstant::SUCCESS == retcode)
                        {
                            NSLog(@"sync query success");
                        }
                        else
                        {
                            NSLog(@"sync query error= %d",retcode);
                        }
                    } break;
                }
            }else if(AIUIConstant::CMD_QUERY_SYNC_STATUS == event.getArg1())
            {
                int syncType = event.getData()->getInt("sync_dtype", -1);
                
                if (AIUIConstant::SYNC_DATA_QUERY == syncType)
                {
                    string result = event.getData()->getString("result","");
                    
                    if(m_controller)
                    {
                        if(m_controller.textView)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSString *retInfo = [[NSString alloc] initWithUTF8String:result.c_str()];
                                m_controller.textView.text = retInfo;
                            });
                        }
                    }
                }
            }
        }default:break;
    }
}
