//
//  Telepat.m
//  Kraken
//
//  Created by Ovidiu on 24/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <sys/utsname.h>
#import "Telepat.h"
#import "TelepatTransportNotification.h"

@implementation Telepat {
    NSMutableDictionary *_mServerContexts;
    NSMutableDictionary *_subscriptions;
    id<TelepatDatabaseProtocol> _dbInstance;
}

+ (Telepat *) client {
    static Telepat *telepat = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        telepat = [[self alloc] init];
    });
    
    return telepat;
}

+ (KRRest *) restClient {
    return [KRRest sharedClient];
}

+ (NSString *) deviceName {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

+ (void) setApiKey:(NSString *)apiKey {
    [[Telepat client] setApiKey:apiKey];
}

- (id) init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteNotificationReceived:) name:TelepatRemoteNotificationReceived object:nil];
        
        _dbInstance = [TelepatLevelDB database];
    }
    
    return self;
}

- (void) saveDeviceID:(NSString *)identifier {
    [[KRRest sharedClient] setDevice_id:identifier];
    [[NSUserDefaults standardUserDefaults] setObject:identifier forKey:@"device_id"];
}

- (NSString *) deviceID:(NSString *)string {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"device_id"];
}

- (void) registerDeviceWithToken:(NSString*)token withBlock:(TelepatResponseBlock)block {
    [self registerDeviceWithToken:token shouldUpdateBackend:NO withBlock:block];
}

- (void) registerDeviceWithToken:(NSString*)token shouldUpdateBackend:(BOOL)shouldUpdateBackend withBlock:(TelepatResponseBlock)block {
    NSString *udid = [_dbInstance getOperationsDataWithKey:kUDID defaultValue:@""];
    
    if ([udid length] && !shouldUpdateBackend) return;
    
    if (![udid length]) {
        [[KRRest sharedClient] registerDevice:[UIDevice currentDevice] token:token withBlock:^(KRResponse *response) {
            TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithResponse:response];
            if (![registerResponse isError]) {
                TelepatDeviceIdentifier *deviceIdentifier = [registerResponse getObjectOfType:[TelepatDeviceIdentifier class]];
                [self saveDeviceID:deviceIdentifier.identifier];
            }
            block(registerResponse);
        }];
    } //else {
        // TODO: send update
    //}
}

- (void) login:(NSString *)token withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] loginWithToken:token andBlock:^(KRResponse *response) {
        TelepatResponse *loginResponse = [[TelepatResponse alloc] initWithResponse:response];
        if (![loginResponse isError]) {
            TelepatToken *tokenObj = [loginResponse getObjectOfType:[TelepatToken class]];
            LevelDB *ldb = [LevelDB databaseInLibraryWithName:@"test.ldb"];
            [ldb setObject:tokenObj forKey:@"token"];
            [[KRRest sharedClient] setBearer:tokenObj.token];
        }
        block(loginResponse);
    }];
}

- (void) logoutWithBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] logoutWithBlock:^(KRResponse *response) {
        TelepatResponse *logoutResponse = [[TelepatResponse alloc] initWithResponse:response];
        [[KRRest sharedClient] setBearer:nil];
        block(logoutResponse);
    }];
}

- (void) getAll:(TelepatResponseBlock)block {
    [[KRRest sharedClient] updateContextsWithBlock:^(KRResponse *response) {
        TelepatResponse *getallResponse = [[TelepatResponse alloc] initWithResponse:response];
        _mServerContexts = [NSMutableDictionary dictionary];
        NSArray *contexts = [getallResponse getObjectOfType:[TelepatContext class]];
        for (TelepatContext *context in contexts) {
            [_mServerContexts setObject:context forKey:[NSNumber numberWithLong:context.context_id]];
        }
        block(getallResponse);
    }];
}

- (void) create:(NSDictionary *)body {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/object/create"]
                     parameters:body
                        headers:@{}
                  responseBlock:^(KRResponse *response) {
                      NSLog(@"create re status: %d", response.status);
                      NSLog(@"create re: %@", [response asString]);
                  }];
}

- (TelepatChannel *) subscribe:(TelepatContext *)context modelName:(NSString *)modelName classType:(Class)classType withBlock:(TelepatResponseBlock)block {
    TelepatChannel *channel = [[TelepatChannel alloc] initWithModelName:modelName context:context objectType:classType];
    [channel subscribeWithBlock:^(TelepatResponse *response) {
        block(response);
    }];
    return channel;
}

- (void) removeSubscription:(TelepatChannel *)channel withBlock:(TelepatResponseBlock)block {
    [channel unsubscribeWithBlock:^(TelepatResponse *response) {
        block(response);
    }];
}

- (void) registerSubscription:(TelepatChannel *)channel {
    if (!_subscriptions) _subscriptions = [NSMutableDictionary dictionary];
    [_subscriptions setObject:channel forKey:channel.subscriptionIdentifier];
}

- (void) unregisterSubscription:(TelepatChannel *)channel {
    [_subscriptions removeObjectForKey:channel.subscriptionIdentifier];
}

- (BOOL) isSubscribedToChannelId:(NSString *) channelIdentifier {
    return [_subscriptions.allKeys containsObject:channelIdentifier];
}

- (TelepatContext *) contextWithId:(NSInteger)contextId {
    return [_mServerContexts objectForKey:[NSNumber numberWithLong:contextId]];
}

- (NSDictionary *) contextsMap {
    return _mServerContexts;
}

- (BOOL) isLoggedIn {
    return [[[KRRest sharedClient] bearer] length] > 0;
}

- (void) setApiKey:(NSString *)apiKey {
    _apiKey = apiKey;
    [[KRRest sharedClient] setApi_key:apiKey];
}

- (void) remoteNotificationReceived:(NSNotification *)notification {
    NSDictionary *userInfo = notification.object;
    if (userInfo[@"data"] == nil) return;
    NSDictionary *data = userInfo[@"data"];
    
    // process "new" notifications
    for (NSDictionary *ndict in data[@"new"]) {
        TelepatTransportNotification *createdTransportNotification = [[TelepatTransportNotification alloc] init];
        createdTransportNotification.type = TelepatNotificationTypeObjectAdded;
        createdTransportNotification.value = ndict[@"value"];
        createdTransportNotification.subscription = ndict[@"subscription"];
        createdTransportNotification.guid = ndict[@"guid"];
        
        TelepatChannel *channel = [self channelWithSubscription:ndict[@"subscription"]];
        [channel processNotification:createdTransportNotification];
    }
    
    // process "updated" notifications
    for (NSDictionary *ndict in data[@"updated"]) {
        TelepatTransportNotification *updatedTransportNotification = [[TelepatTransportNotification alloc] init];
        updatedTransportNotification.type = TelepatNotificationTypeObjectUpdated;
        updatedTransportNotification.value = ndict[@"value"];
        updatedTransportNotification.path = ndict[@"path"];
        
        TelepatChannel *channel = [self channelWithSubscription:ndict[@"subscription"]];
        [channel processNotification:updatedTransportNotification];
    }
    
    // process "deleted" notifications
    for (NSDictionary *ndict in data[@"deleted"]) {
        TelepatTransportNotification *deletedTransportNotification = [[TelepatTransportNotification alloc] init];
        deletedTransportNotification.type = TelepatNotificationTypeObjectDeleted;
        deletedTransportNotification.value = nil;
        deletedTransportNotification.path = ndict[@"path"];
        
        TelepatChannel *channel = [self channelWithSubscription:ndict[@"subscription"]];
        [channel processNotification:deletedTransportNotification];
    }
}

- (TelepatChannel *) channelWithSubscription:(NSString *) subscriptionIdentifier {
    TelepatChannel *channel = [_subscriptions objectForKey:subscriptionIdentifier];
    return channel;
}

- (id<TelepatDatabaseProtocol>) getDBInstance {
    return _dbInstance;
}

- (void) dealloc {
    [_dbInstance close];
}

@end
