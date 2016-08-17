//
//  TelepatIndexedList.h
//  Pods
//
//  Created by Ovidiu D. Nitan on 17/08/16.
//
//

#import <Foundation/Foundation.h>
#import "TelepatBaseObject.h"

typedef void (^TelepatIndexedListGetMembersResponseBlock)(TelepatResponse *response, NSArray *members);
typedef void (^TelepatIndexedListRemoveMemberResponseBlock)(TelepatResponse *response, BOOL success);
typedef void (^TelepatIndexedListRemoveListResponseBlock)(TelepatResponse *response, BOOL success);

@interface TelepatIndexedList : NSObject

- (instancetype) initWithName:(NSString *)name indexedProperty:(NSString *)property;

- (void) appendMember:(NSDictionary *)memberObject;
- (void) appendMember:(NSDictionary *)memberObject withBlock:(TelepatResponseBlock)block;
- (void) getMembers:(NSArray *)members withBlock:(TelepatIndexedListGetMembersResponseBlock)block;
- (void) removeMember:(NSString *)memberName;
- (void) removeMember:(NSString *)memberName withBlock:(TelepatIndexedListRemoveMemberResponseBlock)block;
- (void) removeList;
- (void) removeListWithBlock:(TelepatIndexedListRemoveListResponseBlock)block;

@end
