//
//  NSString+DemoObjC.m
//  DemoObjC
//
//  Created by GrepRuby1 on 06/10/15.
//  Copyright (c) 2015 GrepRuby. All rights reserved.
//

#import "NSString+QB.h"

@implementation NSString (QB)

// MARK: To check Email is valid or not
+ (BOOL)isValidEmailAddress:(NSString*)email
{
  NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
  NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
  BOOL result = [emailTest evaluateWithObject:email];
  return result;
}

// MARK: To check Phone umber is valid or not
+ (BOOL)isValidPhoneNumber:(NSString*)phoneNumber
{
  NSString *phoneRegex = @"^\\d{3}-\\d{3}-\\d{4}$";
  NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex];
  BOOL result = [phoneTest evaluateWithObject:phoneNumber];
  return result;
}


@end
