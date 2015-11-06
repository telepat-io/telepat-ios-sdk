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

@end
