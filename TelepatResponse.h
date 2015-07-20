//
//  TelepatResponse.h
//  Kraken
//
//  Created by Ovidiu on 29/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KRResponse.h"
#import "TelepatBaseObject.h"

@interface TelepatResponse : NSObject

@property (nonatomic) NSInteger status;
@property (nonatomic, strong) id content;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSError *error;

- (id) initWithResponse:(KRResponse *)response;
- (BOOL) isError;
- (id) getObjectOfType:(Class)classType;

@end
