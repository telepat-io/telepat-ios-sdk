//
//  TelepatDB.h
//  GW Sales
//
//  Created by Ovidiu on 05/08/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TelepatBaseObject.h"

@interface TelepatDB : NSObject

+ (instancetype) database;
- (NSArray *) keysForChannel:(NSString *)channelIdentifier;
- (BOOL) objectWithID:(NSString *)objectID existsInChannel:(NSString *) channelIdenfier;
- (id) getObjectWithID:(NSString *)objectID fromChannel:(NSString *)channelIdentifier;
- (NSArray *) getObjectsFromChannel:(NSString *)channelIdentifier;
- (void) setOperationsDataWithObject:(id)object forKey:(NSString *)key;
- (void) deleteOperationsDataForKey:(NSString *)key;
- (id) getOperationsDataForKey:(NSString *)key defaultValue:(id)defaultValue;
- (void) persistObject:(TelepatBaseObject *)object inChannel:(NSString *)channelIdentifier;
- (void) persistObjects:(NSArray *)objects inChannel:(NSString *)channelIdentifier;
- (void) deleteObjectWithID:(NSString *)objectID fromChannel:(NSString *)channelIdentifier;
- (void) deleteObjectsFromChannel:(NSString *)channelIdentifier;
- (void) empty;
- (void) close;

@end
