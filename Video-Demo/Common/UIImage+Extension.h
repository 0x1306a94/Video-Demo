//
//  UIImage+Extension.h
//  Video-Demo
//
//  Created by king on 2018/11/9.
//  Copyright © 2018 king. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extension)
/**
 *从图片中按指定的位置大小截取图片的一部分
 * UIImage image 原始的图片
 * CGRect rect 要截取的区域
 */
+ (UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect;
/**
 *根据给定的size的宽高比自动缩放原图片、自动判断截取位置,进行图片截取
 * UIImage image 原始的图片
 * CGSize size 截取图片的size
 */
+ (UIImage *)clipImage:(UIImage *)image toRect:(CGSize)size;
@end
