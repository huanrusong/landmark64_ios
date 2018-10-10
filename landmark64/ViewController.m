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
    //[self loadModelPicture];
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
    
//    UIImage* image = [wrapper getImage];
//    UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
//    [imageView setFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
//    [self.view addSubview:imageView];
}

- (void) loadModelPicture
{
    NSString* imageName = [[NSBundle mainBundle] pathForResource:@"liudehua" ofType:@"jpg"];
    UIImage* image = [UIImage imageNamed:imageName];
    CIImage* imageCI = [CIImage imageWithCGImage:image.CGImage];
    CIContext* context = [CIContext contextWithOptions:nil];
    NSDictionary* param = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy ];
    CIDetector* faceDector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:param];
    NSArray* detectResult = [faceDector featuresInImage:imageCI];
    CGRect detectRect;
    UIImageView* vview = [[UIImageView alloc]init];
    [vview setFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [vview setImage:image];
    [self.view addSubview:vview];
    CGSize ciImageSize =  imageCI.extent.size;
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    transform = CGAffineTransformTranslate(transform, 0,-1*ciImageSize.height );
    
    if(detectResult.count>0)
    {
        CIFeature * feature = detectResult.firstObject;
        detectRect = feature.bounds;
        
        
   
        detectRect = CGRectApplyAffineTransform(detectRect, transform);
        
        
        UIView *faceView = [[UIView alloc] initWithFrame:detectRect];

        faceView.layer.borderColor = [UIColor redColor].CGColor;
        faceView.layer.borderWidth = 1;
        UIView* resultView = [[UIView alloc] initWithFrame:vview.frame];
        [resultView addSubview:faceView];
        [self.view addSubview:resultView];
        // [resultView setTransform:CGAffineTransformMakeScale(1, -1)];
    }

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
