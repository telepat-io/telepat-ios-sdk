//
//  TelepatIndexedList.m
//  Pods
//
//  Created by Ovidiu D. Nitan on 17/08/16.
//
//

#import "TelepatIndexedList.h"
#import "TelepatResponse.h"
#import "KRRest.h"

@implementation TelepatIndexedList {
    NSString *listName;
    NSString *indexedProperty;
}

- (instancetype) initWithName:(NSString *)name indexedProperty:(NSString *)property {
    if (self = [super init]) {
        listName = name;
        indexedProperty = property;
    }
    
    return self;
}

- (void) appendMember:(NSDictionary *)memberObject {
    [self appendMember:memberObject withBlock:nil];
}

- (void) appendMember:(NSDictionary *)memberObject withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] appendMember:memberObject toIndexedList:listName withPropertyName:indexedProperty andBlock:^(KRResponse *response) {
        TelepatResponse *telepatResponse = [[TelepatResponse alloc] initWithResponse:response];
        if (block) block(telepatResponse);
    }];
}

- (void) getMembers:(NSArray *)members withBlock:(TelepatIndexedListGetMembersResponseBlock)block {
    [[KRRest sharedClient] getMembers:members fromIndexedList:listName withPropertyName:indexedProperty andBlock:^(KRResponse *response) {
        TelepatResponse *telepatResponse = [[TelepatResponse alloc] initWithResponse:response];
        if (![telepatResponse isError]) {
            NSDictionary *membersDict = telepatResponse.content;
            NSMutableArray *mutableMembers = [NSMutableArray array];
            for (NSString *key in membersDict) {
                if ([[membersDict objectForKey:key] isKindOfClass:[NSDictionary class]]) {
                    [mutableMembers addObject:[membersDict objectForKey:key]];
                }
            }
            block(telepatResponse, [NSArray arrayWithArray:mutableMembers]);
        } else {
            block(telepatResponse, nil);
        }
    }];
}

- (void) removeMember:(NSString *)memberName {
    [self removeMember:memberName withBlock:nil];
}

- (void) removeMember:(NSString *)memberName withBlock:(TelepatIndexedListRemoveMemberResponseBlock)block {
    [[KRRest sharedClient] removeMember:memberName fromIndexedList:listName withPropertyName:indexedProperty andBlock:^(KRResponse *response) {
        TelepatResponse *telepatResponse = [[TelepatResponse alloc] initWithResponse:response];
        if (![telepatResponse isError]) {
            NSDictionary *responseDict = telepatResponse.content;
            BOOL success = [[responseDict objectForKey:@"removed"] boolValue];
            if (block) block(telepatResponse, success);
        } else {
            if (block) block(telepatResponse, NO);
        }
    }];
}

- (void) removeList {
    [self removeListWithBlock:nil];
}

- (void) removeListWithBlock:(TelepatIndexedListRemoveListResponseBlock)block {
    [[KRRest sharedClient] removeIndexedList:listName withBlock:^(KRResponse *response) {
        TelepatResponse *telepatResponse = [[TelepatResponse alloc] initWithResponse:response];
        if (![telepatResponse isError]) {
            NSDictionary *responseDict = telepatResponse.content;
            BOOL success = [[responseDict objectForKey:@"removed"] boolValue];
            if (block) block(telepatResponse, success);
        } else {
            if (block) block(telepatResponse, NO);
        }
    }];
}

@end
