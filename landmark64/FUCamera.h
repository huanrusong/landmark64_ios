//
//  FUCamera.h
//  rtcengine
//
//  Created by zhangxu on 2017/8/4.
//  Copyright © 2017年 宦如松. All rights reserved.
//

#ifndef FUCamera_h
#define FUCamera_h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol FUCameraDelegate <NSObject>

- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer rect:(NSArray<NSValue *> *)rects;

@end

@interface FUCamera : NSObject
@property (nonatomic, assign) id<FUCameraDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL isFrontCamera;
@property (copy  , nonatomic) dispatch_queue_t  captureQueue;//录制的队列

- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition captureFormat:(int)captureFormat;

- (void)startUp;

- (void)startCapture;

- (void)stopCapture;

- (void)changeCameraInputDeviceisFront:(BOOL)isFront;

- (void)takePhotoAndSave;
- (void)setCameroResolution:(int)resolutionLevel;

@end



#endif /* FUCamera_h */
