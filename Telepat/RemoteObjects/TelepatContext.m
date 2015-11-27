//
//  TelepatContext.m
//  Kraken
//
//  Created by Ovidiu on 25/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatContext.h"

@implementation TelepatContext

+ (TelepatJSONKeyMapper *)keyMapper {
    return [[TelepatBaseObject keyMapper] newKeyMapperWithDictionary:@{@"id" : @"context_id"}];
}

- (BOOL) isEqual:(id)object {
    if (![object isKindOfClass:[TelepatContext class]]) return NO;
    return [((TelepatContext*)object).context_id isEqualToString:self.context_id];
}

- (NSString *) contextIdentifier {
    return [NSString stringWithFormat:@"blg:%@:context", self.application_id];
}

@end
