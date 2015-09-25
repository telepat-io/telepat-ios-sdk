//
//  TelepatYapDB.m
//  GW Sales
//
//  Created by Ovidiu on 05/08/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatYapDB.h"

NSString *const DB_NAME = @"TELEPAT_OPERATIONS";
NSString *const OPERATIONS_PREFIX = @"TP_OPERATIONS_";
NSString *const OBJECTS_PREFIX = @"TP_OBJECTS_";

static TelepatYapDB *telepatdb;

@implementation TelepatYapDB {
    YapDatabase *_dbInstance;
    YapDatabaseConnection *_dbConnection;
}

+ (NSString *) databasePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [baseDir stringByAppendingPathComponent:@"Telepat.sqlite"];
}

+ (NSString *) applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

+ (id) database {
    if (!telepatdb) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            telepatdb = [[TelepatYapDB alloc] init];
        });
    }
    return telepatdb;
}

- (id) init {
    if (self = [super init]) {
        _dbInstance = [[YapDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/yap.db", [TelepatYapDB applicationDocumentsDirectory]]];
        _dbConnection = [_dbInstance newConnection];
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
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    BOOL __block exists = NO;
    
    [_dbConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        exists = [transaction objectForKey:[self getKeyForObjectID:objectID inChannel:channelIdenfier] inCollection:nil] != nil;
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return exists;
}

- (id) getObjectWithID:(NSString *)objectID fromChannel:(NSString *)channelIdentifier {
    id __block object = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [_dbConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        object = [transaction objectForKey:[self getKeyForObjectID:objectID inChannel:channelIdentifier] inCollection:nil];
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return object;
}

- (NSArray *) getObjectsFromChannel:(NSString *)channelIdentifier {
    id __block objects = nil;
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [_dbConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        objects = [transaction objectForKey:channelIdentifier inCollection:nil];
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return objects;
}

- (void) setOperationsDataWithObject:(id)object forKey:(NSString *)key {
    [_dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:object forKey:[NSString stringWithFormat:@"%@%@", OPERATIONS_PREFIX, key] inCollection:nil];
    }];
}

- (id) getOperationsDataForKey:(NSString *)key defaultValue:(id)defaultValue {
    return [self getData:[NSString stringWithFormat:@"%@%@", OPERATIONS_PREFIX, key] defaultValue:defaultValue];
}

- (void) persistObject:(TelepatBaseObject *)object inChannel:(NSString *)channelIdentifier {
    [_dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:object forKey:[self getKeyForObjectID:object.object_id inChannel:channelIdentifier] inCollection:nil];
    }];
}

- (void) persistObjects:(NSArray *)objects inChannel:(NSString *)channelIdentifier {
    [_dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:objects forKey:channelIdentifier inCollection:nil];
    }];
}

- (void) deleteObjectWithID:(NSString *)objectID fromChannel:(NSString *)channelIdentifier {
    [_dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:[self getKeyForObjectID:objectID inChannel:channelIdentifier] inCollection:nil];
    }];
}

- (void) deleteObjectsFromChannel:(NSString *)channelIdentifier {
    [_dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:channelIdentifier inCollection:nil];
    }];
}

- (void) empty {
    [_dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeAllObjectsInAllCollections];
    }];
}

- (void) close {
    _dbConnection = nil;
    _dbInstance = nil;
}

#pragma mark Private methods

- (id) getData:(NSString *)key defaultValue:(id)defaultValue {
    id __block obj = nil;
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [_dbConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        obj = [transaction objectForKey:key inCollection:nil];
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return obj ? obj : defaultValue;
}

@end
