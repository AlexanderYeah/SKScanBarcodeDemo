//
//  ViewController.m
//  SKScanDemo
//
//  Created by XunLi on 2017/6/27.
//  Copyright © 2017年 AlexanderYeah. All rights reserved.
//

#import "ViewController.h"
#import "SKScanViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"扫描" forState:UIControlStateNormal];
    btn.frame =CGRectMake(100, 200, 200, 200);
    btn.backgroundColor = [UIColor redColor];
    [btn addTarget:self action:@selector(beginScan) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    
}

#pragma mark - 扫描
- (void)beginScan
{
    SKScanViewController *scanVC = [[SKScanViewController alloc]init];
    
    [self.navigationController pushViewController:scanVC animated:YES];
    
    
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
