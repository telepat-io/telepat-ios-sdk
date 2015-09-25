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

- (NSDictionary *) patchAgainst:(TelepatBaseObject *)updatedObject {
    if (![updatedObject isKindOfClass:[TelepatUser class]]) @throw([NSException exceptionWithName:kTelepatInvalidClass reason:@"The received object is not the same as the current one" userInfo:nil]);
    NSMutableDictionary *patch = [NSMutableDictionary dictionary];
    
    NSMutableArray *patches = [NSMutableArray array];
    for (NSString *property in [updatedObject propertiesList]) {
        if (![[updatedObject valueForKey:property] isEqual:[self valueForKey:property]]) {
            NSMutableDictionary *patchDict = [NSMutableDictionary dictionary];
            patchDict[@"path"] = [NSString stringWithFormat:@"user/%@/%@", self.object_id, property];
            
            if ([updatedObject valueForKey:property] == nil) {
                patchDict[@"op"] = @"delete";
            } else {
                patchDict[@"op"] = @"replace";
                patchDict[@"value"] = [updatedObject valueForKey:property];
            }
            
            [patches addObject:patchDict];
        }
    }
    
    if ([patches count]) [patch setObject:patches forKey:@"patches"];
    return [NSDictionary dictionaryWithDictionary:patch];
}

- (NSString *) user_id {
    return self.object_id;
}

@end
