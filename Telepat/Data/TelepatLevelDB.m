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

static TelepatLevelDB *telepatdb;

NSString *const DB_NAME = @"TELEPAT_OPERATIONS";
NSString *const OPERATIONS_PREFIX = @"TP_OPERATIONS_";
NSString *const OBJECTS_PREFIX = @"TP_OBJECTS_";

@implementation TelepatLevelDB {
    LevelDB *_dbInstance;
}

+ (id) database {
    if (!telepatdb) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            telepatdb = [[TelepatLevelDB alloc] init];
        });
    }
    return telepatdb;
}

- (id) init {
    if (self = [super init]) {
        _dbInstance = [LevelDB databaseInLibraryWithName:@"Telepat.ldb"];
    }
    return self;
}

- (NSString *) getPrefixForChannel:(NSString *)channelIdenfier {
    return [NSString stringWithFormat:@"%@%@", OBJECTS_PREFIX, channelIdenfier];
}

- (NSString *) getKeyForObjectID:(NSString *)objectID inChannel:(NSString *)channelIdenfier {
    return [NSString stringWithFormat:@"%@:%@", [self getPrefixForChannel:channelIdenfier], objectID];
}

- (BOOL) objectWithID:(NSString *)objectID existsInChannel:(NSString *) channelIdenfier {
    return [_dbInstance objectExistsForKey:[self getKeyForObjectID:objectID inChannel:channelIdenfier]];
}

- (id) getObjectWithID:(NSString *)objectID fromChannel:(NSString *)channelIdentifier {
    return [_dbInstance objectForKey:[self getKeyForObjectID:objectID inChannel:channelIdentifier]];
}

- (NSArray *) getObjectsFromChannel:(NSString *)channelIdentifier {
    return [_dbInstance objectForKey:channelIdentifier];
}

- (id) getOperationsDataWithKey:(NSString *)key defaultValue:(id)defaultValue {
    return [self getData:key defaultValue:defaultValue];
}

- (void) persistObject:(TelepatBaseObject *)object inChannel:(NSString *)channelIdentifier {
    [_dbInstance setObject:object forKey:[self getKeyForObjectID:object.object_id inChannel:channelIdentifier]];
}

- (void) persistObjects:(NSArray *)objects inChannel:(NSString *)channelIdentifier {
    [_dbInstance setObject:objects forKey:channelIdentifier];
}

- (void) setOperationsDataWithObject:(id)object forKey:(NSString *)key {
    if (object) {
        [_dbInstance setObject:object forKey:[NSString stringWithFormat:@"%@%@", OPERATIONS_PREFIX, key]];
    }
}

- (id) getOperationsDataForKey:(NSString *)key defaultValue:(id)defaultValue {
    return [self getData:[NSString stringWithFormat:@"%@%@", OPERATIONS_PREFIX, key] defaultValue:defaultValue];
}

- (void) deleteObjectWithID:(NSString *)objectID fromChannel:(NSString *)channelIdentifier {
    [_dbInstance removeObjectForKey:[self getKeyForObjectID:objectID inChannel:channelIdentifier]];
}

- (void) deleteObjectsFromChannel:(NSString *)channelIdentifier {
    [_dbInstance removeObjectForKey:channelIdentifier];
}

- (void) empty {
    [_dbInstance removeAllObjects];
}

- (void) close {
    [super close];
}

#pragma mark Private methods

- (id) getData:(NSString *)key defaultValue:(id)defaultValue {
    id obj = [_dbInstance objectForKey:key];
    return obj ? obj : defaultValue;
}

@end