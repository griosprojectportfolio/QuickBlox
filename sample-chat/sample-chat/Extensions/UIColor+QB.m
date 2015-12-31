//
//  UIColor+DemoObjC.m
//  DemoObjC
//
//  Created by GrepRuby1 on 06/10/15.
//  Copyright (c) 2015 GrepRuby. All rights reserved.
//

#import "UIColor+QB.h"

@implementation UIColor (QB)

// MARK: - UIColor from hex color code
+ (UIColor *)hexColorCode:(NSString *)hex {
  
  NSString *colorString = [[hex uppercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ;
  if ([colorString length] < 6)
    return [UIColor grayColor];
  
  if ([colorString hasPrefix:@"0X"])
    colorString = [colorString substringFromIndex:2];
  else if ([colorString hasPrefix:@"#"])
    colorString = [colorString substringFromIndex:1];
  else if ([colorString length] != 6)
    return  [UIColor grayColor];
  
  NSRange range;
  range.location = 0;
  range.length = 2;
  NSString *rString = [colorString substringWithRange:range];
  range.location += 2;
  NSString *gString = [colorString substringWithRange:range];
  range.location += 2;
  NSString *bString = [colorString substringWithRange:range];
  
  unsigned int red, green, blue;
  [[NSScanner scannerWithString:rString] scanHexInt:&red];
  [[NSScanner scannerWithString:gString] scanHexInt:&green];
  [[NSScanner scannerWithString:bString] scanHexInt:&blue];
  
  return [UIColor colorWithRed:((float) red / 255.0f)
                         green:((float) green / 255.0f)
                          blue:((float) blue / 255.0f)
                         alpha:1.0f];
}

// MARK: - UIColor from hex color code and alpha
+ (UIColor *)hexColorCode:(NSString *)hex withAlpha:(float)alpha{
  
  NSString *colorString = [[hex uppercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ;
  if ([colorString length] < 6)
    return [UIColor grayColor];
  
  if ([colorString hasPrefix:@"0X"])
    colorString = [colorString substringFromIndex:2];
  else if ([colorString hasPrefix:@"#"])
    colorString = [colorString substringFromIndex:1];
  else if ([colorString length] != 6)
    return  [UIColor grayColor];
  
  NSRange range;
  range.location = 0;
  range.length = 2;
  NSString *rString = [colorString substringWithRange:range];
  range.location += 2;
  NSString *gString = [colorString substringWithRange:range];
  range.location += 2;
  NSString *bString = [colorString substringWithRange:range];
  
  unsigned int red, green, blue;
  [[NSScanner scannerWithString:rString] scanHexInt:&red];
  [[NSScanner scannerWithString:gString] scanHexInt:&green];
  [[NSScanner scannerWithString:bString] scanHexInt:&blue];
  
  return [UIColor colorWithRed:((float) red / 255.0f)
                         green:((float) green / 255.0f)
                          blue:((float) blue / 255.0f)
                         alpha:alpha];
  
}

//+(UIColor *) colorWithBrightnessFactor:(CGFloat)factor{
//  CGFloat hue = 0;
//  CGFloat saturation = 0;
//  CGFloat brightness = 0;
//  CGFloat alpha = 0;
//
//}

// MARK: - UIColor from RGB value
+ (UIColor *)colorWithRGB:(int)rgbValue alpha:(CGFloat)alpha {
  return [UIColor
          colorWithRed : ((float)((rgbValue & 0xFF0000) >> 16)) / 255.0
          green : ((float)((rgbValue & 0xFF00) >> 8)) / 255.0
          blue : ((float)(rgbValue & 0xFF)) / 255.0
          alpha : alpha ];
}

// MARK: - Custom Methods for app
+ (UIColor *)appBackgroundColor{
  return [self hexColorCode:@"#ded0a4"];
}

+ (UIColor *)appSignInButtonBgColor{
  return [self hexColorCode:@"#628c00"];
}

+ (UIColor *)appSignUpButtonBgColor{
  return [self hexColorCode:@"#f5894e"];
}

+ (UIColor *)appNavigationBarTinColor {
    return [self hexColorCode:@"#FB383A"];
}

@end
