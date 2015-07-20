//
//  TelepatTransportNotification.h
//  Kraken
//
//  Created by Ovidiu on 26/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ENUM(NSInteger, TelepatNotificationType) {
    TelepatNotificationTypeObjectAdded,
    TelepatNotificationTypeObjectUpdated,
    TelepatNotificationTypeObjectDeleted
};

@interface TelepatTransportNotification : NSObject

@property (nonatomic) enum TelepatNotificationType type;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *subscription;
@property (nonatomic, strong) NSString *guid;

+ (instancetype) notificationOfType:(enum TelepatNotificationType)type withValue:(id)value andPath:(NSString *)path;

@end
