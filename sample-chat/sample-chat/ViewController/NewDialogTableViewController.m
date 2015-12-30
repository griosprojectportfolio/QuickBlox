//
//  NewDialogTableViewController.m
//  sample-chat
//
//  Created by Anton Sokolchenko on 5/29/15.
//  Copyright (c) 2015 Igor Khomenko. All rights reserved.
//

#import "NewDialogTableViewController.h"
#import "ServicesManager.h"
#import "ChatViewController.h"
#import "UIAlertDialog.h"

@interface NewDialogTableViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) NSMutableArray *marryFriend;
@end

@implementation NewDialogTableViewController

- (void)viewDidLoad
{
        // self.dataSource = [[UsersDataSource alloc] initWithUsers:[[ServicesManager instance] filteredUsersByCurrentEnvironment]];
        // [self.dataSource setExcludeUsersIDs:@[@([QBSession currentSession].currentUser.ID)]];
        //self.tableView.dataSource = self.dataSource;
    _marryFriend = [[NSMutableArray alloc]init];
	[super viewDidLoad];

    [self friendList];
    self.tableView.tableFooterView = [UIView new];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self checkJoinChatButtonState];
	[self.tableView reloadData];
}

- (void)checkJoinChatButtonState
{
	self.navigationItem.rightBarButtonItem.enabled = self.tableView.indexPathsForSelectedRows.count != 0;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kGoToChatSegueIdentifier]) {
        ChatViewController* viewController = segue.destinationViewController;
        viewController.shouldUpdateNavigationStack = YES;
        viewController.dialog = sender;
    }
}

- (NSArray *)friendList {
    QBContactList *contactList = [QBChat instance].contactList;
    NSLog(@"%@",contactList);
    NSArray *arryFriend = contactList.contacts;
    for (QBContactListItem *userContact in arryFriend) {
            //  QBContactListItem *userContact = [arryFriend objectAtIndex:0];
        NSInteger userId = userContact.userID;
        [_marryFriend addObject:[Storage userFromId:userId]];
        [self.tableView reloadData];
    }
        //[self performSegueWithIdentifier:kGoToDialogsSegueIdentifier sender:nil];
    return _marryFriend;
}


- (void)navigateToChatViewControllerWithDialog:(QBChatDialog *)dialog
{
    [self performSegueWithIdentifier:kGoToChatSegueIdentifier sender:dialog];
}


- (IBAction)joinChatButtonPressed:(UIButton *)sender {
    __weak __typeof(self) weakSelf = self;

    [self createChatWithName:nil completion:^(QBChatDialog *dialog) {
        __typeof(self) strongSelf = weakSelf;
        if( dialog != nil ) {
            [strongSelf navigateToChatViewControllerWithDialog:dialog];
        }
        else {
            [SVProgressHUD showErrorWithStatus:@"Can not create dialog"];
        }
    }];
    return;
    if (self.tableView.indexPathsForSelectedRows.count == 1) {

    } else {
        UIAlertDialog *dialog = [[UIAlertDialog alloc] initWithStyle:UIAlertDialogStyleAlert title:@"Enter chat name:" andMessage:@""];

        [dialog addButtonWithTitle:@"Create" andHandler:^(NSInteger buttonIndex, UIAlertDialog *dialog) {
            __typeof(self) strongSelf = weakSelf;
            sender.enabled = NO;
            [strongSelf createChatWithName:[dialog textFieldText] completion:^(QBChatDialog *dialog){
                sender.enabled = YES;
                if( dialog != nil ) {
                    [strongSelf navigateToChatViewControllerWithDialog:dialog];
                }
                else {
                    [SVProgressHUD showErrorWithStatus:@"Can not create dialog"];
                }
            }];
        }];
        dialog.showTextField = YES;
        dialog.textFieldPlaceholderText = @"Enter chat name";
        [dialog showInViewController:self];
    }
}

- (void)createChatWithName:(NSString *)name completion:(void(^)(QBChatDialog* dialog))completion {
    NSMutableIndexSet* indexSet = [NSMutableIndexSet indexSet];
    [self.tableView.indexPathsForSelectedRows enumerateObjectsUsingBlock:^(NSIndexPath* obj, NSUInteger idx, BOOL *stop) {
        [indexSet addIndex:obj.row];
    }];

    NSArray *selectedUsers = [self.marryFriend objectsAtIndexes:indexSet];//dataSource.users objectsAtIndexes:indexSet];

    if (selectedUsers.count == 1) {
            // Creating private chat dialog.
        [ServicesManager.instance.chatService createPrivateChatDialogWithOpponent:selectedUsers.firstObject completion:^(QBResponse *response, QBChatDialog *createdDialog) {
            if( !response.success  && createdDialog == nil ) {
                if (completion) completion(nil);
            }
            else {
                if (completion) completion(createdDialog);
            }
        }];
    } else if (selectedUsers.count > 1) {
        if (name == nil || [[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
            name = [NSString stringWithFormat:@"%@_", [QBSession currentSession].currentUser.login];
            for (QBUUser *user in selectedUsers) {
                name = [NSString stringWithFormat:@"%@%@,", name, user.login];
            }
            name = [name substringToIndex:name.length - 1]; // remove last , (comma)
        }

            //uncomment when api has start
            /*[self createGroupApiCallWithName:name groupMember:selectedUsers completion:^(QBChatDialog *dialog) {
                if(dialog != nil) {
                    completion(dialog);
                } else {
                    completion(nil);
                }
            }];*/

            //comment when api start
            [self createGroupDialogwithName:name groupMember:selectedUsers completion:^(QBChatDialog *dialog) {
                if(dialog != nil) {
                    completion(dialog);
                } else {
                    completion(nil);
                }
        }];

        [SVProgressHUD showWithStatus:@"Creating dialog..." maskType:SVProgressHUDMaskTypeClear];

    } else {
        assert("no users given");
    }
}

- (void)createGroupDialogwithName:(NSString*)name groupMember:(NSArray*)selectedUsers completion:(void(^)(QBChatDialog* dialog))completion {
        // Creating group chat dialog.
    [ServicesManager.instance.chatService createGroupChatDialogWithName:name photo:nil occupants:selectedUsers completion:^(QBResponse *response, QBChatDialog *createdDialog) {
        if (response.success) {
                // Notifying users about created dialog.
            [[ServicesManager instance].chatService sendSystemMessageAboutAddingToDialog:createdDialog toUsersIDs:createdDialog.occupantIDs completion:^(NSError *error) {
                    //
                if (completion) completion(createdDialog);
            }];
        } else {
            if (completion) completion(nil);
        }
    }];
}

- (void)createGroupApiCallWithName:(NSString*)name groupMember:(NSArray*)selectedUsers completion:(void(^)(QBChatDialog* dialog))completion {
    NSDictionary *aParam = @{
                             };
    [sharedDelegate.apiOperation callPostUrl:aParam method:@"" success:^(NSURLSessionTask *task, id responseObject) {
        [self createGroupDialogwithName:name groupMember:selectedUsers completion:^(QBChatDialog *dialog) {
            NSLog(@"success");
            if(dialog != nil) {
                completion(dialog);
            } else {
                completion(nil);
            }
        }];
    } failure:^(NSURLSessionTask *task, NSError *error) {

    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {


}

/*- (IBAction)joinChatButtonPressed:(UIButton *)sender {
	__weak __typeof(self) weakSelf = self;
	
	if (self.tableView.indexPathsForSelectedRows.count == 1) {
		[self createChatWithName:nil completion:^(QBChatDialog *dialog) {
            __typeof(self) strongSelf = weakSelf;
			if( dialog != nil ) {
				[strongSelf navigateToChatViewControllerWithDialog:dialog];
			}
			else {
				[SVProgressHUD showErrorWithStatus:@"Can not create dialog"];
			}
		}];
	} else {
		UIAlertDialog *dialog = [[UIAlertDialog alloc] initWithStyle:UIAlertDialogStyleAlert title:@"Enter chat name:" andMessage:@""];
		
		[dialog addButtonWithTitle:@"Create" andHandler:^(NSInteger buttonIndex, UIAlertDialog *dialog) {
            __typeof(self) strongSelf = weakSelf;
			sender.enabled = NO;
			[strongSelf createChatWithName:[dialog textFieldText] completion:^(QBChatDialog *dialog){
				sender.enabled = YES;
				if( dialog != nil ) {
					[strongSelf navigateToChatViewControllerWithDialog:dialog];
				}
				else {
					[SVProgressHUD showErrorWithStatus:@"Can not create dialog"];
				}
			}];
		}];
		dialog.showTextField = YES;
		dialog.textFieldPlaceholderText = @"Enter chat name";
		[dialog showInViewController:self];
	}
}

- (void)createChatWithName:(NSString *)name completion:(void(^)(QBChatDialog* dialog))completion
{
    NSMutableIndexSet* indexSet = [NSMutableIndexSet indexSet];
    [self.tableView.indexPathsForSelectedRows enumerateObjectsUsingBlock:^(NSIndexPath* obj, NSUInteger idx, BOOL *stop) {
        [indexSet addIndex:obj.row];
    }];
	
	NSArray *selectedUsers = [self.dataSource.users objectsAtIndexes:indexSet];
	
	if (selectedUsers.count == 1) {
        // Creating private chat dialog.
		[ServicesManager.instance.chatService createPrivateChatDialogWithOpponent:selectedUsers.firstObject completion:^(QBResponse *response, QBChatDialog *createdDialog) {
			if( !response.success  && createdDialog == nil ) {
				if (completion) completion(nil);
			}
			else {
				if (completion) completion(createdDialog);
			}
		}];
	} else if (selectedUsers.count > 1) {
		if (name == nil || [[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
			name = [NSString stringWithFormat:@"%@_", [QBSession currentSession].currentUser.login];
			for (QBUUser *user in selectedUsers) {
				name = [NSString stringWithFormat:@"%@%@,", name, user.login];
			}
			name = [name substringToIndex:name.length - 1]; // remove last , (comma)
		}
		
		[SVProgressHUD showWithStatus:@"Creating dialog..." maskType:SVProgressHUDMaskTypeClear];
		
        // Creating group chat dialog.
		[ServicesManager.instance.chatService createGroupChatDialogWithName:name photo:nil occupants:selectedUsers completion:^(QBResponse *response, QBChatDialog *createdDialog) {
			if (response.success) {
                // Notifying users about created dialog.
                [[ServicesManager instance].chatService sendSystemMessageAboutAddingToDialog:createdDialog toUsersIDs:createdDialog.occupantIDs completion:^(NSError *error) {
                    //
                    if (completion) completion(createdDialog);
                }];
			} else {
				if (completion) completion(nil);
			}
		}];
	} else {
		assert("no users given");
	}
}*/

#pragma mark UITableView delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_marryFriend count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell*cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell"];
    QBUUser *user = [self.marryFriend objectAtIndex:indexPath.row];
    cell.textLabel.text = user.fullName;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self checkJoinChatButtonState];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self checkJoinChatButtonState];
}

@end