//
//  TelepatLevelDB.m
//  Kraken
//
//  Created by Ovidiu on 15/07/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "Telepat.h"
#import "TelepatBaseObject.h"
#import "TelepatLevelDB.h"

static TelepatLevelDB *_dbinstance;

NSString *const DB_NAME = @"TELEPAT_OPERATIONS";
NSString *const OPERATIONS_PREFIX = @"TP_OPERATIONS_";
NSString *const OBJECTS_PREFIX = @"TP_OBJECTS_";

@implementation TelepatLevelDB

+ (id) database {
    if (_dbinstance == nil)
        _dbinstance = [TelepatLevelDB databaseInLibraryWithName:@"Telepat.ldb"];
    return _dbinstance;
}

- (NSString *) getPrefixForChannel:(NSString *)channelIdenfier {
    return [NSString stringWithFormat:@"%@%@", OBJECTS_PREFIX, channelIdenfier];
}

- (NSString *) getKeyForObjectID:(NSInteger)objectID inChannel:(NSString *)channelIdenfier {
    return [NSString stringWithFormat:@"%@:%d", [self getPrefixForChannel:channelIdenfier], objectID];
}

- (BOOL) objectWithID:(NSInteger)objectID existsInChannel:(NSString *) channelIdenfier {
    return [self objectExistsForKey:[self getKeyForObjectID:objectID inChannel:channelIdenfier]];
}

- (id) getObjectWithID:(NSInteger)objectID fromChannel:(NSString *)channelIdentifier {
    return [self objectForKey:[self getKeyForObjectID:objectID inChannel:channelIdentifier]];
}

- (NSArray *) getObjectsFromChannel:(NSString *)channelIdentifier {
    return [self objectForKey:channelIdentifier];
}

- (id) getOperationsDataWithKey:(NSString *)key defaultValue:(id)defaultValue {
    return 	[self getData:key defaultValue:defaultValue];
}

- (void) persistObject:(TelepatBaseObject *)object inChannel:(NSString *)channelIdentifier {
    [self setObject:object forKey:[self getKeyForObjectID:object.object_id inChannel:channelIdentifier]];
}

- (void) persistObjects:(NSArray *)objects inChannel:(NSString *)channelIdentifier {
    [self setObject:objects forKey:channelIdentifier];
}

- (void) deleteObjectWithID:(NSInteger)objectID fromChannel:(NSString *)channelIdentifier {
    [self removeObjectForKey:[self getKeyForObjectID:objectID inChannel:channelIdentifier]];
}

- (void) deleteObjectsFromChannel:(NSString *)channelIdentifier {
    [self removeObjectForKey:channelIdentifier];
}

- (void) empty {
    [self removeAllObjects];
}

- (void) close {
    [super close];
}

#pragma mark Private methods

- (id) getData:(NSString *)key defaultValue:(id)defaultValue {
    id obj = [self objectForKey:key];
    return obj ? obj : defaultValue;
}

@end
