//
//  FindFriendViewController.m
//  sample-chat
//
//  Created by GrepRuby on 29/12/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import "FindFriendViewController.h"

@interface FindFriendViewController ()

@end

@implementation FindFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - Send and accept friend request

- (void)sendRequestApiCall {
    NSDictionary *aParam = @{

                             };
    [sharedDelegate.apiOperation  callPostUrl:aParam method:@"" success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *response = responseObject;
        [self sendRequestApiCall:response];
    } failure:^(NSURLSessionTask *task, NSError *error) {
        
    }];
}

- (void)sendRequestApiCall:(NSDictionary*)aParam {
    [sharedDelegate.apiOperation callPostUrl:aParam method:@"" success:^(NSURLSessionTask *task, id responseObject) {
        [self sendFriendRequestViaQBWithUserId:33];
    } failure:^(NSURLSessionTask *task, NSError *error) {
    }];
}

- (void)sendFriendRequestViaQBWithUserId:(NSInteger)userId {//7822648
    __weak __typeof(self)weakSelf = self;
    [[QBChat instance] addUserToContactListRequest:userId completion:^(NSError * _Nullable error) {
        if(error == nil) {
            NSLog(@"Success");
        }
        NSLog(@"%@", error);
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
