//
//  TelepatContext.h
//  Kraken
//
//  Created by Ovidiu on 25/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatBaseObject.h"

@interface TelepatContext : TelepatBaseObject

@property (nonatomic) NSString *context_id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *application_id;
@property (nonatomic, strong) NSString<Optional> *type;

- (NSString *) contextIdentifier;

@end
