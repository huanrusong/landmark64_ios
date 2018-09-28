//
//  ViewController.m
//  landmark64
//
//  Created by 宦如松 on 2018/9/27.
//  Copyright © 2018年 宦如松. All rights reserved.
//

#import "ViewController.h"
#import "Camera.h"
#import "DlibApi.h"
@interface ViewController ()<RSCameraDelegate>
{
    DlibApi* wrapper;
    AVSampleBufferDisplayLayer * viewlayer;
    UIView* baseView;
}
@property (nonatomic, strong) RSCamera *bgraCamera;//BGRA摄像头

@end

@implementation ViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    [self initDlib];
    [self initCamero];
    [self previewLayer];
    baseView = [[UIView alloc]init];
    baseView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);;
    baseView.backgroundColor = [UIColor redColor];
    viewlayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [baseView.layer addSublayer:viewlayer];
    [self.view addSubview:baseView];
    [_bgraCamera startUp];
    // Do any additional setup after loading the view, typically from a nib.
}

-(AVSampleBufferDisplayLayer *)previewLayer{
    if (viewlayer == nil) {
        viewlayer = [[AVSampleBufferDisplayLayer alloc] init];
    }
    return viewlayer;
}

-(void)initDlib
{
    wrapper = [[DlibApi alloc]init];
    [wrapper prepare];
}

-(void)initCamero
{
    if (!_bgraCamera) {
        _bgraCamera = [[RSCamera alloc] init];
        [_bgraCamera setCameroResolution:0];
        _bgraCamera.delegate = self;
    }
}


- (int)switchCamera
{
    static bool isfront = YES;
    [_bgraCamera changeCameraInputDeviceisFront:![_bgraCamera isFrontCamera]];
    [_bgraCamera startCapture];
    NSLog(@"---@ startCapture!\n");
    isfront = !isfront;
    return 0;
}

- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer rect:(NSArray<NSValue *> *)rects
{
    NSDate* date1 = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
    NSTimeInterval time1=[date1 timeIntervalSince1970]*1000;
    if(rects)
    {
        [wrapper doWorkOnSampleBuffer:sampleBuffer inRects:rects];
    }
    NSDate* date2 = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
    NSTimeInterval time2=[date2 timeIntervalSince1970]*1000;
    NSLog(@"time2-time1=%fms",time2-time1);
    [viewlayer enqueueSampleBuffer:sampleBuffer];
}
@end
