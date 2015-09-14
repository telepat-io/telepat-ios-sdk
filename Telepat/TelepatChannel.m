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

- (id) init {
    if (self = [super init]) {
        _waitingForCreation = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (id) initWithModelName:(NSString *)modelName context:(TelepatContext *)context objectType:(Class)objectType {
    if (self = [super init]) {
        _modelName = modelName;
        _context = context;
        _objectType = objectType;
    }
    return self;
}

- (void) subscribeWithBlock:(void (^)(TelepatResponse *response))block {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"channel": [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                                              @"context": [NSNumber numberWithLong:self.context.context_id],
                                                                                                                                              @"model": self.modelName}]}];
    if (self.user) [params[@"channel"] setObject:@(self.user.user_id) forKey:@"user"];
    if (self.opFilter) [params[@"channel"] setObject:[self.opFilter toDictionary] forKey:@"filters"];
    
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/object/subscribe"]
                     parameters:params
                        headers:@{}
                  responseBlock:^(KRResponse *response) {
                      TelepatResponse *subscribeResponse = [[TelepatResponse alloc] initWithResponse:response];
                      if (response.status == 200) {
                          TelepatResponse *subscribeResponse = [[TelepatResponse alloc] initWithResponse:response];
                          if ([subscribeResponse.content isKindOfClass:[NSArray class]]) {
                              for (NSDictionary *dict in subscribeResponse.content) {
                                  [self processNotification:[TelepatTransportNotification notificationOfType:TelepatNotificationTypeObjectAdded withValue:dict path:@"/" origin:TelepatNotificationOriginSubscribe]];
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
    [[KRRest sharedClient] create:@{@"model": self.modelName,
                                    @"context": @(self.context.context_id),
                                    @"content": [object toDictionary]} withBlock:^(KRResponse *response) {
    }];
    return object.uuid;
}

- (NSString *) patch:(TelepatBaseObject *)object {
    TelepatBaseObject *oldObject = [self retrieveObjectWithID:object.object_id];
    NSAssert(oldObject, @"Patch error: could not retrieve the original object.");
    
    NSMutableArray *patches = [NSMutableArray array];
    for (NSString *property in [object propertiesList]) {
        if (![[object valueForKey:property] isEqual:[oldObject valueForKey:property]]) {
            NSMutableDictionary *patchDict = [NSMutableDictionary dictionary];
            patchDict[@"path"] = [NSString stringWithFormat:@"%@/%ld/%@", self.modelName, (long)object.object_id, property];
            
            if ([object valueForKey:property] == nil) {
                patchDict[@"op"] = @"delete";
            } else {
                patchDict[@"op"] = @"replace";
                patchDict[@"value"] = [object valueForKey:property];
            }
            
            [patches addObject:patchDict];
        }
    }
    
    NSAssert([patches count], @"Patch error: no patch resulted.");
    
    [object setUuid:[[NSUUID UUID] UUIDString]];
    [[KRRest sharedClient] update:@{@"model": self.modelName,
                                    @"context": @(self.context.context_id),
                                    @"id": @(object.object_id),
                                    @"patch": patches} withBlock:^(KRResponse *response) {
    }];
    
    return object.uuid;
}

- (void) processNotification:(TelepatTransportNotification *)notification {
    switch (notification.type) {
        case TelepatNotificationTypeObjectAdded: {
            id obj = [[_objectType alloc] initWithDictionary:notification.value error:nil];
            if (obj) {
                [[NSNotificationCenter defaultCenter] postNotificationName:TelepatChannelObjectAdded object:self userInfo:@{kNotificationObject: obj,
                                                                                                                            kNotificationOrigin: @(notification.origin)}];
                [self persistObject:obj];
            }
            break;
        }
            
        case TelepatNotificationTypeObjectUpdated: {
            if (notification.value == nil || ([notification.value isKindOfClass:[NSString class]] && [notification.value length] == 0)) return;
            NSArray *pathComponents = [notification.path pathComponents];
            NSString *modelName = pathComponents[0];
            if (![modelName isEqualToString:self.modelName]) return;
            NSInteger objectId = [pathComponents[1] integerValue];
            NSString *propertyName = pathComponents[2];
            if ([[[Telepat client] dbInstance] objectWithID:objectId existsInChannel:[self subscriptionIdentifier]]) {
                id updatedObject = [[[Telepat client] dbInstance] getObjectWithID:objectId fromChannel:[self subscriptionIdentifier]];
                [updatedObject setValue:notification.value forKey:propertyName];
                [[NSNotificationCenter defaultCenter] postNotificationName:TelepatChannelObjectUpdated object:self userInfo:@{kNotificationObject: updatedObject,
                                                                                                                              kNotificationPropertyName: propertyName,
                                                                                                                              kNotificationValue: notification.value,
                                                                                                                              kNotificationOrigin: @(notification.origin)}];
                [self persistObject:updatedObject];
            }
            break;
        }
            
        case TelepatNotificationTypeObjectDeleted: {
            NSArray *pathComponents = [notification.path pathComponents];
            NSString *modelName = pathComponents[0];
            if (![modelName isEqualToString:self.modelName]) return;
            NSInteger objectId = [pathComponents[1] integerValue];
             if ([[[Telepat client] dbInstance] objectWithID:objectId existsInChannel:[self subscriptionIdentifier]]) {
                 TelepatBaseObject *deletedObject = [[[Telepat client] dbInstance] getObjectWithID:objectId fromChannel:[self subscriptionIdentifier]];
                 [[[Telepat client] dbInstance] deleteObjectWithID:deletedObject.object_id fromChannel:[self subscriptionIdentifier]];
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:TelepatChannelObjectDeleted object:self userInfo:@{kNotificationObject: deletedObject,
                                                                                                                               kNotificationOrigin: @(notification.origin)}];
             }
            break;
        }
            
        default:
            break;
    }
}

- (void) persistObject:(id)object {
    [[[Telepat client] dbInstance] persistObject:object inChannel:[self subscriptionIdentifier]];
}

- (id) retrieveObjectWithID:(NSInteger)object_id {
    return [[[Telepat client] dbInstance] getObjectWithID:object_id fromChannel:[self subscriptionIdentifier]];
}

- (NSString *) subscriptionIdentifier {
    if (self.context == nil || self.modelName == nil) return nil;
    NSString *subid = @"blg";
    if (self.context) {
        subid = [NSString stringWithFormat:@"%@:%ld", subid, (long)self.context.context_id];
    }
    if (self.user) {
        subid = [NSString stringWithFormat:@"%@:users:%ld", subid, (long)self.user.user_id];
    }
    if (self.modelName) {
        subid = [NSString stringWithFormat:@"%@:%@", subid, self.modelName];
    }
    if (self.opFilter) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[_opFilter toDictionary] options:0 error:nil];
        subid = [NSString stringWithFormat:@"%@:%@", subid, [jsonData base64EncodedStringWithOptions:0]];
    }
    
    return subid;
}

@end
