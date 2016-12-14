//
//  KRBaseObject.h
//  Kraken
//
//  Created by Ovidiu on 24/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import <JSONModel/JSONModelClassProperty.h>
#import "TelepatJSONKeyMapper.h"

#define kTelepatNoChannelError @"NoChannelError"
#define kTelepatDeserializeError @"DeserializeError"

@class TelepatChannel, TelepatResponse;
typedef void (^TelepatResponseBlock)(TelepatResponse  *_Nonnull response);

@interface TelepatBaseObject : JSONModel

@property (nonatomic) NSString *_Nonnull object_id;
@property (nonatomic) NSString<Optional> *_Nullable uuid;
@property (nonatomic, weak) TelepatChannel <Ignore>*_Nullable channel;
@property (nonatomic, strong) NSDate<Optional> *_Nullable created;
@property (nonatomic, strong) NSDate<Optional> *_Nullable modified;

+ (TelepatJSONKeyMapper *_Nullable)keyMapper;
- (NSDictionary *_Nullable) patchAgainst:(TelepatBaseObject *_Nonnull)updatedObject;
- (NSArray *_Nonnull) propertiesList;
- (void) setValue:(id <NSObject>_Nonnull)value forProperty:(NSString *_Nonnull)propertyName;
- (void) update;
- (void) updateWithBlock:(TelepatResponseBlock _Nonnull)block;

@end
