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

#ifdef DEBUG
const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
const int ddLogLevel = LOG_LEVEL_ERROR;
#endif

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
        
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
        [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor greenColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
        [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor redColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
        
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

- (void) registerFacebookUserWithToken:(NSString *)token andBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] registerUserWithFacebookToken:token andBlock:^(KRResponse *response) {
        TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(registerResponse);
    }];
}

- (void) registerTwitterUserWithToken:(NSString *)token secret:(NSString *)secret andBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] registerUserWithTwitterToken:token secret:secret andBlock:^(KRResponse *response) {
        TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(registerResponse);
    }];
}

- (void) registerUser:(NSString *)username withPassword:(NSString *)password name:(NSString *)name andBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] registerUser:username withPassword:password name:name andBlock:^(KRResponse *response) {
        TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(registerResponse);
    }];
}

- (void) registerUser:(TelepatUser *)user withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] registerUser:[user toDictionary] withBlock:^(KRResponse *response) {
        TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(registerResponse);
    }];
}

- (void) adminDeleteUser:(NSString *)username withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] adminDeleteUser:username withBlock:^(KRResponse *response) {
        TelepatResponse *deleteUserResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(deleteUserResponse);
    }];
}

- (void) adminUpdateUser:(TelepatUser *)oldUser withUser:(TelepatUser *)newUser andBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] adminUpdateUser:[oldUser patchAgainst:newUser] withBlock:^(KRResponse *response) {
        TelepatResponse *updateUserResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(updateUserResponse);
    }];
}

- (void) refreshTokenWithBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] refreshTokenWithBlock:^(KRResponse *response) {
        [self processLoginResponse:response withBlock:block];
    }];
}

- (void) deleteUser:(TelepatUser *)user withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] deleteUserWithID:user.user_id andUsername:user.username andBlock:^(KRResponse *response) {
        TelepatResponse *deleteUserResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(deleteUserResponse);
    }];
}

- (void) updateUser:(TelepatUser *)oldUser withUser:(TelepatUser *)newUser andBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] updateUser:[oldUser patchAgainst:newUser] withBlock:^(KRResponse *response) {
        TelepatResponse *updateUserResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(updateUserResponse);
    }];
}

- (void) listAppUsersWithBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] listAppUsersWithBlock:^(KRResponse *response) {
        TelepatResponse *listAppUsersResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(listAppUsersResponse);
    }];
}

- (void) loginWithFacebook:(NSString *)token andBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] loginWithFacebookToken:token andBlock:^(KRResponse *response) {
        [self processLoginResponse:response withBlock:block];
    }];
}

- (void) loginWithTwitter:(NSString *)authToken secret:(NSString *)secret andBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] loginWithTwitterToken:authToken secret:secret andBlock:^(KRResponse *response) {
        [self processLoginResponse:response withBlock:block];
    }];
}

- (void) login:(NSString *)username password:(NSString *)password withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] loginWithUsername:username andPassword:password withBlock:^(KRResponse *response) {
        [self processLoginResponse:response withBlock:block];
    }];
}

- (void) requestPasswordResetForUsername:(NSString *)username withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] requestPasswordResetForUsername:username withBlock:^(KRResponse *response) {
        TelepatResponse *passwordRequestResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(passwordRequestResponse);
    }];
}

- (void) resetPasswordWithToken:(NSString *)token forUserID:(NSString *)userID newPassword:(NSString *)newPassword withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] resetPasswordWithToken:token forUserID:userID newPassword:newPassword withBlock:^(KRResponse *response) {
        TelepatResponse *passwordResetResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(passwordResetResponse);
    }];
}

- (void) adminLogin:(NSString *)username password:(NSString *)password withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] adminLoginWithUsername:username andPassword:password withBlock:^(KRResponse *response) {
        [self processLoginResponse:response withBlock:block];
    }];
}

- (void) authorizeAdmin:(NSString *)username withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] adminAuthorizeWithUsername:username andBlock:^(KRResponse *response) {
        TelepatResponse *authorizeResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(authorizeResponse);
    }];
}

- (void) deauthorizeAdmin:(NSString *)username withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] adminDeauthorizeWithUsername:username andBlock:^(KRResponse *response) {
        TelepatResponse *deauthorizeResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(deauthorizeResponse);
    }];
}

- (void) adminAdd:(NSString *)username password:(NSString *)password name:(NSString *)name withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] adminAddWithUsername:username password:password name:name withBlock:^(KRResponse *response) {
        TelepatResponse *addResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(addResponse);
    }];
}

- (void) deleteAdminWithBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] adminDeleteWithBlock:^(KRResponse *response) {
        TelepatResponse *deleteResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(deleteResponse);
    }];
}

- (void) updateAdmin:(TelepatUser *)oldAdmin withUser:(TelepatUser *)newAdmin andBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] updateAdmin:[oldAdmin patchAgainst:newAdmin] withBlock:^(KRResponse *response) {
        TelepatResponse *updateAdminResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(updateAdminResponse);
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
            [_mServerContexts setObject:context forKey:context.context_id];
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

- (void) createContextWithName:(NSString *)name meta:(NSDictionary *)meta withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] createContext:name meta:meta withBlock:^(KRResponse *response) {
        TelepatResponse *createContextResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(createContextResponse);
    }];
}

- (void) getContext:(NSString *)contextId withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] getContext:contextId withBlock:^(KRResponse *response) {
        TelepatResponse *getContextResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(getContextResponse);
    }];
}

- (void) getContextsWithBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] getContextsWithBlock:^(KRResponse *response) {
        TelepatResponse *getContextsResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(getContextsResponse);
    }];
}

- (void) getSchemasWithBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] getSchemasWithBlock:^(KRResponse *response) {
        TelepatResponse *getSchemasResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(getSchemasResponse);
    }];
}

- (void) updateSchema:(NSDictionary *)schema withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] updateSchema:schema withBlock:^(KRResponse *response) {
        TelepatResponse *getUpdateSchemaResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(getUpdateSchemaResponse);
    }];
}

- (void) getCurrentAdminWithBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] getCurrentAdminWithBlock:^(KRResponse *response) {
        TelepatResponse *getMeResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(getMeResponse);
    }];
}

- (void) getCurrentUserWithBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] getCurrentUserWithBlock:^(KRResponse *response) {
        TelepatResponse *getMeResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(getMeResponse);
    }];
}

- (NSDictionary *) contextsMap {
    return _mServerContexts;
}

- (BOOL) isLoggedIn {
    return [[[KRRest sharedClient] bearer] length] > 0;
}

- (void) createAppWithName:(NSString *)appName keys:(NSArray *)keys customFields:(NSDictionary *)fields block:(TelepatResponseBlock)block {
    [[KRRest sharedClient] appCreate:appName apiKeys:keys customFields:fields withBlock:^(KRResponse *response) {
        TelepatResponse *createAppResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(createAppResponse);
    }];
}

- (void) listAppsWithBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] listAppsWithBlock:^(KRResponse *response) {
        TelepatResponse *appsListResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(appsListResponse);
    }];
}

- (void) removeAppWithBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] removeAppWithBlock:^(KRResponse *response) {
        TelepatResponse *removeAppResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(removeAppResponse);
    }];
}

- (void) updateApp:(TelepatApp *)oldApp withApp:(TelepatApp *)newApp andBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] updateApp:[oldApp patchAgainst:newApp] withBlock:^(KRResponse *response) {
        TelepatResponse *updateAppResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(updateAppResponse);
    }];
}

- (void) removeAppModel:(NSString *)modelName withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] removeAppModel:modelName withBlock:^(KRResponse *response) {
        TelepatResponse *removeModelResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(removeModelResponse);
    }];
}

- (void) removeContext:(NSString *)contextId withBlock:(TelepatResponseBlock)block {
    [[KRRest sharedClient] removeContext:contextId withBlock:^(KRResponse *response) {
        TelepatResponse *removeContextResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(removeContextResponse);
    }];
}

- (void) updateContext:(TelepatContext *)oldContext withContext:(TelepatContext *)newContext andBlock:(TelepatResponseBlock)block {
    NSMutableDictionary *mutablePatch = [NSMutableDictionary dictionaryWithDictionary:[oldContext patchAgainst:newContext]];
    mutablePatch[@"id"] = oldContext.context_id;
    [[KRRest sharedClient] updateContext:[NSDictionary dictionaryWithDictionary:mutablePatch] withBlock:^(KRResponse *response) {
        TelepatResponse *updateContextResponse = [[TelepatResponse alloc] initWithResponse:response];
        block(updateContextResponse);
    }];
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
