//
//  TelepatUser.m
//  GW Sales
//
//  Created by Ovidiu on 07/08/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatUser.h"
#import "Telepat.h"

@implementation TelepatUser

+ (BOOL) propertyIsOptional:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"isAdmin"]) return YES;
    return NO;
}

+ (instancetype) userWithUsername:(NSString *)username email:(NSString *)email password:(NSString *)password {
    TelepatUser *user = [[TelepatUser alloc] init];
    user.username = username;
    user.password = password;
    user.email = email;
    
    return user;
}

- (NSString *) user_id {
    return self.object_id;
}

- (void) setUser_id:(NSString<Ignore> *)user_id {
    self.object_id = user_id;
}

@end
