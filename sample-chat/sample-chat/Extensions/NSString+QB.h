//
//  NSString+DemoObjC.h
//  DemoObjC
//
//  Created by GrepRuby1 on 06/10/15.
//  Copyright (c) 2015 GrepRuby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (QB)

+ (BOOL)isValidEmailAddress:(NSString*)email;
+ (BOOL)isValidPhoneNumber:(NSString*)phoneNumber;

@end
