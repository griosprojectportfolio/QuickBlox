//
//  NSDate+DemoObjC.m
//  DemoObjC
//
//  Created by GrepRuby1 on 06/10/15.
//  Copyright (c) 2015 GrepRuby. All rights reserved.
//

#import "NSDate+QB.h"

@implementation NSDate (QB)

+ (int)getComponent:(NSCalendarUnit)component {
  
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSInteger components = [calendar component:component fromDate:[NSDate date]];
  return (int)components;
}

+ (int)currentYear{
  return [self getComponent:NSCalendarUnitYear];
}

+ (int)currentMonth{
  return [self getComponent:NSCalendarUnitMonth];
}

+ (int)currentWeekday{
  return [self getComponent:NSCalendarUnitWeekday];
}

+ (int)currentWeekMonth{
  return [self getComponent:NSCalendarUnitWeekOfMonth];
}

@end
