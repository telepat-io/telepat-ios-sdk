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
#define kUDID @"udid"
#define kJWT @"authentication-token"
#define kJWT_TIMESTAMP @"authentication-token-timestamp"

extern NSString *const TelepatRemoteNotificationReceived;

extern NSString *const TelepatChannelObjectAdded;
extern NSString *const TelepatChannelObjectUpdated;
extern NSString *const TelepatChannelObjectDeleted;

#endif
