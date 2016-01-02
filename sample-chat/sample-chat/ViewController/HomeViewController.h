//
//  HomeViewController.h
//  sample-chat
//
//  Created by GrepRuby on 31/12/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,retain)IBOutlet UITableView *tblHome;

@property(nonatomic,retain)IBOutlet UIButton *btnGlobal;
@property(nonatomic,retain)IBOutlet UIButton *btnTrending;
@property(nonatomic,retain)IBOutlet UIButton *btnFollowing;

@property(nonatomic,retain)IBOutlet UIImageView *imgVWDotGlobal;
@property(nonatomic,retain)IBOutlet UIImageView *imgVWDotTrending;
@property(nonatomic,retain)IBOutlet UIImageView *imgVWDotFollowing;

- (IBAction)btnGlobalAction:(id)sender;
- (IBAction)btnTrendingAction:(id)sender;
- (IBAction)btnFollowingAction:(id)sender;

@end
