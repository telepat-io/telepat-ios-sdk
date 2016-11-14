//
//  TelepatIndexedList.m
//  Pods
//
//  Created by Ovidiu D. Nitan on 17/08/16.
//
//

#import "TelepatIndexedList.h"
<<<<<<< HEAD
#import "TelepatResponse.h"
#import "KRRest.h"
=======
#import "Telepat.h"
>>>>>>> markiza

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
    [[Telepat client] post:[Telepat urlForEndpoint:@"/til/append"]
                parameters:@{@"listName": listName,
                             @"indexedProperty": indexedProperty,
                             @"memberObject": memberObject}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 if (block) block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) getMembers:(NSArray *)members withBlock:(TelepatIndexedListGetMembersResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/til/get"]
                parameters:@{@"listName": listName,
                             @"indexedProperty": indexedProperty,
                             @"members": members}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 TelepatResponse *telepatResponse = [[TelepatResponse alloc] initWithDictionary:dictionary error:error];
                 if (![telepatResponse isError]) {
                     NSDictionary *membersDict = telepatResponse.content;
                     NSMutableArray *mutableMembers = [NSMutableArray array];
                     for (NSString *key in membersDict) {
                         if ([[membersDict objectForKey:key] isKindOfClass:[NSDictionary class]]) {
                             [mutableMembers addObject:membersDict[key]];
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
<<<<<<< HEAD
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
=======
    [[Telepat client] post:[Telepat urlForEndpoint:@"/til/removeMember"]
                parameters:@{@"listName": listName,
                             @"indexedProperty": indexedProperty,
                             @"member": memberName}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 TelepatResponse *telepatResponse = [[TelepatResponse alloc] initWithDictionary:dictionary error:error];
                 if (![telepatResponse isError]) {
                     NSDictionary *responseDict = telepatResponse.content;
                     BOOL success = [[responseDict objectForKey:@"removed"] boolValue];
                     if (block) block(telepatResponse, success);
                 } else {
                     if (block) block(telepatResponse, NO);
                 }
             }];
}

- (void) removeIndexedList:(NSString *)listName withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/til/removeList"]
                parameters:@{@"listName": listName}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 if (block) block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
>>>>>>> markiza
}

- (void) removeList {
    [self removeListWithBlock:nil];
}

- (void) removeListWithBlock:(TelepatIndexedListRemoveListResponseBlock)block {
<<<<<<< HEAD
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
=======
    [[Telepat client] post:[Telepat urlForEndpoint:@"/til/removeList"]
                     parameters:@{@"listName": listName}
                        headers:@{}
                  responseBlock:^(NSDictionary *dictionary, NSError *error) {
                      TelepatResponse *telepatResponse = [[TelepatResponse alloc] initWithDictionary:dictionary error:error];
                      if (![telepatResponse isError]) {
                          NSDictionary *responseDict = telepatResponse.content;
                          BOOL success = [[responseDict objectForKey:@"removed"] boolValue];
                          if (block) block(telepatResponse, success);
                      } else {
                          if (block) block(telepatResponse, NO);
                      }
                  }];
>>>>>>> markiza
}

@end
