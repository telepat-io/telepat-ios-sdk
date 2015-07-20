//
//  TelepatChannel.m
//  Kraken
//
//  Created by Ovidiu on 26/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatChannel.h"
#import "Telepat.h"

@implementation TelepatChannel {
    NSMutableDictionary *_waitingForCreation;
}

- (id) initWithModelName:(NSString *)modelName context:(TelepatContext *)context objectType:(Class)objectType {
    if (self = [super init]) {
        _modelName = modelName;
        _context = context;
        _objectType = objectType;
        
        _waitingForCreation = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) subscribeWithBlock:(void (^)(TelepatResponse *response))block {
    NSDictionary *params = @{@"channel": @{
                                     @"context": [NSNumber numberWithLong:self.context.context_id],
                                     @"model": self.modelName}};
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/object/subscribe"]
                     parameters:params
                        headers:@{}
                  responseBlock:^(KRResponse *response) {
                      TelepatResponse *subscribeResponse = [[TelepatResponse alloc] initWithResponse:response];
                      if (response.status == 200) {
                          TelepatResponse *subscribeResponse = [[TelepatResponse alloc] initWithResponse:response];
                          if ([subscribeResponse.content isKindOfClass:[NSArray class]]) {
                              for (NSDictionary *dict in subscribeResponse.content) {
                                  [self processNotification:[TelepatTransportNotification notificationOfType:TelepatNotificationTypeObjectAdded withValue:dict andPath:@"/"]];
                              }
                          }
                          
                          [[Telepat client] registerSubscription:self];
                      }
                      block(subscribeResponse);
                  }];
}

- (void) unsubscribeWithBlock:(void (^)(TelepatResponse *response))block {
    NSDictionary *params = @{@"channel": @{
                                     @"context": [NSNumber numberWithLong:self.context.context_id],
                                     @"model": self.modelName}};
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/object/unsubscribe"]
                     parameters:params
                        headers:@{}
                  responseBlock:^(KRResponse *response) {
                      TelepatResponse *unsubscribeResponse = [[TelepatResponse alloc] initWithResponse:response];
                      if (response.status == 200) {
                          [[Telepat client] unregisterSubscription:self];
                      }
                      block(unsubscribeResponse);
                  }];
}

- (NSString *) add:(TelepatBaseObject *)object {
    [object setUuid:[[NSUUID UUID] UUIDString]];
    [_waitingForCreation setObject:object forKey:[[NSUUID UUID] UUIDString]];
    [[KRRest sharedClient] create:[object toDictionary] withBlock:^(KRResponse *response) {
        NSLog(@"re: %@", response);
    }];
    return object.uuid;
}

- (void) processNotification:(TelepatTransportNotification *)notification {
    switch (notification.type) {
        case TelepatNotificationTypeObjectAdded: {
            id obj = [[_objectType alloc] initWithDictionary:notification.value error:nil];
            if (obj) {
                [[NSNotificationCenter defaultCenter] postNotificationName:TelepatChannelObjectAdded object:self userInfo:@{kNotificationObject: obj}];
                [self persistObject:obj];
            }
            break;
        }
            
        case TelepatNotificationTypeObjectUpdated: {
            if (notification.value == nil || [notification.value length] == 0) return;
            NSArray *pathComponents = [notification.path pathComponents];
            NSString *modelName = pathComponents[0];
            if (![modelName isEqualToString:self.modelName]) return;
            NSInteger objectId = [pathComponents[1] integerValue];
            NSString *propertyName = pathComponents[2];
            if ([[[Telepat client] getDBInstance] objectWithID:objectId existsInChannel:[self subscriptionIdentifier]]) {
                id updatedObject = [[[Telepat client] getDBInstance] getObjectWithID:objectId fromChannel:[self subscriptionIdentifier]];
                [updatedObject setValue:notification.value forKey:propertyName];
                [[NSNotificationCenter defaultCenter] postNotificationName:TelepatChannelObjectUpdated object:self userInfo:@{kNotificationObject: updatedObject,
                                                                                                                              kNotificationPropertyName: propertyName,
                                                                                                                              kNotificationValue: notification.value}];
                [self persistObject:updatedObject];
            }
            break;
        }
            
        case TelepatNotificationTypeObjectDeleted: {
            NSArray *pathComponents = [notification.path pathComponents];
            NSString *modelName = pathComponents[0];
            if (![modelName isEqualToString:self.modelName]) return;
            NSInteger objectId = [pathComponents[1] integerValue];
             if ([[[Telepat client] getDBInstance] objectWithID:objectId existsInChannel:[self subscriptionIdentifier]]) {
                 TelepatBaseObject *deletedObject = [[[Telepat client] getDBInstance] getObjectWithID:objectId fromChannel:[self subscriptionIdentifier]];
                 [[[Telepat client] getDBInstance] deleteObjectWithID:deletedObject.object_id fromChannel:[self subscriptionIdentifier]];
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:TelepatChannelObjectDeleted object:self userInfo:@{kNotificationObject: deletedObject}];
             }
            break;
        }
            
        default:
            break;
    }
}

- (NSString *) subscriptionIdentifier {
    if (self.context == nil || self.modelName == nil) return nil;
    return [NSString stringWithFormat:@"blg:%d:%@", self.context.context_id, self.modelName];
}

- (void) persistObject:(id)object {
    [[[Telepat client] getDBInstance] persistObject:object inChannel:[self subscriptionIdentifier]];
}

@end
