//
//  NSDate+DemoObjC.h
//  DemoObjC
//
//  Created by GrepRuby1 on 06/10/15.
//  Copyright (c) 2015 GrepRuby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (QB)

+ (int)getComponent:(NSCalendarUnit)component;
+ (int)currentYear;
+ (int)currentMonth;
+ (int)currentWeekday;
+ (int)currentWeekMonth;

@end
