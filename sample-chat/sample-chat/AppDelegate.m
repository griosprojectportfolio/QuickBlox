//
//  AppDelegate.m
//  sample-chat
//
//  Created by Igor Khomenko on 10/16/13.
//  Copyright (c) 2013 Igor Khomenko. All rights reserved.
//

#import "AppDelegate.h"
#import "ServicesManager.h"
#import "ChatViewController.h"

//const NSUInteger kApplicationID = 28783;
//NSString *const kAuthKey        = @"b5bVGCHHv6rcAmD";
//NSString *const kAuthSecret     = @"ySwEpardeE7ZXHB";
//NSString *const kAcconuntKey    = @"7yvNe17TnjNUqDoPwfqp";

const NSUInteger kApplicationID = 32699;
NSString *const kAuthKey        = @"A7XWw8DN5gzBR8J";
NSString *const kAuthSecret     = @"FzROKbyn2e6CDwG";
NSString *const kAcconuntKey    = @"E6dM1TpyqRQGWR3KanjM";

@interface AppDelegate () <NotificationServiceDelegate>

@end

@implementation AppDelegate 

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Set QuickBlox credentials (You must create application in admin.quickblox.com)
    [QBSettings setApplicationID:kApplicationID];
    [QBSettings setAuthKey:kAuthKey];
    [QBSettings setAuthSecret:kAuthSecret];
    [QBSettings setAccountKey:kAcconuntKey];
    
    // Enables Quickblox REST API calls debug console output
    [QBSettings setLogLevel:QBLogLevelDebug];
    
    // Enables detailed XMPP logging in console output
    [QBSettings enableXMPPLogging];

    _apiOperation = [ChatApi sharedClient];

    // app was launched from push notification, handling it
    if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        ServicesManager.instance.notificationService.pushDialogID = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey][kPushNotificationDialogIdentifierKey];
    }
    [self setTableViewAppearance];
    [self setNaviagtionAppearance];
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *deviceIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // subscribing for push notifications
    QBMSubscription *subscription = [QBMSubscription subscription];
    subscription.notificationChannel = QBMNotificationChannelAPNS;
    subscription.deviceUDID = deviceIdentifier;
    subscription.deviceToken = deviceToken;
    
    [QBRequest createSubscription:subscription successBlock:^(QBResponse *response, NSArray *objects) {
        //
    } errorBlock:^(QBResponse *response) {
        //
    }];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    // failed to register push
    NSLog(@"Push failed to register with error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if ([application applicationState] == UIApplicationStateInactive)
    {
        NSString *dialogID = userInfo[kPushNotificationDialogIdentifierKey];
        if (dialogID != nil) {
            NSString *dialogWithIDWasEntered = [ServicesManager instance].currentDialogID;
            if ([dialogWithIDWasEntered isEqualToString:dialogID]) return;
            
            ServicesManager.instance.notificationService.pushDialogID = dialogID;
            [ServicesManager.instance.notificationService handlePushNotificationWithDelegate:self];
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Logout from chat
    //
	[ServicesManager.instance.chatService disconnectWithCompletionBlock:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	
    // Login to QuickBlox Chat
    //
	[ServicesManager.instance.chatService connectWithCompletionBlock:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Nvigation Apprence

- (void) setNaviagtionAppearance {
    [UINavigationBar appearance].barTintColor = [UIColor appNavigationBarTinColor];
    [UINavigationBar appearance].tintColor = [UIColor whiteColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
}

#pragma mark - Nvigation Apprence
- (void) setTableViewAppearance {
    [UITableView appearance].tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.window.frame];
    backgroundView.backgroundColor =
    [UIColor colorWithPatternImage:
     [UIImage imageNamed:@"Background"]];
    [UITableView appearance].backgroundColor = [UIColor clearColor];
    //[UITableView appearance].backgroundView = backgroundView;
}

#pragma mark - NotificationServiceDelegate protocol

- (void)notificationServiceDidSucceedFetchingDialog:(QBChatDialog *)chatDialog {
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    
    ChatViewController *chatController = (ChatViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatViewController"];
    chatController.dialog = chatDialog;
    
    NSString *dialogWithIDWasEntered = [ServicesManager instance].currentDialogID;
    if (dialogWithIDWasEntered != nil) {
        // some chat already opened, return to dialogs view controller first
        [navigationController popViewControllerAnimated:NO];
    }
    
    [navigationController pushViewController:chatController animated:NO];
}

@end
