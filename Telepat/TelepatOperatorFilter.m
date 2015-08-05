//
//  TelepatFilter.m
//  GW Sales
//
//  Created by Ovidiu on 23/07/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatOperatorFilter.h"

@implementation TelepatOperatorFilter {
    TelepatFilterRelation _relation;
    NSMutableArray *_subfilters;
}

- (id) initWithRelation:(TelepatFilterRelation)relation {
    if (self = [super init]) {
        _subfilters = [NSMutableArray array];
        _relation = relation;
    }
    
    return self;
}

- (void) addSubfilter:(id)subfilter {
    [_subfilters addObject:subfilter];
}

- (NSDictionary *) toDictionary {
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    NSMutableArray *root = [NSMutableArray array];
    switch (_relation) {
        case TelepatFilterRelationAnd:
                [output setObject:root forKey:@"and"];
            break;
        
        case TelepatFilterRelationOr:
                [output setObject:root forKey:@"or"];
            break;
            
        default:
                @throw([NSException exceptionWithName:@"InvalidRelationType" reason:@"You need to specify a valid filter relation" userInfo:nil]);
            break;
    }
    
    for (id<TelepatFilterProtocol> subfilter in _subfilters) {
        [root addObject:[subfilter toDictionary]];
    }
    
    return output;
}

@end
