//
//  IFlyAudioSession.m
//  AIUIDemo
//
//  Created on: 2018年1月1日
//      Author: 讯飞开放平台（http://aiui.xfyun.cn）
//
//

#import "IFlyAudioSession.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioSession.h>
#import <UIKit/UIDevice.h>

@implementation IFlyAudioSession
+(void) initPlayingAudioSession:(BOOL)isMPCenter
{
    IFlyLogD(@"%s",__func__);
    
    AVAudioSession * avSession = [AVAudioSession sharedInstance];
    BOOL success;
    NSError * setCategoryError;
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        if ([avSession.category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
            success = [avSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionAllowBluetooth error:&setCategoryError];
            if (!success) {
                IFlyLogD(@"%s| AVAudioSessionCategory PlayAndRecord error:@%",__func__,setCategoryError);
            }
        }
        else
        {
            if(!isMPCenter)
            {
                if (![avSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&setCategoryError])
                {
                    IFlyLogD(@"%s| AVAudioSessionCategory Playback error:@%",__func__,setCategoryError);
                }
            }
        }
    }
    else
    {
        OSStatus error ;
        UInt32 orignalCategory = kAudioSessionCategory_MediaPlayback ;
        UInt32 sessionCategory1 = kAudioSessionCategory_MediaPlayback;
        UInt32 propertySize = sizeof(orignalCategory);
        AudioSessionGetProperty(kAudioSessionProperty_AudioCategory,&propertySize,&orignalCategory);
        if (orignalCategory == kAudioSessionCategory_PlayAndRecord) {
            sessionCategory1 = kAudioSessionCategory_PlayAndRecord;
        }
        else
        {
            sessionCategory1 = kAudioSessionCategory_MediaPlayback;
        }
        
        error = AudioSessionSetProperty (
                                         kAudioSessionProperty_AudioCategory,
                                         sizeof (sessionCategory1),
                                         &sessionCategory1
                                         );
        if (error) {
            IFlyLogD(@"%s| AudioSessionSetProperty kAudioSessionProperty_AudioCategory error",__func__);
        }
        UInt32 audioRouteOverride = 1;
        error = AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof (audioRouteOverride),&audioRouteOverride);
        if (error) {
            IFlyLogD(@"%s|AudioSessionSetProperty kAudioSessionProperty_OverrideCategoryDefaultToSpeaker error:%ld", __func__,error);
        }
        
        //Modifying a recording category to support Bluetooth input
        UInt32 allowBluetoothInput = 1;
        AudioSessionSetProperty (
                                 
                                 kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
                                 
                                 sizeof (allowBluetoothInput),
                                 
                                 &allowBluetoothInput
                                 
                                 );
    }

}

+(BOOL) initRecordingAudioSession
{
    IFlyLogD(@"%s",__func__);
    
    AVAudioSession * avSession = [AVAudioSession sharedInstance];
    BOOL success;
    NSError * setCategoryError;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending)
    {
        success = [avSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionAllowBluetooth error:&setCategoryError];
        if (!success) {
            IFlyLogD(@"%s| AVAudioSessionCategoryOptionAllowBluetooth error:@%",__func__,setCategoryError);
        }
    }
    else
    {
        OSStatus error;
        UInt32 category = kAudioSessionCategory_PlayAndRecord;
        UInt32 size;
        error = AudioSessionGetPropertySize(kAudioSessionProperty_AudioCategory, &size);
        if (error) {
            IFlyLogD(@"%s|AudioSessionGetPropertySize error:%ld",__func__,error);
        }
        error = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
        if (error) {
            IFlyLogD(@"%s|AudioSessionSetProperty error:%ld", __func__,error);
            return NO;
        }
        
        UInt32 audioRouteOverride = 1;
        error = AudioSessionGetPropertySize(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, &size);
        if (error) {
            IFlyLogD(@"%s|AudioSessionGetPropertySize kAudioSessionProperty_OverrideCategoryDefaultToSpeaker error", __func__);
            return NO;
        }
        error = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker,sizeof(audioRouteOverride),&audioRouteOverride);
        if (error) {
            IFlyLogD(@"%s|AudioSessionSetProperty kAudioSessionProperty_OverrideCategoryDefaultToSpeaker error:%ld", __func__,error);
            return NO;
        }
        
        error = AudioSessionGetPropertySize(kAudioSessionProperty_OverrideCategoryEnableBluetoothInput, &size);
        if (error) {
            IFlyLogD(@"%s|AudioSessionGetPropertySize kAudioSessionProperty_OverrideCategoryEnableBluetoothInput error:%ld", __func__,error);
            return NO;
        }
        //Modifying a recording category to support Bluetooth input
        UInt32 allowBluetoothInput = TRUE;
        error = AudioSessionSetProperty
                                (kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
                                 sizeof (allowBluetoothInput),
                                 &allowBluetoothInput
                                 );
        if (error) {
            IFlyLogD(@"%s|AudioSessionSetProperty kAudioSessionProperty_OverrideCategoryEnableBluetoothInput error:%ld", __func__,error);
            return NO;
        }
    }
    return YES;
}
@end
