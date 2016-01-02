//
//  ProfileViewController.h
//  sample-chat
//
//  Created by GrepRuby on 31/12/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,retain)IBOutlet UIImageView *imgVWProfile;
@property(nonatomic,retain)IBOutlet UILabel *lblName;
@property(nonatomic,retain)IBOutlet UILabel *lblMail;
@property(nonatomic,retain)IBOutlet UILabel *lblAddress;
@property(nonatomic,retain)IBOutlet UITableView *tblProfile;

@property(nonatomic,retain) NSArray *arrData;


@end
