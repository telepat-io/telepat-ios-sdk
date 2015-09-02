//
//  TelepatTransportNotification.h
//  Kraken
//
//  Created by Ovidiu on 26/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Marks the type of the received notification
 */
typedef NS_ENUM(NSInteger, TelepatNotificationType) {
    /**
     *  Marks that an object was added
     */
    TelepatNotificationTypeObjectAdded,
    /**
     *  Marks that an object was updated
     */
    TelepatNotificationTypeObjectUpdated,
    /**
     *  Marks that an object was deleted
     */
    TelepatNotificationTypeObjectDeleted
};

/**
 *  Defines the origin of the notification
 */
typedef NS_ENUM(NSInteger, TelepatNotificationOrigin) {
    /**
     *  Notification came from Apple's Push Notification system
     */
    TelepatNotificationOriginPN,
    /**
     *  Notification came via websockets
     */
    TelepatNotificationOriginWebsockets,
    /**
     *  Notification came from a subscribe response (see `TelepatChannel` class)
     */
    TelepatNotificationOriginSubscribe
};

/**
 *  A class which store data received from websockets or Apple Push Notifications
 */
@interface TelepatTransportNotification : NSObject

/**
 *  The notification type
 */
@property (nonatomic) enum TelepatNotificationType type;

/**
 *  The origin of notification
 */
@property (nonatomic) enum TelepatNotificationOrigin origin;

/**
 *  The new or updated value
 */
@property (nonatomic, strong) id value;

/**
 *  The JSON path of the modified property
 */
@property (nonatomic, strong) NSString *path;

/**
 *  The subscription which this notification affects
 */
@property (nonatomic, strong) NSString *subscription;

/**
 *  An unique ID of this notification
 */
@property (nonatomic, strong) NSString *guid;


/**
 *  Create a new `TelepatTransportNotification`
 *
 *  @param type The notification type
 *  @param value The new or updated value
 *  @param path The JSON path of the modified property
 *  @param origin The origin of the notification
 */
+ (instancetype) notificationOfType:(enum TelepatNotificationType)type withValue:(id)value path:(NSString *)path origin:(TelepatNotificationOrigin)origin;

@end
