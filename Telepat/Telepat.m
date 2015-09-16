//
//  Telepat.m
//  Kraken
//
//  Created by Ovidiu on 24/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <sys/utsname.h>
#import <CommonCrypto/CommonDigest.h>
#import "Telepat.h"
#import "TelepatWebsocketTransport.h"
#import "NSData+HexString.h"

@implementation Telepat {
    NSMutableDictionary *_mServerContexts;
    NSMutableDictionary *_subscriptions;
    TelepatDB *_dbInstance;
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

+ (void) setApplicationId:(NSString *)clientAppId apiKey:(NSString *)clientApiKey {
    [[Telepat client] setAppId:clientAppId];
    [[Telepat client] setApiKey:clientApiKey];
}

- (id) init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteNotificationReceived:) name:TelepatRemoteNotificationReceived object:nil];
        
        _dbInstance = [TelepatYapDB database];
        [[KRRest sharedClient] setDevice_id:[_dbInstance getOperationsDataForKey:kUDID defaultValue:@""]];
    }
    
    return self;
}

- (NSString *) deviceID:(NSString *)string {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"device_id"];
}

- (void) registerDeviceForWebsocketsWithBlock:(TelepatResponseBlock)block shouldUpdateBackend:(BOOL)shouldUpdateBackend {
    [[KRRest sharedClient] setSocketsEnabled:YES];
    
    NSString *udid = [_dbInstance getOperationsDataForKey:kUDID defaultValue:@""];
    [[TelepatWebsocketTransport sharedClient] connect:[KRRest socketURL] withBlock:^(NSString *token) {
        if ([udid length] && !shouldUpdateBackend) {
            block(nil);
            return;
        }
        
        if (![udid length]) {
            [[KRRest sharedClient] registerDevice:[UIDevice currentDevice] token:token update:NO withBlock:^(KRResponse *response) {
                TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithResponse:response];
                if (![registerResponse isError]) {
                    TelepatDeviceIdentifier *deviceIdentifier = [registerResponse getObjectOfType:[TelepatDeviceIdentifier class]];
                    [[KRRest sharedClient] setDevice_id:deviceIdentifier.identifier];
                    [_dbInstance setOperationsDataWithObject:deviceIdentifier.identifier forKey:kUDID];
                }
                block(registerResponse);
            }];
        } else {
            [[KRRest sharedClient] setDevice_id:udid];
            
            [[KRRest sharedClient] registerDevice:[UIDevice currentDevice] token:token update:YES withBlock:^(KRResponse *response) {
                TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithResponse:response];
                block(registerResponse);
            }];
        }
    }];
}

- (void) registerDeviceWithToken:(NSString*)token withBlock:(TelepatResponseBlock)block {
    [self registerDeviceWithToken:token shouldUpdateBackend:NO withBlock:block];
}

- (void) registerDeviceWithToken:(NSString*)token shouldUpdateBackend:(BOOL)shouldUpdateBackend withBlock:(TelepatResponseBlock)block {
    NSString *udid = [_dbInstance getOperationsDataForKey:kUDID defaultValue:@""];
    
    if ([udid length] && !shouldUpdateBackend) return;
    
    if (![udid length]) {
        [[KRRest sharedClient] registerDevice:[UIDevice currentDevice] token:token update:NO withBlock:^(KRResponse *response) {
            TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithResponse:response];
            if (![registerResponse isError]) {
                TelepatDeviceIdentifier *deviceIdentifier = [registerResponse getObjectOfType:[TelepatDeviceIdentifier class]];
                [[KRRest sharedClient] setDevice_id:deviceIdentifier.identifier];
                [_dbInstance setOperationsDataWithObject:deviceIdentifier.identifier forKey:kUDID];
            }
            block(registerResponse);
        }];
    } else {
        [[KRRest sharedClient] setDevice_id:udid];
        
        [[KRRest sharedClient] registerDevice:[UIDevice currentDevice] token:token update:YES withBlock:^(KRResponse *response) {
            TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithResponse:response];
            block(registerResponse);
        }];
    }
}

- (void) registerUser:(NSString *)token withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] registerUser:token andBlock:^(KRResponse *response) {
        TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(registerResponse);
    }];
}

- (void) login:(NSString *)token withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] loginWithToken:token andBlock:^(KRResponse *response) {
        [self processLoginResponse:response withBlock:block];
    }];
}

- (void) login:(NSString *)username password:(NSString *)password withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] loginWithUsername:username andPassword:password withBlock:^(KRResponse *response) {
        [self processLoginResponse:response withBlock:block];
    }];
}

- (void) processLoginResponse:(KRResponse *)response withBlock:(TelepatResponseBlock)block {
    TelepatResponse *loginResponse = [[TelepatResponse alloc] initWithResponse:response];
    if (![loginResponse isError]) {
        TelepatAuthorization *tokenObj = [loginResponse getObjectOfType:[TelepatAuthorization class]];
        [_dbInstance setOperationsDataWithObject:tokenObj forKey:kJWT];
        [_dbInstance setOperationsDataWithObject:[NSDate date] forKey:kJWT_TIMESTAMP];
        [[KRRest sharedClient] setBearer:tokenObj.token];
    }
    block(loginResponse);
}

- (void) logoutWithBlock:(TelepatResponseBlock)block {
    [[TelepatWebsocketTransport sharedClient] disconnect];
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
                  }];
}

- (TelepatChannel *) subscribe:(TelepatContext *)context modelName:(NSString *)modelName classType:(Class)classType withBlock:(TelepatResponseBlock)block {
    if (![classType isSubclassOfClass:[TelepatBaseObject class]])
        @throw([NSException exceptionWithName:kTelepatInvalidClass reason:@"classType parameter must be a subclass of TelepatBaseObject" userInfo:@{@"classType": classType}]);
    
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
    NSData *dataIn = [apiKey dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableData *dataOut = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(dataIn.bytes, (CC_LONG)dataIn.length, dataOut.mutableBytes);
    _apiKey = [[NSData dataWithData:dataOut] dataToHex];
    
    [[KRRest sharedClient] setApi_key:self.apiKey];
}

- (void) setAppId:(NSString *)appId {
    _appId = appId;
    [[KRRest sharedClient] setApp_id:appId];
}

- (void) remoteNotificationReceived:(NSNotification *)notification {
    NSDictionary *userInfo = notification.object;
    if (userInfo[@"data"] == nil) return;
    NSDictionary *data = userInfo[@"data"];
    TelepatNotificationOrigin origin = [notification.userInfo[@"source"] intValue];
    
    // process "new" notifications
    for (NSDictionary *ndict in data[@"new"]) {
        TelepatTransportNotification *createdTransportNotification = [[TelepatTransportNotification alloc] init];
        createdTransportNotification.type = TelepatNotificationTypeObjectAdded;
        createdTransportNotification.origin = origin;
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
        updatedTransportNotification.origin = origin;
        updatedTransportNotification.value = ndict[@"value"];
        updatedTransportNotification.path = ndict[@"path"];
        
        TelepatChannel *channel = [self channelWithSubscription:ndict[@"subscription"]];
        [channel processNotification:updatedTransportNotification];
    }
    
    // process "deleted" notifications
    for (NSDictionary *ndict in data[@"deleted"]) {
        TelepatTransportNotification *deletedTransportNotification = [[TelepatTransportNotification alloc] init];
        deletedTransportNotification.type = TelepatNotificationTypeObjectDeleted;
        deletedTransportNotification.origin = origin;
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

- (TelepatDB *) dbInstance {
    return _dbInstance;
}

- (void) dealloc {
    [_dbInstance close];
}

@end
