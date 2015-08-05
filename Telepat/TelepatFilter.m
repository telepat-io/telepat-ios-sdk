//
//  TelepatFilter.m
//  GW Sales
//
//  Created by Ovidiu on 23/07/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatFilter.h"

@implementation TelepatFilter {
    TelepatFilterType _type;
    NSMutableDictionary *_fields;
}

- (id) initWithType:(TelepatFilterType)type {
    if (self = [super init]) {
        _type = type;
        _fields = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void) addFilteredField:(NSString *)fieldName withValue:(id)value {
    [_fields setObject:value forKey:fieldName];
}

- (NSDictionary *) toDictionary {
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    switch (_type) {
        case TelepatFilterTypeIs:
            [output setObject:_fields forKey:@"is"];
            break;
            
        case TelepatFilterTypeLike:
            [output setObject:_fields forKey:@"is"];
            break;
            
        case TelepatFilterTypeRange:
            [output setObject:_fields forKey:@"range"];
            break;
            
        default:
            @throw([NSException exceptionWithName:@"InvalidFilterType" reason:@"You need to specify the filter type" userInfo:nil]);
            break;
    }
    
    return output;
}

@end
