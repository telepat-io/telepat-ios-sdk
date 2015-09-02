//
//  TelepatTransportNotification.h
//  Kraken
//
//  Created by Ovidiu on 26/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TelepatNotificationType) {
    TelepatNotificationTypeObjectAdded,
    TelepatNotificationTypeObjectUpdated,
    TelepatNotificationTypeObjectDeleted
};

typedef NS_ENUM(NSInteger, TelepatNotificationOrigin) {
    TelepatNotificationOriginPN,          // Notification comes from a Push Notification
    TelepatNotificationOriginWebsockets,  // Notification comes from websockets
    TelepatNotificationOriginSubscribe    // Notification comes from a subscribe response (see TelepatChannel)
};

@interface TelepatTransportNotification : NSObject

@property (nonatomic) enum TelepatNotificationType type;
@property (nonatomic) enum TelepatNotificationOrigin origin;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *subscription;
@property (nonatomic, strong) NSString *guid;

+ (instancetype) notificationOfType:(enum TelepatNotificationType)type withValue:(id)value path:(NSString *)path origin:(TelepatNotificationOrigin)origin;

@end
