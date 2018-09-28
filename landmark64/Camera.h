//
//  Camera.h
//  landmark64
//
//  Created by 宦如松 on 2018/9/28.
//  Copyright © 2018年 宦如松. All rights reserved.
//

#ifndef Camera_h
#define Camera_h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol RSCameraDelegate <NSObject>

- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer rect:(NSArray<NSValue *> *)rects;

@end

@interface RSCamera : NSObject
@property (nonatomic, assign) id<RSCameraDelegate> delegate;
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



#endif /* Camera_h */
