//
//  HomeViewCell.m
//  sample-chat
//
//  Created by GrepRuby on 31/12/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import "HomeViewCell.h"

@implementation HomeViewCell

- (void)awakeFromNib {
    // Initialization code
    [self setElementlayer];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setElementlayer {
    self.imgVwProfile.layer.cornerRadius = 25;
}

@end
