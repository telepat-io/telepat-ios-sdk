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
#import "TelepatAggregationResult.h"
#import "TelepatTransportNotification.h"
#import "TelepatOperatorFilter.h"
#import "TelepatUser.h"

#define kNotificationObject @"object"
#define kNotificationOriginalContent @"originalContent"
#define kNotificationPropertyName @"propertyName"
#define kNotificationValue @"value"

typedef NS_ENUM(NSInteger, TelepatChannelSortMode) {
    TelepatChannelSortModeNone,
    TelepatChannelSortModeAscending,
    TelepatChannelSortModeDescending
};

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
 *  The id of the channel item
 */
@property (nonatomic, strong) NSString *objectId;

/**
 *  Instantiate a new instance of `TelepatChannel`
 *
 *  @param modelName The model name of the desired objects
 *  @param objectType The desired class of the objects that will be emitted in this channel
 */
- (id) initWithModelName:(NSString *)modelName objectType:(Class)objectType;

/**
 *  Instantiate a new instance of `TelepatChannel` with a context
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
 *  Instantiate a new instance of `TelepatChannel` with a parent model and id
 *
 *  @param parentModel The parent's model name
 *  @param parentId    The parent's id
 *  @param objectType  The desired class of the objects that will be emitted in this channel
 *
 *  @return A new instance of `TelepatChannel`
 */
- (id) initWithModelName:(NSString *)modelName parentModel:(NSString *)parentModel parentId:(NSString *)parentId objectType:(Class)objectType;

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
 *  Get all objects from this channel. This doesn't subscribe you to the notifications from Telepat
 *
 *  @param block A block which will be called when the request is completed.
 */
- (void) getAllObjects:(void (^)(NSArray *objects, TelepatResponse *response))block;

/**
 *  Get objects from this channel in the specified range. This doesn't subscribe you to the notifications from Telepat
 *
 *  @param range A `NSRange` specifying the offset and the limit of objects count to be returned
 *  @param block A block which will be called when the request is completed.
 */
- (void) getObjectsInRange:(NSRange)range withBlock:(void (^)(NSArray *objects, TelepatResponse *response))block;

/**
 *  Get cached objects from this channel.
 *
 *  @return A list of objects contained by this channel and cached in the internal database
 */
- (NSArray *) getLocalObjects;

/**
 *  Configure the channel to sort after a property value
 *
 *  @param sortedProperty A `NSString` naming the property which will be sorted
 *  @param sortOrder The sorting order, ascedent or descendent
 */
- (void) setSortedProperty:(NSString *)sortedProperty order:(TelepatChannelSortMode)order;

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
 *  Delete an object in this channel
 *
 *  @param object Object to delete
 */
- (void) deleteObject:(TelepatBaseObject *)object;

/**
 *  Delete an object in this channel
 *
 *  @param object Object to delete
 *  @param block  A block which will be called when the delete request was completed
 */
- (void) deleteObject:(TelepatBaseObject *)object withBlock:(void (^)(TelepatResponse *response))block;

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
 *  @param block A block which will be called when the count request was completed
 */
- (void) countWithBlock:(void (^)(TelepatCountResult *result))block;

/**
 *  Get the arithmetic average of a field
 *
 *  @param field The field name
 *  @param block A block which will be called when the aggregation request was completed
 */
- (void) average:(NSString *)field withBlock:(void (^)(TelepatAggregationResult *result))block;

/**
 *  Get the current subscription identifier
 *
 *  @return Subscription's identifier
 */
- (NSString *) subscriptionIdentifier;

@end
