//
//  TelepatUserMetadata.m
//  Pods
//
//  Created by Ovidiu on 24/02/16.
//
//

#import "TelepatUserMetadata.h"

@implementation TelepatUserMetadata

+ (TelepatJSONKeyMapper *)keyMapper {
    return [[TelepatBaseObject keyMapper] newKeyMapperWithDictionary:@{@"user_id" : @"userId"}];
}

@end
