//
//  TelepatApp.m
//  Pods
//
//  Created by Ovidiu on 22/09/15.
//
//

#import "TelepatApp.h"
#import "Telepat.h"

@implementation TelepatApp

+ (JSONKeyMapper *) keyMapper {
    return [[JSONKeyMapper alloc] initWithDictionary:@{@"id" : @"app_id"}];
}

- (BOOL) isEqual:(id)object {
    if (![object isKindOfClass:[TelepatApp class]]) return NO;
    return [((TelepatApp *)object).app_id isEqualToString:self.app_id];
}

- (NSDictionary *) patchAgainst:(TelepatBaseObject *)updatedObject {
    if (![updatedObject isMemberOfClass:[TelepatApp class]]) @throw([NSException exceptionWithName:kTelepatInvalidClass reason:@"The received object is not the same as the current one" userInfo:nil]);
    NSMutableDictionary *patch = [NSMutableDictionary dictionary];
    
    NSMutableArray *patches = [NSMutableArray array];
    for (NSString *property in [updatedObject propertiesList]) {
        if (![[updatedObject valueForKey:property] isEqual:[self valueForKey:property]]) {
            NSMutableDictionary *patchDict = [NSMutableDictionary dictionary];
            patchDict[@"path"] = [NSString stringWithFormat:@"application/%@/%@", self.object_id, property];
            
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

@end
