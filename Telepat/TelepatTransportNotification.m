//
//  TelepatTransportNotification.m
//  Kraken
//
//  Created by Ovidiu on 26/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatTransportNotification.h"

@implementation TelepatTransportNotification

+ (instancetype) notificationFromDictionary:(NSDictionary *)dict withOrigin:(TelepatNotificationOrigin)origin {
    TelepatTransportNotification *transportNotification = [[TelepatTransportNotification alloc] init];
    transportNotification.origin = origin;
    
    if ([dict[@"op"] isEqualToString:@"create"]) {
        transportNotification.type = TelepatNotificationTypeObjectAdded;
    } else if ([dict[@"op"] isEqualToString:@"update"]) {
        transportNotification.type = TelepatNotificationTypeObjectUpdated;
    } else if ([dict[@"op"] isEqualToString:@"delete"]) {
        transportNotification.type = TelepatNotificationTypeObjectDeleted;
    }
    
    if (dict[@"value"]) {
        transportNotification.value = dict[@"value"];
    } else if (dict[@"object"]) {
        transportNotification.value = dict[@"object"];
    } else if (dict[@"patch"] && dict[@"patch"][@"value"]) {
        transportNotification.value = dict[@"patch"][@"value"];
    }
    
    if (dict[@"path"]) {
        transportNotification.path = dict[@"path"];
    } else if (dict[@"patch"] && dict[@"patch"][@"path"]) {
        transportNotification.path = dict[@"patch"][@"path"];
    }
    
    return transportNotification;
}

@end
