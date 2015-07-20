//
//  TelepatDatabaseProtocol.h
//  Kraken
//
//  Created by Ovidiu on 15/07/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TelepatBaseObject.h"

@protocol TelepatDatabaseProtocol <NSObject>

+ (id) database;
- (BOOL) objectWithID:(NSInteger)objectID existsInChannel:(NSString *) channelIdenfier;
- (id) getObjectWithID:(NSInteger)objectID fromChannel:(NSString *)channelIdentifier;
- (NSArray *) getObjectsFromChannel:(NSString *)channelIdentifier;
- (id) getOperationsDataWithKey:(NSString *)key defaultValue:(id)defaultValue;
- (void) persistObject:(TelepatBaseObject *)object inChannel:(NSString *)channelIdentifier;
- (void) persistObjects:(NSArray *)objects inChannel:(NSString *)channelIdentifier;
- (void) deleteObjectWithID:(NSInteger)objectID fromChannel:(NSString *)channelIdentifier;
- (void) deleteObjectsFromChannel:(NSString *)channelIdentifier;
- (void) empty;
- (void) close;

@end
