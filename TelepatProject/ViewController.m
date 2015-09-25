//
//  ViewController.m
//  Telepat
//
//  Created by Ovidiu on 07/09/15.
//  Copyright (c) 2015 Telepat. All rights reserved.
//

#import "ViewController.h"

@interface Event : TelepatBaseObject

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *image;

@end

@implementation Event

@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Set the API key and the current application ID
//    [[Telepat client] setApiKey:@"API_KEY"];
//    [[Telepat client] setAppId:@"APP_ID"];
//    
//    [[Telepat client] login:@"username@example.com" password:@"mysecurepassword" withBlock:^(TelepatResponse *response) {
//        [[Telepat client] getContextsWithBlock:^(TelepatResponse *response) {
//            NSArray *contexts = [response getObjectOfType:[TelepatContext class]];
//            TelepatContext *firstContext = contexts[0];
//            TelepatChannel *firstChannel = [[Telepat client] subscribe:firstContext modelName:@"events" classType:[Event class] withBlock:^(TelepatResponse *response) {
//                NSLog(@"Subscribed to %@", firstContext.name);
//            }];
//            
//            Event *newEvent = [[Event alloc] init];
//            newEvent.text = @"Hello world!";
//            newEvent.image = @"telepat_image.png";
//            
//            [firstChannel add:newEvent];
//            
//            Event *modifiedEvent = [[Event alloc] initWithDi];
//        }];
//        
//    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
