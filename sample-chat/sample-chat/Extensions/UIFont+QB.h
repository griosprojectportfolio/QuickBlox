//
//  UIFont+DemoObjC.h
//  DemoObjC
//
//  Created by GrepRuby1 on 06/10/15.
//  Copyright (c) 2015 GrepRuby. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFont (QB)

+ (UIFont *)normalFontOfSize:(CGFloat)size;
+ (UIFont *)italicFontOfSize:(CGFloat)size;
+ (UIFont *)boldFontOfSize:(CGFloat)size;
+ (UIFont *)mediumFontOfSize:(CGFloat)size;
+ (UIFont *)lightFontOfSize:(CGFloat)size;
+ (UIFont *)thinFontOfSize:(CGFloat)size;
+ (UIFont *)ultraLightFontOfSize:(CGFloat)size;

@end
