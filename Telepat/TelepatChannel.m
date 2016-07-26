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
    NSMutableDictionary *_sortingDict;
}

- (id) init {
    if (self = [super init]) {
        _waitingForCreation = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (id) initWithModelName:(NSString *)modelName objectType:(Class)objectType {
    if (self = [super init]) {
        _modelName = modelName;
        _objectType = objectType;
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

- (id) initWithModelName:(NSString *)modelName context:(TelepatContext *)context filter:(TelepatOperatorFilter*)filter objectType:(Class)objectType {
    if (self = [super init]) {
        _modelName = modelName;
        _context = context;
        _opFilter = filter;
        _objectType = objectType;
    }
    
    return self;
}

- (id) initWithModelName:(NSString *)modelName parentModel:(NSString *)parentModel parentId:(NSString *)parentId objectType:(Class)objectType {
    if (self = [super init]) {
        _modelName = modelName;
        _parentModelName = parentModel;
        _parentId = parentId;
        _objectType = objectType;
    }
    
    return self;
}

- (void) subscribeWithBlock:(void (^)(TelepatResponse *response))block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/object/subscribe"]
                     parameters:[self paramsForSubscription]
                        headers:@{}
                  responseBlock:^(KRResponse *response) {
                      TelepatResponse *subscribeResponse = [[TelepatResponse alloc] initWithResponse:response];
                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                          if (response.status == 200) {
                              if ([subscribeResponse.content isKindOfClass:[NSArray class]]) {
                                  for (NSDictionary *dict in subscribeResponse.content) {
                                      NSError *err;
                                      id obj = [[_objectType alloc] initWithDictionary:dict error:&err];
                                      if (err) continue;
                                      [self persistObject:obj];
                                  }
                              } else {
                                  id obj = [[_objectType alloc] initWithDictionary:subscribeResponse.content error:nil];
                                  [self persistObject:obj];
                              }
                              
                              [[Telepat client] registerSubscription:self];
                          }
                          
                          dispatch_async(dispatch_get_main_queue(), ^{
                              block(subscribeResponse);
                          });
                      });
                  }];
}

- (void) unsubscribeWithBlock:(void (^)(TelepatResponse *response))block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/object/unsubscribe"]
                     parameters:[self paramsForSubscription]
                        headers:@{}
                  responseBlock:^(KRResponse *response) {
                      TelepatResponse *unsubscribeResponse = [[TelepatResponse alloc] initWithResponse:response];
                      if (response.status == 200) {
                          [[Telepat client] unregisterSubscription:self];
                      }
                      block(unsubscribeResponse);
                  }];
}

- (void) getAllObjects:(void (^)(NSArray *objects, TelepatResponse *response))block {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:[self paramsForSubscription]];
    mutableParams[@"no_subscribe"] = @YES;
    
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/object/subscribe"]
                     parameters:mutableParams
                        headers:@{}
                  responseBlock:^(KRResponse *response) {
                      TelepatResponse *subscribeResponse = [[TelepatResponse alloc] initWithResponse:response];
                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                          if (response.status == 200) {
                              NSMutableArray *returnedObjects = [NSMutableArray array];
                              
                              if ([subscribeResponse.content isKindOfClass:[NSArray class]]) {
                                  for (NSDictionary *dict in subscribeResponse.content) {
                                      NSError *err;
                                      id obj = [[_objectType alloc] initWithDictionary:dict error:&err];
                                      if (err) continue;
                                      ((TelepatBaseObject*) obj).channel = self;
                                      [self persistObject:obj];
                                      [returnedObjects addObject:obj];
                                  }
                                  
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      block([NSArray arrayWithArray:returnedObjects], subscribeResponse);
                                  });
                              } else {
                                  NSError *err;
                                  id obj = [[_objectType alloc] initWithDictionary:subscribeResponse.content error:&err];
                                  if (err) {
                                      block(nil, subscribeResponse);
                                      return;
                                  }
                                  ((TelepatBaseObject*) obj).channel = self;
                                  [self persistObject:obj];
                                  
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      block(@[obj], subscribeResponse);
                                  });
                              }
                          } else {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  block(nil, subscribeResponse);
                              });
                          }
                      });
                  }];
}

- (void) getObjectsInRange:(NSRange)range withBlock:(void (^)(NSArray *objects, TelepatResponse *response))block {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:[self paramsForSubscription]];
    mutableParams[@"no_subscribe"] = @YES;
    mutableParams[@"offset"] = @(range.location);
    mutableParams[@"limit"] = @(range.length);
    
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/object/subscribe"]
                     parameters:mutableParams
                        headers:@{}
                  responseBlock:^(KRResponse *response) {
                      TelepatResponse *subscribeResponse = [[TelepatResponse alloc] initWithResponse:response];
                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                          if (response.status == 200) {
                              NSMutableArray *returnedObjects = [NSMutableArray array];
                              
                              if ([subscribeResponse.content isKindOfClass:[NSArray class]]) {
                                  for (NSDictionary *dict in subscribeResponse.content) {
                                      id obj = [[_objectType alloc] initWithDictionary:dict error:nil];
                                      [self persistObject:obj];
                                      [returnedObjects addObject:obj];
                                  }
                                  
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      block([NSArray arrayWithArray:returnedObjects], subscribeResponse);
                                  });
                              } else {
                                  id obj = [[_objectType alloc] initWithDictionary:subscribeResponse.content error:nil];
                                  [self persistObject:obj];
                                  
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      block(@[obj], subscribeResponse);
                                  });
                              }
                          } else {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  block(nil, subscribeResponse);
                              });
                          }
                      });
                  }];
}

- (NSArray *) getLocalObjects {
    return [[[Telepat client] dbInstance] getObjectsFromChannel:[self subscriptionIdentifier]];
}

- (void) setSortedProperty:(NSString *)sortedProperty order:(TelepatChannelSortMode)order {
    _sortingDict = [NSMutableDictionary dictionary];
    NSDictionary *orderDict;
    if (order == TelepatChannelSortModeAscending) {
        orderDict = @{@"order": @"asc"};
    } else if (order == TelepatChannelSortModeDescending) {
        orderDict = @{@"order": @"desc"};
    } else {
        orderDict = nil;
    }
    
    if (orderDict) {
        _sortingDict[sortedProperty] = orderDict;
    } else {
        _sortingDict = nil;
    }
}

- (NSDictionary *) paramsForSubscription {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"channel": [NSMutableDictionary dictionaryWithDictionary:@{@"model": self.modelName}]}];
    if (self.context) [params[@"channel"] setObject:self.context.context_id forKey:@"context"];
    if (self.user) [params[@"channel"] setObject:self.user.user_id forKey:@"user"];
    if (self.parentId && self.parentModelName) {
        [params[@"channel"] setObject:@{@"id": self.parentId, @"model": self.parentModelName} forKey:@"parent"];
    }
    if (self.opFilter) [params setObject:[self.opFilter toDictionary] forKey:@"filters"];
    if (_sortingDict) [params setObject:_sortingDict forKey:@"sort"];
    
    return [NSDictionary dictionaryWithDictionary:params];
}

- (NSString *) add:(TelepatBaseObject *)object {
    return [self add:object withBlock:nil];
}

- (NSString *) add:(TelepatBaseObject *)object withBlock:(void (^)(TelepatResponse *response))block {
    [object setChannel:self];
    [object setUuid:[[NSUUID UUID] UUIDString]];
    [_waitingForCreation setObject:object forKey:object.uuid];
    [[KRRest sharedClient] create:@{@"model": self.modelName,
                                    @"context": self.context.context_id,
                                    @"content": [object toDictionary]} withBlock:^(KRResponse *response) {
                                        if (block) {
                                            TelepatResponse *addResponse = [[TelepatResponse alloc] initWithResponse:response];
                                            if (addResponse.isError) [_waitingForCreation removeObjectForKey:object.uuid];
                                            block(addResponse);
                                        }
                                    }];
    return object.uuid;
}

- (NSString *) patch:(TelepatBaseObject *)object {
    return [self patch:object withBlock:nil];
}

- (NSString *) patch:(TelepatBaseObject *)object withBlock:(void (^)(TelepatResponse *response))block {
    TelepatBaseObject *oldObject = [self retrieveObjectWithID:object.object_id];
    NSAssert(oldObject, @"Patch error: could not retrieve the original object.");
    
    NSMutableArray *patches = [NSMutableArray array];
    for (NSString *property in [object propertiesList]) {
        if ([property isEqualToString:@"uuid"]) continue;
        if (![[object valueForKey:property] isEqual:[oldObject valueForKey:property]]) {
            NSString *convertedProperty = [[[object class] keyMapper] convertValue:property isImportingToModel:YES];
            NSMutableDictionary *patchDict = [NSMutableDictionary dictionary];
            patchDict[@"path"] = [NSString stringWithFormat:@"%@/%@/%@", self.modelName, object.object_id, convertedProperty];
            
//            if ([object valueForKey:property] == nil) {
//                patchDict[@"op"] = @"delete";
//            } else {
//                patchDict[@"op"] = @"replace";
//                patchDict[@"value"] = [object valueForKey:property];
//            }
            
            id newValue = [object toDictionary][convertedProperty];
            
            if ([oldObject toDictionary][convertedProperty] == nil && newValue == nil) continue;
            patchDict[@"op"] = @"replace";
            patchDict[@"value"] = newValue ? newValue : @"";
            
            [patches addObject:patchDict];
        }
    }
    
    NSAssert([patches count], @"Patch error: no patch resulted.");
    
    [object setUuid:[[NSUUID UUID] UUIDString]];
    [[KRRest sharedClient] update:@{@"model": self.modelName,
                                    @"context": self.context.context_id,
                                    @"id": object.object_id,
                                    @"patches": patches} withBlock:^(KRResponse *response) {
                                        if (block) {
                                            TelepatResponse *patchResponse = [[TelepatResponse alloc] initWithResponse:response];
                                            block(patchResponse);
                                        }
                                    }];
    
    return object.uuid;
}

- (void) countWithBlock:(void (^)(TelepatCountResult *result))block {
    [[KRRest sharedClient] count:[self paramsForSubscription] withBlock:^(KRResponse *response) {
        TelepatResponse *countResponse = [[TelepatResponse alloc] initWithResponse:response];
        block([countResponse getObjectOfType:[TelepatCountResult class]]);
    }];
}

- (void) average:(NSString *)field withBlock:(void (^)(TelepatAggregationResult *result))block {
    NSMutableDictionary *requestDict = [NSMutableDictionary dictionaryWithDictionary:[self paramsForSubscription]];
    NSDictionary *aggregationDict = @{@"avg": @{@"field": field}};
    [requestDict setObject:aggregationDict forKey:@"aggregation"];
    [[KRRest sharedClient] count:requestDict withBlock:^(KRResponse *response) {
        TelepatResponse *averageResponse = [[TelepatResponse alloc] initWithResponse:response];
        block([averageResponse getObjectOfType:[TelepatAggregationResult class]]);
    }];
}

- (void) processNotification:(TelepatTransportNotification *)notification {
    switch (notification.type) {
        case TelepatNotificationTypeObjectAdded: {
            NSError *err;
            TelepatBaseObject *obj = [[_objectType alloc] initWithDictionary:notification.value error:&err];
            obj.channel = self;
            if (obj) {
                if ([[[Telepat client] dbInstance] objectWithID:obj.object_id existsInChannel:[self subscriptionIdentifier]]) return;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self persistObject:obj];
                    [[NSNotificationCenter defaultCenter] postNotificationName:TelepatChannelObjectAdded object:self userInfo:@{kNotificationObject: obj,
                                                                                                                                kNotificationOriginalContent: notification.value,
                                                                                                                                kNotificationOrigin: @(notification.origin)}];
                });
            }
            break;
        }
            
        case TelepatNotificationTypeObjectUpdated: {
            if (notification.value == nil || ([notification.value isKindOfClass:[NSString class]] && [notification.value length] == 0)) return;
            NSArray *pathComponents = [notification.path pathComponents];
            NSString *modelName = pathComponents[0];
            if (![modelName isEqualToString:self.modelName]) return;
            NSString *objectId = pathComponents[1];
            NSString *propertyName = pathComponents[2];
            if ([[[Telepat client] dbInstance] objectWithID:objectId existsInChannel:[self subscriptionIdentifier]]) {
                id updatedObject = [[[Telepat client] dbInstance] getObjectWithID:objectId fromChannel:[self subscriptionIdentifier]];
                NSString *transformedPropertyName = [[[updatedObject class] keyMapper] convertValue:propertyName isImportingToModel:NO];
                if ([updatedObject respondsToSelector:NSSelectorFromString(transformedPropertyName)] && [[updatedObject valueForKey:transformedPropertyName] isEqual:notification.value]) return;
                [updatedObject setValue:notification.value forProperty:transformedPropertyName];
                ((TelepatBaseObject*)updatedObject).channel = self;
                [self persistObject:updatedObject];
                [[NSNotificationCenter defaultCenter] postNotificationName:TelepatChannelObjectUpdated object:self userInfo:@{kNotificationObject: updatedObject,
                                                                                                                              kNotificationOriginalContent: notification.value,
                                                                                                                              kNotificationPropertyName: transformedPropertyName,
                                                                                                                              kNotificationValue: notification.value,
                                                                                                                              kNotificationOrigin: @(notification.origin)}];
            }
            break;
        }
            
        case TelepatNotificationTypeObjectDeleted: {
            NSArray *pathComponents = [notification.path pathComponents];
            NSString *modelName = pathComponents[0];
            if (![modelName isEqualToString:self.modelName]) return;
            NSString *objectId = pathComponents[1];
             if ([[[Telepat client] dbInstance] objectWithID:objectId existsInChannel:[self subscriptionIdentifier]]) {
                 TelepatBaseObject *deletedObject = [[[Telepat client] dbInstance] getObjectWithID:objectId fromChannel:[self subscriptionIdentifier]];
                 [[[Telepat client] dbInstance] deleteObjectWithID:deletedObject.object_id fromChannel:[self subscriptionIdentifier]];
                 ((TelepatBaseObject*)deletedObject).channel = self;
                 
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

- (id) retrieveObjectWithID:(NSString *)object_id {
    return [[[Telepat client] dbInstance] getObjectWithID:object_id fromChannel:[self subscriptionIdentifier]];
}

- (NSInteger) channelMask {
    NSInteger mask = 0;
    if (self.context)
        mask += 1;
    if (self.user)
        mask += 2;
    if (self.modelName)
        mask += 4;
    if (self.parentId && self.parentModelName)
        mask += 8;
    if (self.objectId)
        mask += 16;
    return mask;
}

- (NSString *) subscriptionIdentifier {
    NSString *subid = [NSString stringWithFormat:@"blg"];
    switch ([self channelMask]) {
        case 4:
            subid = [NSString stringWithFormat:@"%@:%@:%@", subid, [[Telepat client] appId], self.modelName];
            break;
        case 5:
            subid = [NSString stringWithFormat:@"%@:%@:context:%@:%@", subid, [[Telepat client] appId], self.context.context_id, self.modelName];
            break;
        case 7:
            subid = [NSString stringWithFormat:@"%@:%@:context:%@:users:%@:%@", subid, [[Telepat client] appId], self.context.context_id, self.user.user_id, self.modelName];
            break;
        case 12:
            subid = [NSString stringWithFormat:@"%@:%@:%@:%@:%@", subid, [[Telepat client] appId], self.parentModelName, self.parentId, self.modelName];
            break;
        case 14:
            subid = [NSString stringWithFormat:@"%@:%@:users:%@:%@:%@:%@", subid, [[Telepat client] appId], self.user.user_id, self.parentModelName, self.parentId, self.modelName];
            break;
        case 20:
            subid = [NSString stringWithFormat:@"%@:%@:%@:%@", subid, [[Telepat client] appId], self.modelName, self.objectId];
            break;
    }
    
    if (self.opFilter) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[_opFilter toDictionary] options:0 error:nil];
        subid = [NSString stringWithFormat:@"%@:filter:%@", subid, [jsonData base64EncodedStringWithOptions:0]];
    }
    
    return subid;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<TelepatChannel: %p>%@</TelepatChannel>", self, [self subscriptionIdentifier]];
}

@end
