//
//  TelepatFilter.h
//  GW Sales
//
//  Created by Ovidiu on 23/07/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TelepatFilterProtocol <NSObject>

- (NSDictionary *) toDictionary;

@end

typedef NS_ENUM(NSInteger, TelepatFilterType) {
    TelepatFilterTypeIs,
    TelepatFilterTypeRange,
    TelepatFilterTypeLike
};

@interface TelepatFilter : NSObject <TelepatFilterProtocol>

- (id) initWithType:(TelepatFilterType)type;
- (void) addFilteredField:(NSString *)fieldName withValue:(id)value;
- (NSDictionary *) toDictionary;

@end
