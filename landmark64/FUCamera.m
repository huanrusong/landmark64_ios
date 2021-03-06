//
//  FUCamera.m
//  rtcengine
//
//  Created by zhangxu on 2017/8/4.
//  Copyright © 2017年 宦如松. All rights reserved.
//

#import "FUCamera.h"
#import <UIKit/UIKit.h>
//#import <SVProgressHUD/SVProgressHUD.h>

typedef enum : NSUInteger {
    CommonMode,
    PhotoTakeMode
} RunMode;

@interface FUCamera()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate>
{
    RunMode runMode;
    NSArray<__kindof AVMetadataObject *> *currentMetadata;
    dispatch_queue_t face_queue;
}
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureDeviceInput       *backCameraInput;//后置摄像头输入
@property (strong, nonatomic) AVCaptureDeviceInput       *frontCameraInput;//前置摄像头输入
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureDevice *camera;

@property (assign, nonatomic) AVCaptureDevicePosition cameraPosition;
@property (assign, nonatomic) int captureFormat;
@property (assign, nonatomic) NSString* setResolution;
//预览层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation FUCamera

- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition captureFormat:(int)captureFormat
{
    if (self = [super init]) {
        self.cameraPosition = cameraPosition;
        self.captureFormat = captureFormat;
    }
    return self;
}

- (void)setCameroResolution:(int)resolutionLevel
{
    switch (resolutionLevel) {
        case 0:
            _setResolution =AVCaptureSessionPreset640x480;
            break;
        case 1:
            _setResolution =AVCaptureSessionPreset1280x720;
            break;
        case 2:
            _setResolution =AVCaptureSessionPreset352x288;
            break;
        default:
            _setResolution =AVCaptureSessionPreset640x480;
            break;
    }
}
- (instancetype)init
{
    if (self = [super init]) {
        self.cameraPosition = AVCaptureDevicePositionFront;
        self.captureFormat = kCVPixelFormatType_32BGRA;
        self.setResolution =AVCaptureSessionPreset640x480;
        //self.captureFormat = kCMPixelFormat_32ARGB;
    }
    return self;
}

- (void)startUp{
    [self startCapture];
}

- (void)startCapture{
    if (![self.captureSession isRunning]) {
        [self.captureSession startRunning];
    }
    
}

- (void)stopCapture{
    if ([self.captureSession isRunning]) {
        [self.captureSession stopRunning];
    }
}

- (AVCaptureSession *)captureSession
{
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
       // _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
        _captureSession.sessionPreset = _setResolution;
        
        face_queue = dispatch_queue_create("hrs.landmark64.faceQueue", NULL);
        AVCaptureDeviceInput *deviceInput = self.isFrontCamera ? self.frontCameraInput:self.backCameraInput;
        
        if ([_captureSession canAddInput: deviceInput]) {
            [_captureSession addInput: deviceInput];
        }
        
        AVCaptureMetadataOutput* metaOutput = [[AVCaptureMetadataOutput alloc]init];
        [metaOutput setMetadataObjectsDelegate:self queue: face_queue];
        if ([_captureSession canAddOutput:self.videoOutput]) {
            [_captureSession addOutput:self.videoOutput];
        }
        if ([_captureSession canAddOutput:metaOutput]) {
            [_captureSession addOutput:metaOutput];
        }
        metaOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];

        [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        if (self.videoConnection.supportsVideoMirroring) {
            self.videoConnection.videoMirrored = YES;
        }
        
        [_captureSession beginConfiguration]; // the session to which the receiver's AVCaptureDeviceInput is added.
        if ( [deviceInput.device lockForConfiguration:NULL] ) {
            [deviceInput.device setActiveVideoMinFrameDuration:CMTimeMake(1, 15)];
            [deviceInput.device setActiveVideoMaxFrameDuration:CMTimeMake(1, 15)];
            [deviceInput.device unlockForConfiguration];
        }
        [_captureSession commitConfiguration]; //
    }
    return _captureSession;
}

//后置摄像头输入
- (AVCaptureDeviceInput *)backCameraInput {
    if (_backCameraInput == nil) {
        NSError *error;
        _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        if (error) {
            NSLog(@"获取后置摄像头失败~");
        }
    }
    self.camera = _backCameraInput.device;
    return _backCameraInput;
}

//前置摄像头输入
- (AVCaptureDeviceInput *)frontCameraInput {
    if (_frontCameraInput == nil) {
        NSError *error;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        if (error) {
            NSLog(@"获取前置摄像头失败~");
        }
    }
    self.camera = _frontCameraInput.device;
    return _frontCameraInput;
}

//返回前置摄像头
- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

//返回后置摄像头
- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

//切换前后置摄像头
- (void)changeCameraInputDeviceisFront:(BOOL)isFront {
    
    if (isFront) {
        [self.captureSession stopRunning];
        [self.captureSession removeInput:self.backCameraInput];
        if ([self.captureSession canAddInput:self.frontCameraInput]) {
            [self.captureSession addInput:self.frontCameraInput];
        }
        self.cameraPosition = AVCaptureDevicePositionFront;
    }else {
        [self.captureSession stopRunning];
        [self.captureSession removeInput:self.frontCameraInput];
        if ([self.captureSession canAddInput:self.backCameraInput]) {
            [self.captureSession addInput:self.backCameraInput];
        }
        self.cameraPosition = AVCaptureDevicePositionBack;
    }
    
    AVCaptureDeviceInput *deviceInput = isFront ? self.frontCameraInput:self.backCameraInput;
    self.captureSession.sessionPreset = _setResolution;
    [self.captureSession beginConfiguration]; // the session to which the receiver's AVCaptureDeviceInput is added.
    if ( [deviceInput.device lockForConfiguration:NULL] ) {
        [deviceInput.device setActiveVideoMinFrameDuration:CMTimeMake(1, 15)];
        [deviceInput.device setActiveVideoMaxFrameDuration:CMTimeMake(1, 15)];
        [deviceInput.device unlockForConfiguration];
    }
    [self.captureSession commitConfiguration];
    
    self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    if (self.videoConnection.supportsVideoMirroring) {
        self.videoConnection.videoMirrored = isFront;
    }
    //[self.captureSession startRunning];
}

//用来返回是前置摄像头还是后置摄像头
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    //返回和视频录制相关的所有默认设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //遍历这些设备返回跟position相关的设备
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)camera
{
    if (!_camera) {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if ([device position] == self.cameraPosition)
            {
                _camera = device;
            }
        }
    }
    return _camera;
}

- (AVCaptureVideoDataOutput *)videoOutput
{
    if (!_videoOutput) {
        //输出
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setAlwaysDiscardsLateVideoFrames:YES];
        [_videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:_captureFormat] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
    }
    return _videoOutput;
}

//录制的队列
- (dispatch_queue_t)captureQueue {
    if (_captureQueue == nil) {
        _captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    }
    return _captureQueue;
}

//视频连接
- (AVCaptureConnection *)videoConnection {
    _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    _videoConnection.automaticallyAdjustsVideoMirroring =  NO;
    
    return _videoConnection;
}

- (BOOL)isFrontCamera
{
    return self.cameraPosition == AVCaptureDevicePositionFront;
}

-(void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    currentMetadata = metadataObjects;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    if([self.delegate respondsToSelector:@selector(didOutputVideoSampleBuffer: rect:)])
    {
        if(currentMetadata)
        {
             NSMutableArray<NSValue *> * rects= [[NSMutableArray alloc]init];
            
            for(int i = 0;i<currentMetadata.count;i++)
            {
               AVMetadataObject *metadataObject = [captureOutput transformedMetadataObjectForMetadataObject:[currentMetadata objectAtIndex:i] connection:connection];
                if (metadataObject.type == AVMetadataObjectTypeFace)
                {
                    //NSValue* data = [[NSValue alloc]init];//metadataObject.bounds;
                    //data.CGRectValue = metadataObject.bounds;
                   // [data c:metadataObject.bounds];
                    [rects addObject:[NSValue valueWithCGRect:metadataObject.bounds]];
                }
            }
            [self.delegate didOutputVideoSampleBuffer:sampleBuffer rect:rects];
        }
        else
        {
            [self.delegate didOutputVideoSampleBuffer:sampleBuffer rect:nil];
        }
    }
    
}


@end


