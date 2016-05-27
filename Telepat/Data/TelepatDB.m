//
//  TelepatDB.m
//  GW Sales
//
//  Created by Ovidiu on 05/08/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatDB.h"
#define mustOverride() @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"%s must be overridden in a subclass/category", __PRETTY_FUNCTION__] userInfo:nil]

@implementation TelepatDB

+ (id) database {
    mustOverride();
}

- (NSArray *) keysForChannel:(NSString *)channelIdentifier {
    mustOverride();
}

- (BOOL) objectWithID:(NSString *)objectID existsInChannel:(NSString *) channelIdenfier {
    mustOverride();
}

- (id) getObjectWithID:(NSString *)objectID fromChannel:(NSString *)channelIdentifier {
    mustOverride();
}

- (NSArray *) getObjectsFromChannel:(NSString *)channelIdentifier {
    mustOverride();
}

- (void) setOperationsDataWithObject:(id)object forKey:(NSString *)key {
    mustOverride();
}

- (id) getOperationsDataForKey:(NSString *)key defaultValue:(id)defaultValue {
    mustOverride();
}

- (void) persistObject:(TelepatBaseObject *)object inChannel:(NSString *)channelIdentifier {
    mustOverride();
}

- (void) persistObjects:(NSArray *)objects inChannel:(NSString *)channelIdentifier {
    mustOverride();
}

- (void) deleteObjectWithID:(NSString *)objectID fromChannel:(NSString *)channelIdentifier {
    mustOverride();
}

- (void) deleteObjectsFromChannel:(NSString *)channelIdentifier {
    mustOverride();
}

- (void) empty {
    mustOverride();
}

- (void) close {
    mustOverride();
}

@end
