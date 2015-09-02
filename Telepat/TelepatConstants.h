//
//  TelepatConstants.h
//  Kraken
//
//  Created by Ovidiu on 16/07/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef Kraken_TelepatConstants_h
#define Kraken_TelepatConstants_h

#define kNotificationObject @"object"
#define kNotificationPropertyName @"propertyName"
#define kNotificationValue @"value"
#define kNotificationOrigin @"origin"
#define kUDID @"udid"
#define kJWT @"authentication-token"
#define kJWT_TIMESTAMP @"authentication-token-timestamp"

///--------------------
/// @name Notifications
///--------------------

/**
 *  This should be posted by the developer from `-application:didReceiveRemoteNotification:` in AppDelegate to notify Telepat that a new notification was received
 */
extern NSString *const TelepatRemoteNotificationReceived;

/**
 *  Posted when a new object was added
 */
extern NSString *const TelepatChannelObjectAdded;

/**
 *  Posted when an existing object was updated
 */
extern NSString *const TelepatChannelObjectUpdated;

/**
 *  Posted when an existing object was deleted
 */
extern NSString *const TelepatChannelObjectDeleted;

#endif
