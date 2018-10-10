//
//  DlibApi.m
//  landmark64
//
//  Created by 宦如松 on 2018/9/27.
//  Copyright © 2018年 宦如松. All rights reserved.
//

#import "DlibApi.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#include "dlib/image_processing.h"
#include "dlib/image_io.h"
#include "dlib/opencv/cv_image_abstract.h"
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core.hpp>
#include <vector>
#include <opencv2/photo.hpp>
using namespace cv;
using namespace dlib;
using namespace std;

struct correspondens{
    std::vector<int> index;
};


@interface DlibApi ()
{
     unsigned char *newBitmap;
     CGRect detectRect;
    UIImage* rrimage ;
    std::vector<Point2f> points1, points2;
    cv::Mat* imgCV1;
    cv::Mat* imgCV2;
    unsigned char* bbmap;
}
@property (assign) BOOL prepared;
@end
@implementation DlibApi {
    dlib::shape_predictor sp;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        newBitmap = NULL;
        _prepared = NO;
        imgCV1 = NULL;
        imgCV2 = NULL;
        bbmap=NULL;
    }
    return self;
}

- (void)prepare {
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];

    dlib::deserialize(modelFileNameCString) >> sp;
    // FIXME: test this stuff for memory leaks (cpp object destruction)
    self.prepared = YES;
    [self loadModelPicture];
}

- (void) loadModelPicture
{
    NSString* imageName = [[NSBundle mainBundle] pathForResource:@"2223" ofType:@"jpg"];
    UIImage* image = [UIImage imageNamed:imageName];
    CIImage* imageCI = [CIImage imageWithCGImage:image.CGImage];
    CIContext* context = [CIContext contextWithOptions:nil];
    NSDictionary* param = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy ];
    CIDetector* faceDector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:param];
    NSArray* detectResult = [faceDector featuresInImage:imageCI];
    CGRect detectRect;
    CGSize ciImageSize =  imageCI.extent.size;
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    transform = CGAffineTransformTranslate(transform, 0,-1*ciImageSize.height );
    if(detectResult.count>0)
    {
        CIFeature * feature = detectResult.firstObject;
        detectRect = feature.bounds;
        detectRect = CGRectApplyAffineTransform(detectRect, transform);
    }

    [self convertUIImageToBitmapRGBA8:image];
    
    dlib::array2d<dlib::bgr_pixel> img;
    size_t width =image.size.width ;
    size_t height=image.size.height;
     img.set_size(height,width );
    img.reset();
    long position = 0;
    if(bbmap==NULL)bbmap = (unsigned char*)malloc(width*height*3);
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();
        
        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        char r = newBitmap[bufferLocation];
        char g = newBitmap[bufferLocation + 1];
        char b = newBitmap[bufferLocation + 2];
        newBitmap[bufferLocation + 2] = r;
        newBitmap[bufferLocation] = b;
        bbmap[position*3] = b;
        bbmap[position*3+1] = g;
        bbmap[position*3+2] = r;
        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;
        position++;
    }
    NSMutableArray<NSValue *> * rects= [[NSMutableArray alloc]init];
    [rects addObject:[NSValue valueWithCGRect:detectRect]];
    std::vector<dlib::rectangle> convertedRectangles = [self convertCGRectValueArray:rects];
    
    // for every detected face
    for (unsigned long j = 0; j < convertedRectangles.size(); ++j)
    {
        dlib::rectangle oneFaceRect = convertedRectangles[j];
        
        // detect all landmarks
        dlib::full_object_detection shape = sp(img, oneFaceRect);
        
        // and draw them into the image (samplebuffer)
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
            float x=shape.part(k).x();
            float y=shape.part(k).y();
            points1.push_back(Point2f(x,y));
//            draw_solid_circle(img, p, 1, dlib::rgb_pixel(0, 255, 255));
        }
//        dlib::rectangle ttt(oneFaceRect.left(),oneFaceRect.top(),oneFaceRect.right(),oneFaceRect.bottom());
//        fill_rect(img,ttt,dlib::rgb_alpha_pixel(255, 0, 0,50));
    }
    if(imgCV1==NULL)imgCV1 = new Mat((int)height, (int)width, CV_8UC3, bbmap);
//
//    img.reset();
//    position = 0;
//    while (img.move_next()) {
//        dlib::bgr_pixel& pixel = img.element();
//        long bufferLocation = position * 4; //(row * width + column) * 4;
//        newBitmap[bufferLocation] = pixel.red;
//        newBitmap[bufferLocation + 1] = pixel.green;
//        newBitmap[bufferLocation + 2] = pixel.blue;
//        position++;
//    }
//   rrimage =  [self convertBitmapRGBA8ToUIImage:newBitmap withWidth:width withHeight:height];
}

-(UIImage*)getImage
{
    return rrimage;
}

- (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *) buffer
                                withWidth:(int) width
                               withHeight:(int) height {
    
    
    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if(colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,    // data provider
                                    NULL,        // decode
                                    YES,            // should interpolate
                                    renderingIntent);
    
    uint32_t* pixels = (uint32_t*)malloc(bufferLength);
    
    if(pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }
    
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 kCGImageAlphaPremultipliedLast);
    
    if(context == NULL) {
        NSLog(@"Error context not created");
        free(pixels);
    }
    
    UIImage *image = nil;
    if(context) {
        
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        
        // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
//        if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
//            float scale = [[UIScreen mainScreen] scale];
//            image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
//        } else {
            image = [UIImage imageWithCGImage:imageRef];
    //    }
        
        CGImageRelease(imageRef);
        CGContextRelease(context);
    }
    
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);
    
    if(pixels) {
        free(pixels);
    }
    return image;
}


- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects {
    
    if (!self.prepared) {
        [self prepare];
    }
    
    dlib::array2d<dlib::bgr_pixel> img;
    
    // MARK: magic
    CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    unsigned char *baseBuffer = (unsigned char *)CVPixelBufferGetBaseAddress(imageBuffer);
    unsigned char *baseBuffer11 = (unsigned char *)malloc(width*height*3);
    // set_size expects rows, cols format
    img.set_size(height, width);
    
    // copy samplebuffer image data into dlib image format
    img.reset();
    long position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();
        
        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        char b = baseBuffer[bufferLocation];
        char g = baseBuffer[bufferLocation + 1];
        char r = baseBuffer[bufferLocation + 2];
        baseBuffer11[position*3] = b;
        baseBuffer11[position*3+1] = g;
        baseBuffer11[position*3+2] = r;
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];
        
        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;
        
        position++;
    }
    
    // unlock buffer again until we need it again
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    // convert the face bounds list to dlib format
    std::vector<dlib::rectangle> convertedRectangles = [self convertCGRectValueArray:rects];
    
    // for every detected face
    //for (unsigned long j = 0; j < convertedRectangles.size(); ++j)
    if(convertedRectangles.size() > 0)
    {
        dlib::rectangle oneFaceRect = convertedRectangles[0];
        
        // detect all landmarks
        dlib::full_object_detection shape = sp(img, oneFaceRect);
        
        // and draw them into the image (samplebuffer)
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
            float x=shape.part(k).x();
            float y=shape.part(k).y();
            points2.push_back(Point2f(x,y));
           // draw_solid_circle(img, p, 3, dlib::rgb_pixel(0, 255, 255));
        }
//        dlib::rectangle ttt(oneFaceRect.left(),oneFaceRect.top(),oneFaceRect.right(),oneFaceRect.bottom());
//        fill_rect(img,ttt,dlib::rgb_alpha_pixel(255, 0, 0,50));
    }
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    if(imgCV2==NULL)
    {
        imgCV2 = new Mat((int)height,(int)width, CV_8UC3, baseBuffer11);
    }
    Mat output;
    [self processFace:output];

    // lets put everything back where it belongs
//    CVPixelBufferLockBaseAddress(imageBuffer, 0);
//
    // copy dlib image data back into samplebuffer
   // img.reset();
//    position = 0;
    unsigned char* data  = output.data;
    int length = 0;
    if(data!=0)
    {
      //  for(length =0;length<width*height*4;)
        for(int r = 0;r<height;r++)
        {
            //cv::Mat line = output.row(r);
            cv::Vec3b* p = output.ptr<cv::Vec3b>(r);
            for(int c = 0;c<width;c++)
            {
                length = 4*r*width+4*c;
                baseBuffer[length] = p[c][0];
                baseBuffer[length + 1] = p[c][1];;
                baseBuffer[length + 2] = p[c][2];;
            }
        }
//        memcpy(baseBuffer,data,4*height*width);
    }

//    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
   
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    if(imgCV2)
    {
        delete imgCV2;
        imgCV2 = NULL;
    }
    if(baseBuffer11)
    {
        free(baseBuffer11);
        baseBuffer11=NULL;
    }
    points2.clear();
}

-(void)processFace:( Mat&) output
{
    //---------------------step 3. find convex hull -------------------------------------------
    if(points2.size()<=0)return;
    cv::Mat imgCV1Warped = imgCV2->clone();
    imgCV1->convertTo(*imgCV1, CV_32F);
    imgCV1Warped.convertTo(imgCV1Warped, CV_32F);
    
    std::vector<Point2f> hull1;
    std::vector<Point2f> hull2;
    std::vector<int> hullIndex;
    
    cv::convexHull(points2, hullIndex, false, false);
    
    for(int i = 0; i < hullIndex.size(); i++)
    {
        hull1.push_back(points1[hullIndex[i]]);
        hull2.push_back(points2[hullIndex[i]]);
    }
    
    //-----------------------step 4. delaunay triangulation -------------------------------------
    std::vector<correspondens> delaunayTri;
    cv::Rect rect(0, 0, imgCV1Warped.cols, imgCV1Warped.rows);
    [self delaunayTriangulation:hull2 param1:delaunayTri param2:rect];
    
    for(size_t i=0;i<delaunayTri.size();++i)
    {
        std::vector<Point2f> t1,t2;
        correspondens corpd=delaunayTri[i];
        for(size_t j=0;j<3;++j)
        {
            t1.push_back(hull1[corpd.index[j]]);
            t2.push_back(hull2[corpd.index[j]]);
        }
        [self warpTriangle:(*imgCV1) param1:imgCV1Warped param2:t1 param3:t2];
    }
   
    
    //------------------------step 5. clone seamlessly -----------------------------------------------
    
    //calculate mask
    std::vector<cv::Point> hull8U;
    
    for(int i=0; i< hull2.size();++i)
    {
        cv::Point pt(hull2[i].x,hull2[i].y);
        hull8U.push_back(pt);
    }
    
    
    cv::Mat mask = cv::Mat::zeros(imgCV2->rows,imgCV2->cols,imgCV2->type());
    cv::fillConvexPoly(mask, &hull8U[0], (int)hull8U.size(), Scalar(255,255,255));
    
    
    //NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);

    
    cv::Rect r = boundingRect(hull2);
    cv::Point center = (r.tl() +r.br()) / 2;
    
    imgCV1Warped.convertTo(imgCV1Warped, CV_8UC3);
    imgCV2->convertTo(*imgCV2, CV_8UC3);
    mask.convertTo(mask, CV_8UC3);
   // output = imgCV1Warped.clone();
    cv::seamlessClone(imgCV1Warped,*imgCV2,mask,center,output,cv::NORMAL_CLONE);
    
//    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
//    NSString *filePath = [[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"imgCV1Warped.jpg"]];
//
//    imwrite([filePath UTF8String],imgCV1Warped);
////
//    NSString *filePath3 = [[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"imgCV2.jpg"]];
//
//    imwrite([filePath3 UTF8String],*imgCV2);
////
////
//    NSString *filePath1 = [[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"mask.jpg"]];
//
//    imwrite([filePath1 UTF8String],mask);
//    NSString *filePath2= [[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"output.jpg"]];
//
//    imwrite([filePath2 UTF8String],output);
    
    
    
}

- (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects {
    std::vector<dlib::rectangle> myConvertedRects;
    for (NSValue *rectValue in rects) {
        CGRect rect = [rectValue CGRectValue];
        long left = rect.origin.x;
        long top = rect.origin.y;
        long right = left + rect.size.width;
        long bottom = top + rect.size.height;
        dlib::rectangle dlibRect(left, top, right, bottom);

        myConvertedRects.push_back(dlibRect);
    }
    return myConvertedRects;
}

- (unsigned char *) convertUIImageToBitmapRGBA8:(UIImage *) image {
    
    CGImageRef imageRef = image.CGImage;
    
    // Create a bitmap context to draw the uiimage into
    CGContextRef context = [self newBitmapRGBA8ContextFromImage:imageRef];
    
    if(!context) {
        return NULL;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    
    // Draw image into the context to get the raw image data
    CGContextDrawImage(context, rect, imageRef);
    
    // Get a pointer to the data
    unsigned char *bitmapData = (unsigned char *)CGBitmapContextGetData(context);
    
    // Copy the data and release the memory (return memory allocated with new)
    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    size_t bufferLength = bytesPerRow * height;
    
    if(bitmapData) {
        newBitmap = (unsigned char *)malloc(sizeof(unsigned char) * bytesPerRow * height);
        if(newBitmap)memcpy(newBitmap,bitmapData,bufferLength);
        free(bitmapData);
    } else {
        NSLog(@"Error getting bitmap pixel data\n");
    }
    
    CGContextRelease(context);
    
    return newBitmap;
}

- (CGContextRef) newBitmapRGBA8ContextFromImage:(CGImageRef) image {
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    uint32_t *bitmapData;
    
    size_t bitsPerPixel = 32;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    size_t bytesPerRow = width * bytesPerPixel;
    size_t bufferLength = bytesPerRow * height;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if(!colorSpace) {
        NSLog(@"Error allocating color space RGB\n");
        return NULL;
    }
    
    // Allocate memory for image data
    bitmapData = (uint32_t *)malloc(bufferLength);
    
    if(!bitmapData) {
        NSLog(@"Error allocating memory for bitmap\n");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    //Create bitmap context
    
    context = CGBitmapContextCreate(bitmapData,
                                    width,
                                    height,
                                    bitsPerComponent,
                                    bytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast);    // RGBA
    if(!context) {
        free(bitmapData);
        NSLog(@"Bitmap context not created");
    }
    
    CGColorSpaceRelease(colorSpace);
    
    return context;
}





-(void) delaunayTriangulation:(const std::vector<Point2f>&) hull param1:(std::vector<correspondens>&) delaunayTri param2:(cv::Rect) rect
{
    
    cv::Subdiv2D subdiv(rect);
    for (int it = 0; it < hull.size(); it++)
        subdiv.insert(hull[it]);
    //cout<<"done subdiv add......"<<endl;
    std::vector<Vec6f> triangleList;
    subdiv.getTriangleList(triangleList);
    //cout<<"traingleList number is "<<triangleList.size()<<endl;
    
    
    
    //std::vector<Point2f> pt;
    //correspondens ind;
    for (size_t i = 0; i < triangleList.size(); ++i)
    {
        
        std::vector<Point2f> pt;
        correspondens ind;
        Vec6f t = triangleList[i];
        pt.push_back( Point2f(t[0], t[1]) );
        pt.push_back( Point2f(t[2], t[3]) );
        pt.push_back( Point2f(t[4], t[5]) );
        //cout<<"pt.size() is "<<pt.size()<<endl;
        
        if (rect.contains(pt[0]) && rect.contains(pt[1]) && rect.contains(pt[2]))
        {
            //cout<<t[0]<<" "<<t[1]<<" "<<t[2]<<" "<<t[3]<<" "<<t[4]<<" "<<t[5]<<endl;
            int count = 0;
            for (int j = 0; j < 3; ++j)
                for (size_t k = 0; k < hull.size(); k++)
                    if (abs(pt[j].x - hull[k].x) < 1.0   &&  abs(pt[j].y - hull[k].y) < 1.0)
                    {
                        ind.index.push_back(k);
                        count++;
                    }
            if (count == 3)
                //cout<<"index is "<<ind.index[0]<<" "<<ind.index[1]<<" "<<ind.index[2]<<endl;
                delaunayTri.push_back(ind);
        }
        //pt.resize(0);
        //cout<<"delaunayTri.size is "<<delaunayTri.size()<<endl;
    }
    
    
}




// Apply affine transform calculated using srcTri and dstTri to src
-(void) applyAffineTransform:(Mat&) warpImage param1:(Mat &)src param2:( std::vector<Point2f> &)srcTri param3: (std::vector<Point2f> &)dstTri
{
    // Given a pair of triangles, find the affine transform.
    Mat warpMat = getAffineTransform( srcTri, dstTri );
    
    // Apply the Affine Transform just found to the src image
    warpAffine( src, warpImage, warpMat, warpImage.size(), cv::INTER_LINEAR, BORDER_REFLECT_101);
}




/*
 //morp a triangle in the one image to another image.
 */


-(void) warpTriangle:(Mat &)img1 param1:(Mat &)img2 param2:(std::vector<Point2f> &)t1 param3:(std::vector<Point2f> &)t2
{
    
    cv::Rect r1 = cv::boundingRect(t1);
    cv::Rect r2 = cv::boundingRect(t2);
    
    // Offset points by left top corner of the respective rectangles
    std::vector<cv::Point2f> t1Rect, t2Rect;
    std::vector<cv::Point> t2RectInt;
    for(int i = 0; i < 3; i++)
    {
        t1Rect.push_back( cv::Point2f( t1[i].x - r1.x, t1[i].y -  r1.y) );
        t2Rect.push_back( cv::Point2f( t2[i].x - r2.x, t2[i].y - r2.y) );
        t2RectInt.push_back( cv::Point(t2[i].x - r2.x, t2[i].y - r2.y) ); // for fillConvexPoly
    }
    // Apply warpImage to small rectangular patches
    Mat img1Rect;
    img1(r1).copyTo(img1Rect);
    
    // Get mask by filling triangle
    Mat mask = Mat::zeros(r2.height, r2.width,  img1Rect.type());
    cv::fillConvexPoly(mask, t2RectInt, Scalar(1.0, 1.0, 1.0,0.0), 16, 0);
    
    Mat img2Rect = Mat::zeros(r2.height, r2.width, img1Rect.type());
    
    [self applyAffineTransform:img2Rect param1:img1Rect param2:t1Rect param3:t2Rect];
    
    cv::multiply(img2Rect,mask, img2Rect);
    cv::multiply(img2(r2), Scalar(1.0,1.0,1.0) - mask, img2(r2));
    img2(r2) = img2(r2) + img2Rect;
    
}

@end
