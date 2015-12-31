//
//  LoginTableViewController.m
//  sample-chat
//
//  Created by Anton Sokolchenko on 5/26/15.
//  Copyright (c) 2015 Igor Khomenko. All rights reserved.
//

#import "LoginViewController.h"
#import "ServicesManager.h"
#import "UsersDataSource.h"
#import "AppDelegate.h"
#import "DialogsViewController.h"
#import "ChatViewController.h"
#import "Storage.h"
#import "UsersPaginator.h"

@interface LoginViewController () <NotificationServiceDelegate, UITextFieldDelegate, NMPaginatorDelegate>

@property (nonatomic, weak) IBOutlet UITextField *loginTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, strong) UsersPaginator *paginator;

@property (strong, nonatomic) UsersDataSource *dataSource;
@property (nonatomic, assign, getter=isUsersAreDownloading) BOOL usersAreDownloading;

@end

@implementation LoginViewController

/*
 *  Default test users password
 */
static NSString *const kTestUsersDefaultPassword = @"qwertyuiop";//@"x6Bt0VDy5";

- (void)viewDidLoad
{
	[super viewDidLoad];
    self.loginTextField.text = @"qwery1";
    self.passwordTextField.text = @"qwertyuiop";
        // [self retrieveUsers];
}

- (void)paginator:(id)paginator didReceiveResults:(NSArray *)results {
    [[Storage instance].users addObjectsFromArray:results];
    NSLog(@"%@", [Storage instance].users);
}

- (BOOL)isLoginEmpty {
    BOOL emptyLogin = self.loginTextField.text.length == 0;
    self.loginTextField.backgroundColor = emptyLogin ? [UIColor redColor] : [UIColor whiteColor];
    return emptyLogin;
}

- (BOOL)isPasswordEmpty {
    BOOL emptyPassword = self.passwordTextField.text.length == 0;
    self.passwordTextField.backgroundColor = emptyPassword ? [UIColor redColor] : [UIColor whiteColor];
    return emptyPassword;
}

    // SignIn for chat qbrequest
- (IBAction)signInButtonClicked:(id)sender {
    [self.view endEditing:YES];
    BOOL notEmptyLogin = ![self isLoginEmpty];
    BOOL notEmptyPassword = ![self isPasswordEmpty];
    if (notEmptyLogin && notEmptyPassword) {

        [self qbLoginApiCall];

        /*NSDictionary *aParam = @{

                                 };
        [self loginApiCall:aParam];*/
    }
}

- (void)loginApiCall:(NSDictionary*)aParam {
    [sharedDelegate.apiOperation callPostUrl:aParam method:@"" success:^(NSURLSessionTask *task, id responseObject) {
        [self qbLoginApiCall];
    } failure:^(NSURLSessionTask *task, NSError *error) {
        
    }];
}

- (void)qbLoginApiCall {
        NSString *login = self.loginTextField.text;
        NSString *password = self.passwordTextField.text;
        [SVProgressHUD showWithStatus:@"Signing in"];
        [QBRequest logInWithUserLogin:login password:password successBlock:^(QBResponse *response, QBUUser *user) {
            [self signInForUserChat:user];
            self.paginator = [[UsersPaginator alloc] initWithPageSize:10 delegate:self];
            [self.paginator fetchFirstPage];
        } errorBlock:^(QBResponse *response) {
            [SVProgressHUD dismiss];

            NSLog(@"Errors=%@", [response.error description]);

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[response.error  description]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
    }];
}

    // SignIn for chat
- (void)signInForUserChat:(QBUUser*)user {
    QBUUser *selectedUser = [[QBUUser alloc]init];
    selectedUser.email =  user.email;//@"qwery1@yopmail.com";
    selectedUser.password = self.passwordTextField.text;

    __weak __typeof(self)weakSelf = self;
        // Logging in to Quickblox REST API and chat.
    [ServicesManager.instance logInWithUser:selectedUser completion:^(BOOL success, NSString *errorMessage) {
        if (success) {
            [SVProgressHUD dismiss];
            [SVProgressHUD showSuccessWithStatus:@"Logged in"];
            [weakSelf registerForRemoteNotifications];
            __typeof(self) strongSelf = weakSelf;
            [strongSelf performSegueWithIdentifier:kGoToMainSegueIdentifier sender:nil];
        } else {
            [SVProgressHUD showErrorWithStatus:@"Can not login"];
        }
    }];
}

- (IBAction)cancelButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.backgroundColor = [UIColor whiteColor];
}

/*- (void)retrieveUsers {
	__weak __typeof(self)weakSelf = self;
    
    // Retrieving users from cache.
    [[[ServicesManager instance].usersService loadFromCache] continueWithBlock:^id(BFTask *task) {
        //
        if ([task.result count] > 0) {
            [weakSelf loadDataSourceWithUsers:[[ServicesManager instance] filteredUsersByCurrentEnvironment]];
        } else {
            [weakSelf downloadLatestUsers];
        }
        
        return nil;
    }];
}

- (void)downloadLatestUsers
{
	if (self.isUsersAreDownloading) return;
    
	self.usersAreDownloading = YES;
	
	__weak __typeof(self)weakSelf = self;
    [SVProgressHUD showWithStatus:@"Loading users" maskType:SVProgressHUDMaskTypeClear];
	
    // Downloading latest users.
	[[ServicesManager instance] downloadLatestUsersWithSuccessBlock:^(NSArray *latestUsers) {
        [SVProgressHUD showSuccessWithStatus:@"Completed"];
        [weakSelf loadDataSourceWithUsers:latestUsers];
        weakSelf.usersAreDownloading = NO;
	} errorBlock:^(NSError *error) {
		[SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Can not download users: %@", error.localizedRecoverySuggestion]];
		weakSelf.usersAreDownloading = NO;
	}];
}

- (void)loadDataSourceWithUsers:(NSArray *)users {
	self.dataSource = [[UsersDataSource alloc] initWithUsers:users];
    self.dataSource.isLoginDataSource = YES;
}*/

#pragma mark - NotificationServiceDelegate protocol

- (void)notificationServiceDidStartLoadingDialogFromServer {
    [SVProgressHUD showWithStatus:@"Loading dialog..." maskType:SVProgressHUDMaskTypeClear];
}

- (void)notificationServiceDidFinishLoadingDialogFromServer {
    [SVProgressHUD dismiss];
}

- (void)notificationServiceDidSucceedFetchingDialog:(QBChatDialog *)chatDialog {
    DialogsViewController *dialogsController = (DialogsViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"DialogsViewController"];
    ChatViewController *chatController = (ChatViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ChatViewController"];
    chatController.dialog = chatDialog;
    
    self.navigationController.viewControllers = @[dialogsController, chatController];
}

- (void)notificationServiceDidFailFetchingDialog {
    [self performSegueWithIdentifier:kGoToDialogsSegueIdentifier sender:nil];
}

#pragma mark - Push Notifications

- (void)registerForRemoteNotifications {
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else{
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
#endif

}

@end
