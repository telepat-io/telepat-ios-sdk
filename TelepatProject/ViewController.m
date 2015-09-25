//
//  ViewController.m
//  Telepat
//
//  Created by Ovidiu on 07/09/15.
//  Copyright (c) 2015 Telepat. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //    [[Telepat client] adminAdd:@"nitanovidiu@gmail.com" password:@"abracadabra" name:@"Ovidiu N." withBlock:^(TelepatResponse *response) {
    //        NSLog(@"add re: %@", response);
    //    }];
    
//    [[Telepat client] adminLogin:@"nitanovidiu@gmail.com" password:@"abracadabra" withBlock:^(TelepatResponse *response) {
//        //        [[Telepat client] createAppWithName:@"iOS Test Application" fields:@{@"testdield": @"abcd"} block:^(TelepatResponse *response) {
//        //            NSLog(@"createAppWithName response: %@", response);
//        //        }];
//        
//        [[Telepat client] listAppsWithBlock:^(TelepatResponse *response) {
//            NSLog(@"listAppsWithBlock response: %@", [response getObjectOfType:[TelepatApp class]]);
//        }];
//    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
