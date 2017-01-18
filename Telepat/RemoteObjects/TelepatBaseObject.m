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

@interface JSONModel ()

-(NSArray*)__properties__;
- (BOOL)__customSetValue:(id<NSObject>)value forProperty:(JSONModelClassProperty*)property;

@end

@implementation JSONValueTransformer (CustomTransformer)

- (NSDate *)NSDateFromNSString:(NSString*)string {
    return [NSDate dateWithTimeIntervalSince1970:[string integerValue]];
}

- (NSNumber *)JSONObjectFromNSDate:(NSDate *)date {
    return [NSNumber numberWithInteger:[date timeIntervalSince1970]];
}

@end

@implementation TelepatBaseObject

+ (TelepatJSONKeyMapper *)keyMapper {
    return [[TelepatJSONKeyMapper alloc] initWithDictionary:@{
            @"id" : @"object_id"}];
}

+ (BOOL) propertyIsOptional:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"object_id"]) {
        return YES;
    }
    return NO;
}

- (id) copy {
    TelepatBaseObject *obj = [[[self class] alloc] init];
    [obj mergeFromDictionary:[self toDictionary] useKeyMapping:YES];
    return obj;
}

- (BOOL) isEqual:(id)object {
    if (![object isMemberOfClass:[self class]]) return NO;
    TelepatBaseObject *obj = object;
    if ([obj.object_id isEqualToString:self.object_id]) return YES;
    return NO;
}

- (NSDictionary *_Nullable) patchAgainst:(TelepatBaseObject *_Nonnull)updatedObject withModel:(NSString *_Nonnull)model {
    if (![updatedObject isKindOfClass:[TelepatBaseObject class]]) @throw([NSException exceptionWithName:kTelepatInvalidClass reason:@"The received object is not the same as the current one" userInfo:nil]);
    NSMutableDictionary *patch = [NSMutableDictionary dictionary];
    
    NSMutableArray *patches = [NSMutableArray array];
    for (NSString *property in [updatedObject propertiesList]) {
        id initialValue = [self valueForKey:property];
        id updatedValue = [updatedObject valueForKey:property];
        if (!(initialValue == nil && updatedValue == nil) && ![updatedValue isEqual:initialValue]) {
            NSString *convertedProperty = [[[updatedObject class] keyMapper] convertValue:property isImportingToModel:YES];
            NSMutableDictionary *patchDict = [NSMutableDictionary dictionary];
            patchDict[@"path"] = [NSString stringWithFormat:@"%@/%@/%@", model, self.object_id, convertedProperty];
            
//            if ([updatedObject valueForKey:property] == nil) {
//                patchDict[@"op"] = @"delete";
//            } else {
//                patchDict[@"op"] = @"replace";
//                patchDict[@"value"] = [updatedObject toDictionary][property];
//            }
            
            id newValue = [updatedObject toDictionary][convertedProperty];
            patchDict[@"op"] = @"replace";
            patchDict[@"value"] = newValue ? newValue : @"";
            
            [patches addObject:patchDict];
        }
    }
    
    if ([patches count]) [patch setObject:patches forKey:@"patches"];
    return [NSDictionary dictionaryWithDictionary:patch];
}

- (NSArray *) propertiesList {
    NSMutableArray *mutablePropertiesList = [NSMutableArray array];
    for (JSONModelClassProperty *property in [self __properties__]) {
        [mutablePropertiesList addObject:property.name];
    }
    
    return [NSArray arrayWithArray:mutablePropertiesList];
}

- (void) setValue:(id<NSObject>)value forProperty:(NSString *)propertyName {
    NSMutableDictionary *origDict = [NSMutableDictionary dictionaryWithDictionary:[self toDictionary]];
    if ([origDict[propertyName] isKindOfClass:[NSDictionary class]] && [value isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mutableSubdict = [NSMutableDictionary dictionaryWithDictionary:origDict[propertyName]];
        [mutableSubdict addEntriesFromDictionary:(NSDictionary *)value];
        [origDict setValue:[NSDictionary dictionaryWithDictionary:mutableSubdict] forKey:[[[self class] keyMapper] convertValue:propertyName isImportingToModel:YES]];
    } else {
        [origDict setValue:value forKey:[[[self class] keyMapper] convertValue:propertyName isImportingToModel:YES]];
    }
    [self mergeFromDictionary:origDict useKeyMapping:YES];
}

- (void) update {
    [self updateWithBlock:nil];
}

- (void) updateWithBlock:(TelepatResponseBlock)block {
    if (!self.channel) @throw [NSException exceptionWithName:kTelepatNoChannelError reason:[NSString stringWithFormat:@"You tried to update object %@ but it's channel is null", self] userInfo:nil];
    [self.channel patch:self withBlock:block];
}

@end
