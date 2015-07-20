//
//  TelepatChannel.h
//  Kraken
//
//  Created by Ovidiu on 26/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TelepatContext.h"
#import "TelepatTransportNotification.h"

#define kNotificationObject @"object"
#define kNotificationPropertyName @"propertyName"
#define kNotificationValue @"value"

@class TelepatResponse;

@interface TelepatChannel : NSObject

@property (nonatomic, strong) TelepatContext *context;
@property (nonatomic, strong) NSString *modelName;
@property (nonatomic, strong) Class objectType;

- (id) initWithModelName:(NSString *)modelName context:(TelepatContext *)context objectType:(Class)objectType;
- (void) subscribeWithBlock:(void (^)(TelepatResponse *response))block;
- (void) unsubscribeWithBlock:(void (^)(TelepatResponse *response))block;
- (void) processNotification:(TelepatTransportNotification *)notification;
- (NSString *) add:(TelepatBaseObject *)object;

- (NSString *) subscriptionIdentifier;

@end
