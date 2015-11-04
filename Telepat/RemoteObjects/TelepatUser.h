//
//  TelepatUser.h
//  GW Sales
//
//  Created by Ovidiu on 07/08/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatBaseObject.h"

@interface TelepatUser : TelepatBaseObject

@property (nonatomic, strong) NSString<Ignore> *user_id;
@property (nonatomic, strong) NSString<Optional> *type;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString<Optional> *password;
@property (nonatomic, strong) NSArray<Optional> *devices;
@property (nonatomic) BOOL isAdmin;

@end
