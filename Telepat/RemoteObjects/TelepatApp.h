//
//  TelepatApp.h
//  Pods
//
//  Created by Ovidiu on 22/09/15.
//
//

#import "TelepatBaseObject.h"

@interface TelepatApp : TelepatBaseObject

@property (nonatomic, strong) NSArray *admins;
@property (nonatomic, strong) NSDate *created;
@property (nonatomic, strong) NSString *app_id;
@property (nonatomic, strong) NSArray *keys;
@property (nonatomic, strong) NSDate *modified;
@property (nonatomic, strong) NSString *name;

@end
