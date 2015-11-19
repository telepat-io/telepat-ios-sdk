//
//  KRBaseObject.h
//  Kraken
//
//  Created by Ovidiu on 24/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "JSONModel.h"
#import "JSONModelClassProperty.h"
#import "TelepatJSONKeyMapper.h"
#define kTelepatNoChannelError @"NoChannelError"

@class TelepatChannel, TelepatResponse;
typedef void (^TelepatResponseBlock)(TelepatResponse *response);

@interface TelepatBaseObject : JSONModel

@property (nonatomic) NSString *object_id;
@property (nonatomic) NSString<Optional> *uuid;
@property (nonatomic, weak) TelepatChannel <Ignore>*channel;

+ (TelepatJSONKeyMapper *)keyMapper;
- (NSDictionary *) patchAgainst:(TelepatBaseObject *)updatedObject;
- (NSArray *) propertiesList;
- (void) update;
- (void) updateWithBlock:(TelepatResponseBlock)block;

@end
