//
//  KRBaseObject.m
//  Kraken
//
//  Created by Ovidiu on 24/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <objc/runtime.h>
#import "TelepatBaseObject.h"
#import "Telepat.h"

@implementation TelepatBaseObject

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithDictionary:@{
            @"id" : @"object_id"}];
}

+ (BOOL) propertyIsOptional:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"object_id"]) {
        return YES;
    }
    return NO;
}

- (BOOL) isEqual:(id)object {
    if (![object isMemberOfClass:[self class]]) return NO;
    TelepatBaseObject *obj = object;
    if ([obj.object_id isEqualToString:self.object_id]) return YES;
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
                patchDict[@"value"] = [updatedObject toDictionary][property];
            }
            
            [patches addObject:patchDict];
        }
    }
    
    if ([patches count]) [patch setObject:patches forKey:@"patches"];
    return [NSDictionary dictionaryWithDictionary:patch];
}

- (NSArray *) propertiesList {
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    NSMutableArray *rv = [NSMutableArray array];
    
    unsigned i;
    for (i = 0; i < count; i++)
    {
        objc_property_t property = properties[i];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        [rv addObject:name];
    }
    
    free(properties);
    return rv;
}

- (void) update {
    [self updateWithBlock:nil];
}

- (void) updateWithBlock:(TelepatResponseBlock)block {
    if (!self.channel) @throw [NSException exceptionWithName:kTelepatNoChannelError reason:[NSString stringWithFormat:@"You tried to update object %@ but it's channel is null", self] userInfo:nil];
    [self.channel patch:self withBlock:block];
}

@end
