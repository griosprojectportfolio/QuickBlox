//
//  ProfileViewController.m
//  sample-chat
//
//  Created by GrepRuby on 31/12/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import "ProfileViewController.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self applyDefault];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)applyDefault {
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background"]];
    _arrData = [[NSArray alloc]initWithObjects:@"2,400 Post",@"124 Followers",@"23 Following",@"204 Favories", nil];
    [self setLayer];
}

- (void)setLayer {
    self.imgVWProfile.layer.cornerRadius = 60;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_arrData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cellObj = [tableView dequeueReusableCellWithIdentifier:@"ProfileCell"];
    cellObj.textLabel.text = [self.arrData objectAtIndex:indexPath.row];
    cellObj.textLabel.textColor = [UIColor whiteColor];
    return cellObj;
}

@end
