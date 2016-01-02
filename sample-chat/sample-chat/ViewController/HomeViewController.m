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
}

- (void)setElementlayer {
    self.imgVWDotFollowing.layer.cornerRadius = 5;
    self.imgVWDotGlobal.layer.cornerRadius = 5;
    self.imgVWDotTrending.layer.cornerRadius = 5;
}




- (IBAction)btnGlobalAction:(id)sender {
    
}

- (IBAction)btnTrendingAction:(id)sender {
    
}

- (IBAction)btnFollowingAction:(id)sender {
    
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
