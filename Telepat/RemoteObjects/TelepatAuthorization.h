//
//  KRToken.h
//  Kraken
//
//  Created by Ovidiu on 24/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatBaseObject.h"
#import "TelepatUser.h"

@interface TelepatAuthorization : TelepatBaseObject

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) TelepatUser<Optional> *user;

@end
