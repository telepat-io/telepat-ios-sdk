//
//  TelepatUser.h
//  GW Sales
//
//  Created by Ovidiu on 07/08/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatBaseObject.h"
#import "TelepatUserMetadata.h"

@interface TelepatUser : TelepatBaseObject

@property (nonatomic, strong) NSString<Ignore> *user_id;
@property (nonatomic, strong) NSString<Optional> *type;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString<Optional> *password;
@property (nonatomic, strong) NSArray<Optional> *devices;
@property (nonatomic) BOOL isAdmin;

/*
 *  Create a user with the given username, email and password.
 *  Useful when you want to create a user to register on Telepat
 *
 *  @param username The username of the user
 *  @param email The email of the user
 *  @param password The password of the user
 *
 *  @return An instance of `TelepatUser`
 */
+ (instancetype) userWithUsername:(NSString *)username email:(NSString *)email password:(NSString *)password;

@end
