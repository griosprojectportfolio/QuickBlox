//
//  UIColor+DemoObjC.h
//  DemoObjC
//
//  Created by GrepRuby1 on 06/10/15.
//  Copyright (c) 2015 GrepRuby. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (QB)

+ (UIColor *)hexColorCode:(NSString *)hex;
+ (UIColor *)hexColorCode:(NSString *)hex withAlpha:(float)alpha;
+ (UIColor *)colorWithRGB:(int)rgbValue alpha:(CGFloat)alpha;

+ (UIColor *)appBackgroundColor;
+ (UIColor *)appSignInButtonBgColor;
+ (UIColor *)appSignUpButtonBgColor;
+ (UIColor *)appNavigationBarTinColor;

@end
