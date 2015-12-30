//
//  HomeViewController.m
//  Slang
//
//  Created by GrepRuby on 22/12/15.
//  Copyright © 2015 GrepRuby. All rights reserved.
//

#import "RequestViewController.h"
#import <Quickblox/Quickblox.h>
#import "Storage.h"
#import "NMPaginator.h"
#import "UsersPaginator.h"
#import "ServicesManager.h"
#import "Constants.h"
#import "UsersDataSource.h"
#import "DialogsViewController.h"
#import "ChatViewController.h"

@interface RequestViewController () <QBChatDelegate, NMPaginatorDelegate>
@property (nonatomic, strong) UsersPaginator *paginator;
@property (strong, nonatomic) UsersDataSource *dataSource;
@property (strong, nonatomic) QBChat *qbChat;
@end

@implementation RequestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    QBUUser *currentUser = [QBUUser user];
    currentUser.ID = 7775139;
    currentUser.password = @"qwertyuiop";

        // connect to Chat
/*    _qbChat = [QBChat instance];
    [_qbChat addDelegate:self];
    [_qbChat connectWithUser:currentUser completion:^(NSError * _Nullable error) {
        if(error == nil) {
                //[self registerForRemoteNotifications];
            [self performSelector:@selector(friendList) withObject:nil afterDelay:2.0];
        }
    }];

        ServicesManager.instance.currentUser.password = @"qwertyuiop";
        ServicesManager.instance.currentUser.email = @"qwery1@yopmail.com";
        [ServicesManager.instance logInWithUser:ServicesManager.instance.currentUser completion:^(BOOL success, NSString *errorMessage) {
            if (success) {
                if (ServicesManager.instance.notificationService.pushDialogID == nil) {
                }
                else {
                    [ServicesManager.instance.notificationService handlePushNotificationWithDelegate:self];
                }
    
            } else {
            }
        }];*/

}



#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    QBUUser *selectedUser = self.dataSource.users[indexPath.row];
    selectedUser.password = @"qwertyuiop";

    __weak __typeof(self)weakSelf = self;
        // Logging in to Quickblox REST API and chat.
    [ServicesManager.instance logInWithUser:selectedUser completion:^(BOOL success, NSString *errorMessage) {
        if (success) {
            __typeof(self) strongSelf = weakSelf;
            [strongSelf performSegueWithIdentifier:kGoToDialogsSegueIdentifier sender:nil];
        } else {
        }
    }];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)backToLoginViewController:(UIStoryboardSegue *)segue
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - Send and accept friend request

- (void)receiveFriendRequest { // request from qwery1
    [_qbChat confirmAddContactRequest:7775139  completion:^(NSError * _Nullable error) {
        if(error == nil) {
            NSLog(@"Accept");
        }
        NSLog(@"%@", error);
    }];
}

#pragma mark QBChatDelegate

- (void)chatDidReceiveContactAddRequestFromUser:(NSUInteger)userID{

}

#pragma mark QBChatDelegate

- (void)chatDidReceiveAcceptContactRequestFromUser:(NSUInteger)userID{
    NSLog(@"%ld",userID);
}

@end
