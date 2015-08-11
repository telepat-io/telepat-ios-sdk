//
//  TelepatUser.h
//  GW Sales
//
//  Created by Ovidiu on 07/08/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatBaseObject.h"

@interface TelepatUser : TelepatBaseObject

@property (nonatomic) NSInteger user_id;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *email;
@property (nonatomic) BOOL suspended;

@end
