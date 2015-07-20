//
//  KRBaseObject.m
//  Kraken
//
//  Created by Ovidiu on 24/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatBaseObject.h"

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
    if (obj.object_id == self.object_id) return YES;
    return NO;
}

- (NSComparisonResult) compare:(id)object {
    if (![object isMemberOfClass:[self class]]) return NO;
    TelepatBaseObject *obj = object;
    return [[NSNumber numberWithInt:self.object_id] compare:[NSNumber numberWithInt:obj.object_id]];
}

@end
