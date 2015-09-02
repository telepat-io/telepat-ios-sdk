//
//  TelepatFilter.h
//  GW Sales
//
//  Created by Ovidiu on 23/07/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Protocol for Telepat Filters
 /*
@protocol TelepatFilterProtocol <NSObject>

/**
 *  Serialize the filter into a NSDictionary
 */
- (NSDictionary *) toDictionary;

@end

/**
 *  Defines the type of the filter
 */
typedef NS_ENUM(NSInteger, TelepatFilterType) {
    /**
     *  The filter will use a "is" relation
     */
    TelepatFilterTypeIs,
    /**
     *  The filter will use a "in range" relation
     */
    TelepatFilterTypeRange,
    /**
     *  The filter will use a "is like" relation
     */
    TelepatFilterTypeLike
};


/**
 *  Use `TelepatFilter` instances to create filters to be used on subcribing to contexts. Do not use `TelepatFilter` directly when subscribing but include it into a `TelepatOperatorFilter`. If you want to use just one filter use a `TelepatOperatorFilter` of type `TelepatFilterRelationAnd` and add your `TelepatFilter` instance to it.
 */
@interface TelepatFilter : NSObject <TelepatFilterProtocol>

/**
 *  Create a new instance of TelepatFilter with the specified type
 *
 *  @param type The type of the to-be-created filter
 *  @return A new instance of TelepatFilter
 */
- (id) initWithType:(TelepatFilterType)type;

/**
 *  Add the field name to be filtered according to the specified filter type.
 *
 *  @param fieldName The name of the field to be filtered
 *  @param value The value on which the filtering will be made
 */
- (void) addFilteredField:(NSString *)fieldName withValue:(id)value;

/**
 *  Serialize the filter into a NSDictionary
 */
- (NSDictionary *) toDictionary;

@end
