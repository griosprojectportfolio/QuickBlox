//
//  Storage.m
//  sample-users
//
//  Created by Quickblox Team on 6/11/15.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "Storage.h"

@implementation Storage

+ (instancetype)instance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[self class] new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.users = [NSMutableArray array];
    }
    return self;
}


+ (QBUUser *)userFromId:(NSInteger)userId {
    NSArray *arryUser = [Storage instance].users;
    NSUInteger index = [arryUser indexOfObjectPassingTest: ^BOOL(QBUUser *user, NSUInteger idx, BOOL *stop) {
        return user.ID == userId;
    }];
    QBUUser *user = [arryUser objectAtIndex:index];
    return user;
}
@end
