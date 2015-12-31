//
//  UIFont+DemoObjC.m
//  DemoObjC
//
//  Created by GrepRuby1 on 06/10/15.
//  Copyright (c) 2015 GrepRuby. All rights reserved.
//

#import "UIFont+QB.h"

@implementation UIFont (QB)

+ (UIFont *)normalFontOfSize:(CGFloat)size {
  return [UIFont fontWithName:@"HelveticaNeue" size:size];
}

+ (UIFont *)italicFontOfSize:(CGFloat)size {
  return [UIFont fontWithName:@"HelveticaNeue-Italic" size:size];
}

+ (UIFont *)boldFontOfSize:(CGFloat)size {
  return [UIFont fontWithName:@"HelveticaNeue-Bold" size:size];
}

+ (UIFont *)mediumFontOfSize:(CGFloat)size {
  return [UIFont fontWithName:@"HelveticaNeue-Medium" size:size];
}

+ (UIFont *)lightFontOfSize:(CGFloat)size {
  return [UIFont fontWithName:@"HelveticaNeue-Light" size:size];
}

+ (UIFont *)thinFontOfSize:(CGFloat)size {
  return [UIFont fontWithName:@"HelveticaNeue-Thin" size:size];
}

+ (UIFont *)ultraLightFontOfSize:(CGFloat)size {
  return [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:size];
}


@end
