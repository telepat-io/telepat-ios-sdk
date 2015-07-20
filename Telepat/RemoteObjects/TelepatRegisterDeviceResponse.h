//
//  TelepatRegisterDeviceResponse.h
//  Kraken
//
//  Created by Ovidiu on 25/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatBaseObject.h"

@interface TelepatRegisterDeviceResponse : TelepatBaseObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic) NSInteger status;

@end
