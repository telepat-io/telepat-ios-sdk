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

- (NSString *) user_id {
    return self.object_id;
}

@end
