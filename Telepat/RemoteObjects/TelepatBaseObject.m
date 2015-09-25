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
//    if (![updatedObject isMemberOfClass:[self class]]) @throw([NSException exceptionWithName:kTelepatInvalidClass reason:@"The received object is not the same as the current one" userInfo:nil]);
//    NSMutableArray *patch = [NSMutableArray array];
//    
//    NSMutableArray *patches = [NSMutableArray array];
//    for (NSString *property in [updatedObject propertiesList]) {
//        if (![[updatedObject valueForKey:property] isEqual:[self valueForKey:property]]) {
//            NSMutableDictionary *patchDict = [NSMutableDictionary dictionary];
//            patchDict[@"path"] = [NSString stringWithFormat:@"%@/%ld/%@", self.modelName, (long)object.object_id, property];
//            
//            if ([object valueForKey:property] == nil) {
//                patchDict[@"op"] = @"delete";
//            } else {
//                patchDict[@"op"] = @"replace";
//                patchDict[@"value"] = [object valueForKey:property];
//            }
//            
//            [patches addObject:patchDict];
//        }
//    }
    
    return @{};
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

@end
