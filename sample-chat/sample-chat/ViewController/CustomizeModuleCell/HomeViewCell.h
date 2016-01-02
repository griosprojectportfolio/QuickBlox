//
//  HomeViewCell.h
//  sample-chat
//
//  Created by GrepRuby on 31/12/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeViewCell : UITableViewCell

@property(retain,nonatomic)IBOutlet UIImageView *imgVwProfile;
@property(retain,nonatomic)IBOutlet UIImageView *imgVw;
@property(retain,nonatomic)IBOutlet UIView *VwElement;
@property(retain,nonatomic)IBOutlet UILabel *lblName;
@property(retain,nonatomic)IBOutlet UILabel *lblContent;
@property(retain,nonatomic)IBOutlet UIButton *btnLike;
@property(retain,nonatomic)IBOutlet UIButton *btnComment;
@property(retain,nonatomic)IBOutlet UILabel *lblLikeCount;
@property(retain,nonatomic)IBOutlet UILabel *lblCommentCount;

@end
