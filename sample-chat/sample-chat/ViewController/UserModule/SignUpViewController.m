//
//  SignUpTableViewController.m
//  sample-users
//
//  Created by Quickblox Team on 8/27/15.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "SignUpViewController.h"
#import <Quickblox/Quickblox.h>
#import "SVProgressHUD.h"
#import <Quickblox/QBRequest.h>

@interface SignUpViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *txtFldEmail;
@property (nonatomic, weak) IBOutlet UITextField *txtFldPassword;
@property (nonatomic, weak) IBOutlet UITextField *txtFldUsername;
@property (nonatomic, weak) IBOutlet UITextField *txtFldConfirmationPassword;
@end

@implementation SignUpViewController
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL)isPasswordConfirmed {

    BOOL confirmed;
    if (self.txtFldPassword.text == nil || self.txtFldPassword.text.length == 0) {
        confirmed = NO;
    } else if (self.txtFldConfirmationPassword.text == nil || self.txtFldConfirmationPassword.text.length == 0) {
        confirmed = NO;
    } else {
        confirmed = [self.txtFldPassword.text isEqualToString:self.txtFldConfirmationPassword.text];
    }
    
    self.txtFldPassword.backgroundColor = confirmed ? [UIColor whiteColor] : [UIColor redColor];
    self.txtFldPassword.backgroundColor = confirmed ? [UIColor whiteColor] : [UIColor redColor];
    
    return confirmed;
}

- (BOOL)isLoginTextValid {
    BOOL loginValid = (self.txtFldEmail.text != nil && self.txtFldEmail.text.length > 0);
    self.txtFldEmail.backgroundColor = loginValid ? [UIColor whiteColor] : [UIColor redColor];
    return loginValid;
}

- (BOOL)isNameValid {
    BOOL nameValid = (self.txtFldUsername.text != nil && self.txtFldUsername.text.length > 0);
    self.txtFldEmail.backgroundColor = nameValid ? [UIColor whiteColor] : [UIColor redColor];
    return nameValid;
}

- (IBAction)signUpBtnTapped:(id)sender {
    [self.view endEditing:YES];
    
    BOOL confirmed = [self isPasswordConfirmed];
    BOOL nonEmptyLogin = [self isLoginTextValid];
    BOOL nonEmptyUsername = [self isNameValid];

    if (confirmed && nonEmptyLogin && nonEmptyUsername) {
        [SVProgressHUD showWithStatus:@"Signing up"];

        QBUUser *user = [QBUUser new];
        user.login = self.txtFldEmail.text;
        user.email = self.txtFldEmail.text;
        user.fullName = self.txtFldUsername.text;
        user.password = self.txtFldPassword.text;
        
        NSString* password = user.password;

        [QBRequest signUp:user successBlock:^(QBResponse *response, QBUUser *user) {
            [QBRequest logInWithUserLogin:user.login password:password successBlock:^(QBResponse *response, QBUUser *user) {
                [SVProgressHUD dismiss];
                [self signUpApiCall:user];
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
}

- (void)signUpApiCall:(QBUUser*)user {
    NSDictionary *aParam = @{

                             };
    [sharedDelegate.apiOperation  callPostUrl:aParam method:@"" success:^(NSURLSessionTask *task, id responseObject) {

    } failure:^(NSURLSessionTask *task, NSError *error) {

    }];
}

- (IBAction)cancelButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.backgroundColor = [UIColor whiteColor];
}

@end
