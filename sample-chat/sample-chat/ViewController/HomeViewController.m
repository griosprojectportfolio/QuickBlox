//
//  HomeViewController.m
//  sample-chat
//
//  Created by GrepRuby on 31/12/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import "HomeViewController.h"
#import "HomeViewCell.h"
#import "DetailViewController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

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
    [self setElementlayer];
    self.imgVWDotFollowing.hidden = true;
    self.imgVWDotGlobal.hidden = true;
    self.imgVWDotTrending.hidden = true;
    [self setDefaultBtnColor];
}

- (void)setDefaultBtnColor {
    [self.btnGlobal setTitleColor:[UIColor appNavigationBarTinColor] forState:UIControlStateNormal];
    [self.btnFollowing setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.btnTrending setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
}

- (void)setElementlayer {
    self.imgVWDotFollowing.layer.cornerRadius = 5;
    self.imgVWDotGlobal.layer.cornerRadius = 5;
    self.imgVWDotTrending.layer.cornerRadius = 5;
}

- (IBAction)btnGlobalAction:(id)sender {
    [self setDefaultBtnColor];
}

- (IBAction)btnTrendingAction:(id)sender {
    [self.btnGlobal setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.btnFollowing setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.btnTrending setTitleColor:[UIColor appNavigationBarTinColor] forState:UIControlStateNormal];
}

- (IBAction)btnFollowingAction:(id)sender {
    [self.btnGlobal setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.btnFollowing setTitleColor:[UIColor appNavigationBarTinColor] forState:UIControlStateNormal];
    [self.btnTrending setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
}

#pragma mark - Table view delegates methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    HomeViewCell *cellObj = [tableView dequeueReusableCellWithIdentifier:@"HomeCell"];
    return cellObj;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DetailViewController *vcObj = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailView"];
    [self.navigationController pushViewController:vcObj animated:true];
}


@end
