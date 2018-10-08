//
//  DlibApi.h
//  landmark64
//
//  Created by 宦如松 on 2018/9/27.
//  Copyright © 2018年 宦如松. All rights reserved.
//

#ifndef DlibApi_h
#define DlibApi_h
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>
@interface DlibApi : NSObject

- (instancetype)init;
- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects;
- (void)prepare;
- (UIImage*)getImage;
@end

#endif /* DlibApi_h */
