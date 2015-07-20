//
//  TelepatContext.m
//  Kraken
//
//  Created by Ovidiu on 25/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatContext.h"

@implementation TelepatContext

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithDictionary:@{
        @"id" : @"context_id"}];
}

@end
