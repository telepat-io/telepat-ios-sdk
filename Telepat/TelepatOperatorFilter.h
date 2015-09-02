//
//  TelepatFilter.h
//  GW Sales
//
//  Created by Ovidiu on 23/07/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TelepatFilter.h"

/**
 *  Defines the relation between subfilters
 */
typedef NS_ENUM(NSInteger, TelepatFilterRelation) {
    /**
     *  "AND" relation
     */
    TelepatFilterRelationAnd,
    /**
     *  "OR" relation
     */
    TelepatFilterRelationOr
};


/**
 *  Use `TelepatOperatorFilter` to create "AND" or "OR" relations between `TelepatFilter`s
 */
@interface TelepatOperatorFilter : NSObject <TelepatFilterProtocol>

/**
 *  Create a new `TelepatOperatorFilter` with the specified relation
 *
 *  @param relation The relation type
 *  @return A new instance of `TelepatOperatorFilter` with the specified relation type
 */
- (id) initWithRelation:(TelepatFilterRelation)relation;

/**
 *  Add a subfilter (e.g. a `TelepatFilter` instance)
 *
 *  @param subfilter A `TelepatFilter` instance
 */
- (void) addSubfilter:(id)subfilter;

/**
 *  Serialize the filter into a NSDictionary
 */
- (NSDictionary *) toDictionary;

@end
