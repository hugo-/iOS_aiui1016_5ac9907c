//
//  IFlyPcmRecorder.m
//
//  Created on: 2018年1月1日
//      Author: 讯飞开放平台（http://aiui.xfyun.cn）
//

#import "IFlyPcmRecorder.h"
#import <UIKit/UIKit.h>



#define NUM_BUFFERS 10
#define RECORD_CYCLE   0.003    //录音音量回调时间间隔

/**
 *  内部录音单元
 */
typedef struct{
    AudioFileID                 audioFile;
    AudioStreamBasicDescription dataFormat;
    AudioQueueRef               queue;
    AudioQueueLevelMeterState	*audioLevels;
    AudioQueueBufferRef         buffers[NUM_BUFFERS];
    UInt32                      bufferByteSize;
    SInt64                      currentPacket;
    BOOL                        recording;
    IFlyPcmRecorder             *recorder;
    
} IFlyRecordState;

@interface IFlyPcmRecorder(){
    IFlyRecordState state; //内部录音单元
}

@property(nonatomic,assign)Float64  mSampleRate;	//采样率
@property(nonatomic,assign)UInt32   mBits;		    //比特率
@property(nonatomic,assign)UInt32   mChannels;		//声道数
@property(nonatomic,retain)NSTimer* mGetPowerTimer; //音量获取时钟
@property(nonatomic,assign)NSString* mSaveAudioPath; //保存文件路径
@property(nonatomic,assign)FILE*    mSaveFile;       //保存文件句柄

@property(nonatomic,assign)float    mPowerGetCycle;  //音量获取时间间隔


- (void)setupAudioFormat:(AudioStreamBasicDescription*)format;

void AQRecordRecordListenBack(void * inUserData,AudioQueueRef inAQ,AudioQueuePropertyID inID);
void interruptionListener(void * inClientData, UInt32 inInterruptionState);
void HandleInputBuffer (void *aqData,AudioQueueRef inAQ,AudioQueueBufferRef inBuffer,const AudioTimeStamp *inStartTime,UInt32 inNumPackets,const AudioStreamPacketDescription *inPacketDesc);
void DeriveBufferSize (AudioQueueRef audioQueue,AudioStreamBasicDescription ASBDescription, Float64 seconds, UInt32 *outBufferSize);

@end

static IFlyPcmRecorder *iFlyPcmRecorder = nil;

@implementation IFlyPcmRecorder

@synthesize delegate = _delegate;
@synthesize mSampleRate;
@synthesize mBits;
@synthesize mChannels;
@synthesize mGetPowerTimer;
@synthesize mSaveAudioPath;
@synthesize mSaveFile;
@synthesize mPowerGetCycle;

#pragma mark - system
- (instancetype) init{
    if (self = [super init]) {
        state.recording = NO;
        state.recorder = self;
        
        mSampleRate = 16000.0;
        mBits = 16;
        mChannels = 1;
        [self setupAudioFormat : &state.dataFormat];
        
        state.currentPacket = 0;
        
        mSaveAudioPath = nil;
        mSaveFile = NULL;
        
        mPowerGetCycle = RECORD_CYCLE;
        
        _isNeedDeActive = YES;
        
    }
    return self;
}

- (void) dealloc{
    self.delegate = nil;
    [self SetGetPowerTimerInvalidate];
    if(mSaveAudioPath)
    {
        [mSaveAudioPath release];
        mSaveAudioPath = nil;
    }

    [super dealloc];
}

+ (instancetype) sharedInstance{
    if (iFlyPcmRecorder == nil) {
        iFlyPcmRecorder = [[IFlyPcmRecorder alloc] init];
    }
    return iFlyPcmRecorder;
}

#pragma mark - system call back

void AQRecordRecordListenBack(void * inUserData,AudioQueueRef inAQ,AudioQueuePropertyID inID){
    IFlyRecordState *state = inUserData;
	UInt32 running;
	UInt32 size;
    OSStatus err ;

    AudioQueueGetPropertySize(inAQ, kAudioQueueProperty_IsRunning, &size);
	err = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &running, &size);
	if (err){
		IFlyLogD( @"get kAudioQueueProperty_IsRunning error:%d", err);
		return;
	}
    if (!running){
        IFlyLogD(@"stop recording success");
        
        if(state->recorder && state->recorder->mSaveFile){
            fclose(state->recorder->mSaveFile);
            state->recorder->mSaveFile = NULL;
        }
        
        if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending){
            [[NSNotificationCenter defaultCenter]removeObserver:state->recorder  name:AVAudioSessionInterruptionNotification object:nil];
        }
        else{
            if ([[AVAudioSession sharedInstance] delegate]== state->recorder){
                [[AVAudioSession sharedInstance] setDelegate:nil];
            }
        }
        
        if(state->recorder->_isNeedDeActive){
            [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:NULL];
        }
        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [state->recorder freeRecorderRes];
//        });
    }
}


void HandleInputBuffer (void *aqData,AudioQueueRef inAQ,AudioQueueBufferRef inBuffer,const AudioTimeStamp *inStartTime,UInt32 inNumPackets,const AudioStreamPacketDescription   *inPacketDesc){
    IFlyRecordState *pAqData = (IFlyRecordState *) aqData;
    IFlyPcmRecorder *recorder = pAqData->recorder;
    
    //音量回调放在第一块音频输出时才调用，避免外部说话时机先于录音启动
    if(!recorder->mGetPowerTimer && recorder->_delegate){
        recorder->mGetPowerTimer = [NSTimer scheduledTimerWithTimeInterval:recorder->mPowerGetCycle target:recorder selector:@selector(getPower) userInfo:nil repeats:YES];//RECORD_CYCLE
        
        //确保录音音量不会被屏幕的点击事件所干扰
        [[NSRunLoop currentRunLoop] addTimer:recorder->mGetPowerTimer forMode:NSRunLoopCommonModes];
        
        [recorder->mGetPowerTimer fire];
    }
    
    if (inNumPackets == 0 && pAqData->dataFormat.mBytesPerPacket != 0){
        inNumPackets = inBuffer->mAudioDataByteSize / pAqData->dataFormat.mBytesPerPacket;
    }
    
    if (recorder.delegate){
        //保存文件
        if(recorder->mSaveFile != NULL){
            fseek(recorder->mSaveFile, 0, SEEK_END);
            fwrite(inBuffer->mAudioData, inBuffer->mAudioDataByteSize, 1, recorder->mSaveFile);
        }
        [recorder.delegate onIFlyRecorderBuffer:inBuffer->mAudioData bufferSize:inBuffer->mAudioDataByteSize];
    }
    
    pAqData->currentPacket += inNumPackets;
    if (pAqData->recording == 0){
        return;
    }
    
    AudioQueueEnqueueBuffer (pAqData->queue,inBuffer,0,NULL);
}

void DeriveBufferSize (AudioQueueRef audioQueue,AudioStreamBasicDescription ASBDescription,Float64 seconds,UInt32 *outBufferSize){
    static const int maxBufferSize = 0x50000;
    int maxPacketSize = ASBDescription.mBytesPerPacket;
    if (maxPacketSize == 0){
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty (audioQueue,kAudioConverterPropertyMaximumOutputPacketSize,&maxPacketSize,&maxVBRPacketSize);
    }
    
    Float64 numBytesForTime =ASBDescription.mSampleRate * maxPacketSize * seconds;
    *outBufferSize =  (UInt32) ((numBytesForTime < maxBufferSize) ? numBytesForTime : maxBufferSize);                     // 9
}


#pragma mark - funcs


/**
 *  开始录音
 *  在开始录音前可以调用IFlyAudioSession +(BOOL) initRecordingAudioSession; 方法初始化音频队列
 *
 *  @return  开启录音成功返回YES，否则返回NO
 */
- (BOOL) start{
    
    @synchronized(self) {
        
        IFlyLogD(@"%s,[IN]",__func__);
        
        NSDate *startDate = [NSDate date];
        OSStatus error = 0;
        NSError *avError;
        
        if(![self canRecord]){
            IFlyLogD(@"%s System Recorder no permission",__func__);
            return NO;
        }
        
        BOOL success = [[AVAudioSession sharedInstance] setActive:YES error:&avError];
        if (!success){
            IFlyLogD(@"%s| avSession setActive YES error:@%",__func__,avError);
        }
        
        error= AudioQueueNewInput(&state.dataFormat,HandleInputBuffer,&state,CFRunLoopGetCurrent(),kCFRunLoopCommonModes,0,&state.queue);
        if (error){
            IFlyLogD(@"%s|AudioQueueNewInput error",__func__);
            //终止获取录音音量timer
            [self SetGetPowerTimerInvalidate];
            return NO;
        }
        
        DeriveBufferSize(state.queue, state.dataFormat, 0.15, &state.bufferByteSize);
        
        for(int i = 0; i < NUM_BUFFERS; i++){
            error = AudioQueueAllocateBuffer(state.queue,state.bufferByteSize,&state.buffers[i]);
            if (error){
                IFlyLogD(@"%s|AudioQueueAllocateBuffer error",__func__);
                [self SetGetPowerTimerInvalidate];
                return NO;
            }
            
            error = AudioQueueEnqueueBuffer(state.queue, state.buffers[i], 0, NULL);
            if (error){
                IFlyLogD(@"%s|AudioQueueEnqueueBuffer error",__func__);
                [self SetGetPowerTimerInvalidate];
                return NO;
            }
        }
        
        error = AudioQueueAddPropertyListener(state.queue, kAudioQueueProperty_IsRunning, AQRecordRecordListenBack, &state);
        if (error){
            IFlyLogD(@"%s| AudioQueueAddPropertyListener error:%d",__func__,error);
            [self SetGetPowerTimerInvalidate];
            return NO;
        }

        
        error = AudioQueueStart(state.queue, NULL);
        NSDate *endDate = [NSDate date];
        NSTimeInterval timeValue = [endDate timeIntervalSinceDate:startDate];
        IFlyLogD(@"pcmRecorder|timeValue:%f",timeValue);
        if (error != 0) {
            IFlyLogD(@"%s|AudioQueueStart error",__func__);
            AudioQueueStop(state.queue, YES);
            [self SetGetPowerTimerInvalidate];
            return NO;
        }

        // allocate the memory needed to store audio level information
        state.audioLevels = (AudioQueueLevelMeterState *) calloc (sizeof (AudioQueueLevelMeterState), mChannels);

        UInt32 trueValue = true;
        AudioQueueSetProperty (state.queue,kAudioQueueProperty_EnableLevelMetering,&trueValue,sizeof (UInt32));
        state.currentPacket = 0;
        state.recording = YES;
        
        if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending){
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruption:) name:AVAudioSessionInterruptionNotification object:nil];
        }
        else{
            [[AVAudioSession sharedInstance] setDelegate:self];
        }

        //打开文件
        if(mSaveFile == NULL){
            //删除之前文件
            mSaveFile = fopen([mSaveAudioPath UTF8String], "rb");
            if(mSaveFile){
                fclose(mSaveFile);
                mSaveFile = nil;
                remove([mSaveAudioPath UTF8String]);
            }
            mSaveFile = fopen([mSaveAudioPath UTF8String], "wb+");
        }

        IFlyLogD(@"%s,[OUT],ret =%d",__func__,error);
        
        return YES;

    }
}

- (void) stop{
    
    @synchronized(self) {
        
        IFlyLogD(@"%s[IN]",__func__);
        
        //xlhou add
        if(!state.queue){
            return;
        }
        
        //终止获取录音音量timer
        [self SetGetPowerTimerInvalidate];
        
        _delegate = nil;
        
        if (state.recording== YES){
            OSStatus error ;
            error = AudioQueueFlush(state.queue);
            if (error){
                IFlyLogD(@"%s|AudioQueueFlush error", __func__);
            }

            IFlyLogD(@"%s|AudioQueueFlush", __func__);
            
            error = AudioQueueStop(state.queue, true);
            if (error){
                IFlyLogD(@"%s|AudioQueueStop error", __func__);
            }
            IFlyLogD(@"%s|AudioQueueStop", __func__);
            
            state.recording = NO;
            error = AudioQueueDispose(state.queue, true);
            if (error){
                IFlyLogD(@"%s|AudioQueueDispose error", __func__);
            }
            IFlyLogD(@"%s|AudioQueueDispose", __func__);

            if(state.audioLevels){
                free(state.audioLevels);
                state.audioLevels = NULL;
            }
        }
        
        IFlyLogD(@"%s[OUT]",__func__);
    }
}

/*
 * 设置sample参数
 */
- (void) setSample:(NSString *) rate{
    
    IFlyLogD(@"%s,rate=%@",__func__,rate);
     mSampleRate=[rate floatValue];
    [self setupAudioFormat : &state.dataFormat];
}

/*
 * 设置录音时间间隔参数
 */
- (void) setPowerCycle:(float) cycle{
    
    IFlyLogD(@"%s",__func__);
    
    mPowerGetCycle = cycle;
}


/*
 * 设置保存路径
 */
-(void) setSaveAudioPath:(NSString *)savePath{
    if(mSaveAudioPath)
    {
        [mSaveAudioPath release];
        mSaveAudioPath = nil;
    }
    
    if(savePath.length > 0)
    {
        mSaveAudioPath = [[NSString alloc] initWithFormat:@"%@",savePath];
    }
}

#pragma mark - private

//- (void)freeRecorderRes{
//    
//    AudioQueueRemovePropertyListener(state.queue, kAudioQueueProperty_IsRunning, AQRecordRecordListenBack, &state);
//    
//    OSStatus error ;
//    error = AudioQueueDispose(state.queue, true);
//    if (error){
//        IFlyLogD(@"%s|AudioQueueDispose error", __func__];
//    }
//    IFlyLogD(@"%s|AudioQueueDispose", __func__];
//    
//    if(_isNeedDeActive){
//        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:NULL];
//    }
//}

- (void)SetGetPowerTimerInvalidate{
    if(mGetPowerTimer){
        [mGetPowerTimer invalidate];
        mGetPowerTimer=nil;
    }
}

- (BOOL)canRecord{
    __block BOOL bCanRecord = YES;
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending){
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]){
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted){
                if (granted) {
                    bCanRecord = YES;
                } else {
                    bCanRecord = NO;
                }
            }];
        }
    }
    
    return bCanRecord;
}

- (void)setupAudioFormat:(AudioStreamBasicDescription*)format{
	format->mSampleRate = mSampleRate;
	format->mFormatID = kAudioFormatLinearPCM;
	format->mFormatFlags = kLinearPCMFormatFlagIsSignedInteger| kLinearPCMFormatFlagIsPacked;
	
	format->mChannelsPerFrame = mChannels;
	format->mBitsPerChannel = mBits;
	format->mFramesPerPacket = 1;
	format->mBytesPerPacket = 2;
	
	format->mBytesPerFrame = 2;		// not used, apparently required
	format->mReserved = 0;
}

- (void) pauseRecorder{
    
    @synchronized(self) {
        
        if(state.recording){
            [self SetGetPowerTimerInvalidate];
        }
        
        OSStatus error ;
        error = AudioQueuePause(state.queue);
        if (error){
            IFlyLogD(@"puase Recorder error");
        }
    }
}

- (void) resumeRecorder{
    
    @synchronized(self) {
        
        OSStatus error = AudioQueueStart(state.queue, NULL);
        if (error){
            IFlyLogD(@"resume Recorder error");
        }
        else{
            if(state.recording){
                mGetPowerTimer = [NSTimer scheduledTimerWithTimeInterval:mPowerGetCycle target:self selector:@selector(getPower) userInfo:nil repeats:YES];
                [[NSRunLoop currentRunLoop] addTimer:mGetPowerTimer forMode:NSRunLoopCommonModes];
                [mGetPowerTimer fire];
            }
        }
    }
}

/*
 获取音量
 */
-(void) getPower{
    
    @synchronized(self) {
        
        if(state.recording){
            UInt32 propertySize = mChannels * sizeof (AudioQueueLevelMeterState);
            OSStatus error=AudioQueueGetProperty (state.queue,(AudioQueuePropertyID) kAudioQueueProperty_CurrentLevelMeter,state.audioLevels,&propertySize);
            if(error){
                IFlyLogD(@"%s|getPower error", __func__);
                return;
            }
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(onIFlyRecorderVolumeChanged:)]){
            //录音开始，并来电时，state.audioLevels有可能为空
            if(state.audioLevels){
                int volume = state.audioLevels[0].mPeakPower *30;
                //volume超过30时，按照30处理，注意volume处理后的值是可能大于30的，并不需要按照其最大值来30等分，因为人的录音音量的跨度没有机器允许的值这么大。总之处理不当会引起录音的波形不明显。
                if(volume> 30){
                    volume = 30;
                }
                [_delegate onIFlyRecorderVolumeChanged:volume];
            }
        }
    }
}

-(void)beginInterruption{
    [self pauseRecorder];
    //[self stop];
    NSLog(@"beginInterruption");
}

-(void)endInterruption{
    [self stop];
    //[self start];
    //[self resumeRecorder];
    NSLog(@"endInterruption");
}

//Interruption handler
-(void) interruption:(NSNotification*) aNotification{
    NSDictionary *interuptionDict = aNotification.userInfo;
    NSNumber* interuptionType = (NSNumber*)[interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey];
    if([interuptionType intValue] == AVAudioSessionInterruptionTypeBegan){
        [self beginInterruption];
    }
    else if ([interuptionType intValue] == AVAudioSessionInterruptionTypeEnded){
        [self endInterruption];
    }
}


@end
