//
//  TelepatFilter.h
//  GW Sales
//
//  Created by Ovidiu on 23/07/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TelepatFilter.h"

typedef NS_ENUM(NSInteger, TelepatFilterRelation) {
    TelepatFilterRelationAnd,
    TelepatFilterRelationOr
};

@interface TelepatOperatorFilter : NSObject <TelepatFilterProtocol>

- (id) initWithRelation:(TelepatFilterRelation)relation;
- (void) addSubfilter:(id)subfilter;
- (NSDictionary *) toDictionary;

@end
