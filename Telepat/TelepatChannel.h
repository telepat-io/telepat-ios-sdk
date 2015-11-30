//
//  TelepatChannel.h
//  Kraken
//
//  Created by Ovidiu on 26/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TelepatContext.h"
#import "TelepatCountResult.h"
#import "TelepatTransportNotification.h"
#import "TelepatOperatorFilter.h"
#import "TelepatUser.h"

#define kNotificationObject @"object"
#define kNotificationOriginalContent @"originalContent"
#define kNotificationPropertyName @"propertyName"
#define kNotificationValue @"value"

@class TelepatResponse;

/**
 *  Use `TelepatChannel` to create, update and remove Telepat objects. You can create new `TelepatChannel`s using the subscribe methods of the Telepat instance.
 */
@interface TelepatChannel : NSObject

/**
 *  The reference to the `TelepatContext` instance used to create this channel
 */
@property (nonatomic, strong) TelepatContext *context;

/**
 *  A reference to the current logged in `TelepatUser`, if available
 */
@property (nonatomic, strong) TelepatUser *user;

/**
 *  The model name of the desired objects
 */
@property (nonatomic, strong) NSString *modelName;

/**
 *  The desired class of the objects that will be emitted in this channel (should inherit from the `TelepatBaseObject` class)
 */
@property (nonatomic, strong) Class objectType;

/**
 *  The `TelepatOperatorFilter` used to filter objects in this channel
 */
@property (nonatomic, strong) TelepatOperatorFilter *opFilter;

/**
 *  The model name of the parent object, if any
 */
@property (nonatomic, strong) NSString *parentModelName;

/**
 *  The id of the parent object, if any
 */
@property (nonatomic, strong) NSString *parentId;

/**
 *  Instantiate a new instance of `TelepatChannel`
 *
 *  @param modelName The model name of the desired objects
 *  @param context The context where the desired objects live in
 *  @param objectType The desired class of the objects that will be emitted in this channel
 */
- (id) initWithModelName:(NSString *)modelName context:(TelepatContext *)context objectType:(Class)objectType;

/**
 *  Instantiate a new instance of `TelepatChannel` with filters
 *
 *  @param modelName The model name of the desired objects
 *  @param context The context where the desired objects live in
 *  @param filter Filters to use when creating the `TelepatChannel` object
 *  @param objectType The desired class of the objects that will be emitted in this channel
 */
- (id) initWithModelName:(NSString *)modelName context:(TelepatContext *)context filter:(TelepatOperatorFilter*)filter objectType:(Class)objectType;

/**
 *  Subscribe to this channel
 *
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed. You can retrieve a list of the current objects in this channel by calling `getObjectOfType on the block's `TelepatResponse` argument
 */
- (void) subscribeWithBlock:(void (^)(TelepatResponse *response))block;

/**
 *  Unsubscribe from this channel
 *
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) unsubscribeWithBlock:(void (^)(TelepatResponse *response))block;

/**
 *  Process a `TelepatTransportNotification` received from the update channel (e.g. Websockets)
 *
 *  @param notification Notification to process
 */
- (void) processNotification:(TelepatTransportNotification *)notification;

/**
 *  Add an object in this channel
 *
 *  @param object An instance of a `TelepatBaseObject` subclass to be added in this channel
 *  @return The UUID of the created object
 */
- (NSString *) add:(TelepatBaseObject *)object;

/**
 *  Add an object in this channel
 *
 *  @param object An instance of a `TelepatBaseObject` subclass to be added in this channel
 *  @param block A block which will be called when the add request was completed
 *  @return The UUID of the created object
 */
- (NSString *) add:(TelepatBaseObject *)object withBlock:(void (^)(TelepatResponse *response))block;

/**
 *  Update an object in this channel
 *
 *  @param object The updated object
 *  @return The UUID of the updated object
 */
- (NSString *) patch:(TelepatBaseObject *)object;

/**
 *  Update an object in this channel
 *
 *  @param object The updated object
 *  @param block A block which will be called when the patch request was completed
 *  @return The UUID of the updated object
 */
- (NSString *) patch:(TelepatBaseObject *)object withBlock:(void (^)(TelepatResponse *response))block;

/**
 *  Gets the object count of a certain filter/subscription
 *
 *  @param block A block which will be called when the add request was completed
 */
- (void) countWithBlock:(void (^)(TelepatCountResult *result))block;

/**
 *  Get the current subscription identifier
 *
 *  @return Subscription's identifier
 */
- (NSString *) subscriptionIdentifier;

@end
