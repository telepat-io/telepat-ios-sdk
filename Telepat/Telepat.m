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
#import "TelepatLevelDB.h"
#import "TelepatWebsocketTransport.h"
#import "NSData+HexString.h"

#define DebugRequest(requestType) DDLogDebug(@"\n%@ %@\n%@\n%@\n----\nHTTP: %d\n%@\n", \
requestType,\
[url absoluteString], \
self.sessionManager.requestSerializer.HTTPRequestHeaders, \
[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding], \
response.statusCode, \
responseObject)

#define DebugRequestError(requestType) DDLogDebug(@"\n%@ %@\n%@\n%@\n----\nHTTP: %d\n%@\n", \
requestType, \
[url absoluteString], \
self.sessionManager.requestSerializer.HTTPRequestHeaders, \
[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding], \
response.statusCode, \
[[NSString alloc] initWithData:error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding])

#ifdef DEBUG
const int ddLogLevel = LOG_LEVEL_DEBUG;
#else
const int ddLogLevel = LOG_LEVEL_ERROR;
#endif

@implementation Telepat {
    NSMutableDictionary *_mServerContexts;
    NSMutableDictionary *_subscriptions;
    TelepatDB *_dbInstance;
}

+ (Telepat *) client {
    static Telepat *telepatClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        telepatClient = [[self alloc] init];
    });
    
    return telepatClient;
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

+ (NSURL *) urlForEndpoint:(NSString*) endpoint {
    if ([endpoint hasPrefix:@"/"]) endpoint = [endpoint substringFromIndex:1];
    NSString *apiBaseURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:kTelepatAPIURL];
    if (apiBaseURL == nil) {
        @throw [NSException exceptionWithName:kTelepatInvalidApiURL reason:@"Invalid Telepat API URL. Check if you added a proper value for kTelepatAPIURL in your Info.plist file" userInfo:nil];
    }
    if (![apiBaseURL hasSuffix:@"/"]) apiBaseURL = [NSString stringWithFormat:@"%@/", apiBaseURL];
    NSString *finalURL = [NSString stringWithFormat:@"%@%@", apiBaseURL, endpoint];
    
    return [NSURL URLWithString:finalURL];
}

+ (NSURL *) socketURL {
    NSString *socketURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:kTelepatWebSocketsURL];
    if (socketURL) return [NSURL URLWithString:socketURL];
    
    NSURL *apiURL = [NSURL URLWithString:[[NSBundle mainBundle] objectForInfoDictionaryKey:kTelepatAPIURL]];
    NSString *wsURL = [NSString stringWithFormat:@"ws://%@:80", apiURL.host];
    return [NSURL URLWithString:wsURL];
}

#pragma mark - Initializer

- (id) init {
    if (self = [super init]) {
        NSURL *url = [NSURL URLWithString:@"/" relativeToURL:[Telepat urlForEndpoint:@""]];
        self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[url baseURL]];
        [self.sessionManager.operationQueue setMaxConcurrentOperationCount:5];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteNotificationReceived:) name:TelepatRemoteNotificationReceived object:nil];
        
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
        [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor greenColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
        [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor redColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
        
        _dbInstance = [TelepatLevelDB database];
        self.deviceId = [_dbInstance getOperationsDataForKey:kUDID defaultValue:@""];
    }
    
    return self;
}

#pragma mark - Low level HTTP interface

- (NSDictionary *) mergedHeadersWithHeaders:(NSDictionary*)newHeaders {
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"kHTTPHeaders"]];
    [headers setObject:@"application/json" forKey:@"Content-Type"];
    self.deviceId ? [headers setObject:self.deviceId forKey:@"X-BLGREQ-UDID"] : [headers setObject:@"" forKey:@"X-BLGREQ-UDID"];
    if (self.bearer) [headers setObject:[NSString stringWithFormat:@"Bearer %@", self.bearer] forKey:@"Authorization"];
    if (self.apiKey) [headers setObject:self.apiKey forKey:@"X-BLGREQ-SIGN"];
    if (self.appId) [headers setObject:self.appId forKey:@"X-BLGREQ-APPID"];
    [headers addEntriesFromDictionary:newHeaders];
    return headers;
}

- (void) applyHeaders:(NSDictionary *)newHeaders {
    NSDictionary *headers = [self mergedHeadersWithHeaders:newHeaders];
    for (NSString *key in headers) {
        [self.sessionManager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
    }
}

- (void) get:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(HTTPResponseBlock)block {
    self.sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self applyHeaders:headers];
    
    [self.sessionManager GET:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequest(@"GET");
        if (block) block(responseObject, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequestError(@"GET");
        if (block) block(nil, error);
    }];
}

- (void) post:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(HTTPResponseBlock)block {
    self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self applyHeaders:headers];
    
    [self.sessionManager POST:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequest(@"POST");
        if (block) block(responseObject, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequestError(@"POST");
        /*if (errorResponse.status == 400) {
            [[KRRest sharedClient] refreshTokenWithBlock:^(HTTPResponse *refreshTokenResponse) {
                if (refreshTokenResponse.status == 200) {
                    [[KRRest sharedClient] setBearer:[[refreshTokenResponse.dict objectForKey:@"content"] objectForKey:@"token"]];
                    NSLog(@"Updated token");
                    [self post:url parameters:params headers:headers responseBlock:block];
                } else {
                    block(errorResponse);
                }
            }];
        } else {
            block(errorResponse);
        }*/
    }];
}

- (void) put:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(HTTPResponseBlock)block {
    self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self applyHeaders:headers];
    
    [self.sessionManager PUT:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequest(@"PUT");
        if (block) block(responseObject, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequestError(@"PUT");
        if (block) block(nil, error);
    }];
}

- (void) patch:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(HTTPResponseBlock)block {
    self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self applyHeaders:headers];
    
    [self.sessionManager PATCH:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequest(@"PATCH");
        if (block) block(responseObject, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequestError(@"PATCH");
        if (block) block(nil, error);
    }];
}

- (void) delete:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(HTTPResponseBlock)block {
    self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    self.sessionManager.requestSerializer.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", nil];
    [self applyHeaders:headers];
    
    [self.sessionManager DELETE:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequest(@"DELETE");
        if (block) block(responseObject, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequestError(@"DELETE");
        if (block) block(nil, error);
    }];
}

#pragma mark - Telepat methods

- (void) registerDeviceForWebsocketsWithBlock:(TelepatResponseBlock)block shouldUpdateBackend:(BOOL)shouldUpdateBackend {
    NSString *udid = [_dbInstance getOperationsDataForKey:kUDID defaultValue:@""];
    [[TelepatWebsocketTransport sharedClient] connect:[Telepat socketURL] withBlock:^(NSString *token, NSString *serverName) {
        if ([udid length] && !shouldUpdateBackend) {
            block(nil);
            return;
        }
        
        UIDevice *device = [UIDevice currentDevice];
        NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionaryWithDictionary:@{@"os": [device systemName],
                                                                                              @"version": [device systemVersion],
                                                                                              @"manufacturer": @"Apple",
                                                                                              @"model": [device model]}];
        NSDictionary *persistentDictionary = @{@"type": @"ios",
                                               @"token": @"",
                                               @"active": @(0)};
        NSDictionary *volatileDictionary = @{@"type": @"sockets",
                                             @"token": token,
                                             @"active": @(1),
                                             /*@"server_name": serverName*/};
        
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"info"] = [NSDictionary dictionaryWithDictionary:infoDictionary];
        params[@"volatile"] = volatileDictionary;
        params[@"persistent"] = persistentDictionary;
        
        self.updatesTransportType = TelepatUpdatesTransportTypeSockets;
        
        if ([udid length]) {
            infoDictionary[@"udid"] = [[device identifierForVendor] UUIDString];
            self.deviceId = udid;
        }
        
        [[Telepat client] post:[Telepat urlForEndpoint:@"/device/register"]
                    parameters:params
                       headers:@{}
                 responseBlock:^(NSDictionary *dictionary, NSError *error) {
                     TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithDictionary:dictionary error:error];
                     if (![registerResponse isError]) {
                         TelepatDeviceIdentifier *deviceIdentifier = [registerResponse getObjectOfType:[TelepatDeviceIdentifier class]];
                         if (deviceIdentifier.identifier) {
                             self.deviceId = deviceIdentifier.identifier;
                             [_dbInstance setOperationsDataWithObject:deviceIdentifier.identifier forKey:kUDID];
                             [[TelepatWebsocketTransport sharedClient] bindDevice];
                         }
                     }
                     block(registerResponse);
                 }];
    }];
}

- (void) registerDeviceWithToken:(NSString*)token withBlock:(TelepatResponseBlock)block {
    [self registerDeviceWithToken:token shouldUpdateBackend:NO withBlock:block];
}

- (void) registerDeviceWithToken:(NSString*)token shouldUpdateBackend:(BOOL)shouldUpdateBackend withBlock:(TelepatResponseBlock)block {
    NSString *udid = [_dbInstance getOperationsDataForKey:kUDID defaultValue:@""];
    
    if ([udid length] && !shouldUpdateBackend) return;
    
    UIDevice *device = [UIDevice currentDevice];
    NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionaryWithDictionary:@{@"os": [device systemName],
                                                                                          @"version": [device systemVersion],
                                                                                          @"manufacturer": @"Apple",
                                                                                          @"model": [device model]}];
    NSDictionary *persistentDictionary = @{@"type": @"ios",
                                           @"token": token,
                                           @"active": @(1)};
    NSDictionary *volatileDictionary = @{@"type": @"sockets",
                                         @"token": @"",
                                         @"active": @(0),
                                         /*@"server_name": serverName*/};
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"info"] = [NSDictionary dictionaryWithDictionary:infoDictionary];
    params[@"volatile"] = volatileDictionary;
    params[@"persistent"] = persistentDictionary;
    
    self.updatesTransportType = TelepatUpdatesTransportTypeiOS;
    
    if ([udid length]) {
        infoDictionary[@"udid"] = [[device identifierForVendor] UUIDString];
        self.deviceId = udid;
    }
    
    [[Telepat client] post:[Telepat urlForEndpoint:@"/device/register"]
                     parameters:params
                        headers:@{}
                  responseBlock:^(NSDictionary *dictionary, NSError *error) {
                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                  }];
}

- (void) registerFacebookUserWithToken:(NSString *)token andBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/register-facebook"]
                parameters:@{@"access_token": token}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) registerTwitterUserWithToken:(NSString *)token secret:(NSString *)secret andBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/register-twitter"]
                parameters:@{@"oauth_token": token,
                             @"oauth_token_secret": secret}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) registerUser:(NSString *)username withPassword:(NSString *)password name:(NSString *)name andBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/register-username"]
                parameters:@{@"username": username,
                             @"password": password,
                             @"name": name}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) registerUser:(TelepatUser *)user withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/register-username"]
                parameters:[user toDictionary]
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) adminDeleteUser:(NSString *)username withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/user/delete"]
                parameters:@{@"username": username}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) adminUpdateUser:(TelepatUser *)oldUser withUser:(TelepatUser *)newUser andBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/user/update"]
                parameters:[oldUser patchAgainst:newUser]
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) refreshTokenWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] get:[Telepat urlForEndpoint:@"/user/refresh_token"]
               parameters:@{}
                  headers:@{}
            responseBlock:^(NSDictionary *dictionary, NSError *error) {
                block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
            }];
}

- (void) deleteUser:(TelepatUser *)user withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/delete"]
                parameters:@{@"id": user.user_id,
                             @"username": user.username}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) updateUser:(TelepatUser *)oldUser withUser:(TelepatUser *)newUser andBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/update"]
                parameters:[oldUser patchAgainst:newUser]
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) listAppUsersWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] get:[Telepat urlForEndpoint:@"/admin/user/all"]
               parameters:@{}
                  headers:@{}
            responseBlock:^(NSDictionary *dictionary, NSError *error) {
                block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
            }];
}

- (void) loginWithFacebook:(NSString *)token andBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/login-facebook"]
                parameters:@{@"access_token": token}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 [self processLoginResponse:[[TelepatResponse alloc] initWithDictionary:dictionary error:error] withBlock:block];
             }];
}

- (void) loginWithTwitter:(NSString *)authToken secret:(NSString *)authSecret andBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/login-twitter"]
                parameters:@{@"oauth_token": authToken,
                             @"oauth_token_secret": authSecret}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 [self processLoginResponse:[[TelepatResponse alloc] initWithDictionary:dictionary error:error] withBlock:block];
             }];
}

- (void) login:(NSString *)username password:(NSString *)password withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/login_password"]
                     parameters:@{@"username": username,
                                  @"password": password}
                        headers:@{}
                  responseBlock:^(NSDictionary *dictionary, NSError *error) {
                      [self processLoginResponse:[[TelepatResponse alloc] initWithDictionary:dictionary error:error] withBlock:block];
                  }];
}

- (void) requestPasswordResetForUsername:(NSString *)username withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/request_password_reset"]
                parameters:@{@"type": @"app",
                             @"username": username}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) resetPasswordWithToken:(NSString *)token forUserID:(NSString *)userID newPassword:(NSString *)newPassword withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/password_reset"]
                parameters:@{@"token": token,
                             @"user_id": userID,
                             @"password": newPassword}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) linkAccountWithFacebook:(NSString *)username token:(NSString *)token withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/login-facebook"]
                parameters:@{@"access_token": token,
                             @"username": username}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) adminLogin:(NSString *)username password:(NSString *)password withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/login"]
                parameters:@{@"email": username,
                             @"password": password}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) authorizeAdmin:(NSString *)username withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/app/authorize"]
                parameters:@{@"email": username}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) deauthorizeAdmin:(NSString *)username withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/app/deauthorize"]
                parameters:@{@"email": username}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) adminAdd:(NSString *)username password:(NSString *)password name:(NSString *)name withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/add"]
                parameters:@{@"email": username,
                             @"password": password,
                             @"name": name}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) deleteAdminWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/delete"]
                parameters:@{}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) updateAdmin:(TelepatUser *)oldAdmin withUser:(TelepatUser *)newAdmin andBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/update"]
                     parameters:[oldAdmin patchAgainst:newAdmin]
                        headers:@{}
                  responseBlock:^(NSDictionary *dictionary, NSError *error) {
                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                  }];
}

- (void) processLoginResponse:(TelepatResponse *)loginResponse withBlock:(TelepatResponseBlock)block {
    if (![loginResponse isError]) {
        TelepatAuthorization *tokenObj = [loginResponse getObjectOfType:[TelepatAuthorization class]];
        [_dbInstance setOperationsDataWithObject:tokenObj forKey:kJWT];
        [_dbInstance setOperationsDataWithObject:[NSDate date] forKey:kJWT_TIMESTAMP];
        self.bearer = tokenObj.token;
    }
    block(loginResponse);
}

- (void) logoutWithBlock:(TelepatResponseBlock)block {
    [[TelepatWebsocketTransport sharedClient] disconnect];
    
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/logout"]
                parameters:@{}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 TelepatResponse *logoutResponse = [[TelepatResponse alloc] initWithDictionary:dictionary error:error];
                 self.bearer = nil;
                 block(logoutResponse);
             }];
}

- (void) getAll:(TelepatResponseBlock)block {
    [self getContextsWithBlock:^(TelepatResponse *response) {
        _mServerContexts = [NSMutableDictionary dictionary];
        NSArray *contexts = [response getObjectOfType:[TelepatContext class]];
        for (TelepatContext *context in contexts) {
            [_mServerContexts setObject:context forKey:context.context_id];
        }
        block(response);
    }];
}

- (NSString *) createObject:(TelepatBaseObject *)object inContext:(TelepatContext *)context model:(NSString *)modelName withBlock:(TelepatResponseBlock)block {
    [object setChannel:self];
    [object setUuid:[[NSUUID UUID] UUIDString]];
    [[Telepat client] post:[Telepat urlForEndpoint:@"/object/create"]
                parameters:@{@"model": modelName,
                             @"context": context.context_id,
                             @"content": [object toDictionary]}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 if (block) block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
    return object.uuid;
}

- (void) updateObject:(TelepatBaseObject *)oldObject withObject:(TelepatBaseObject *)newObject withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/object/update"]
                parameters:[oldObject patchAgainst:newObject]
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 if (block) block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) count:(id)body withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/object/count"]
                parameters:body
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (TelepatChannel *) subscribe:(TelepatContext *)context modelName:(NSString *)modelName classType:(Class)classType withBlock:(TelepatResponseBlock)block {
    return [self subscribe:context modelName:modelName classType:classType filter:nil withBlock:block];
}

- (TelepatChannel *) subscribe:(TelepatContext *)context modelName:(NSString *)modelName classType:(Class)classType filter:(TelepatOperatorFilter*)filter withBlock:(TelepatResponseBlock)block {
    if (![classType isSubclassOfClass:[TelepatBaseObject class]])
        @throw([NSException exceptionWithName:kTelepatInvalidClass reason:@"classType parameter must be a subclass of TelepatBaseObject" userInfo:@{@"classType": classType}]);
    
    TelepatChannel *channel = [[TelepatChannel alloc] initWithModelName:modelName context:context objectType:classType];
    if (filter) channel.opFilter = filter;
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

- (TelepatContext *) contextWithId:(NSString *)contextId {
    return [_mServerContexts objectForKey:contextId];
}

- (TelepatContext *) contextWithIdentifier:(NSString *)identifier {
    for (NSString *contextId in _mServerContexts) {
        if ([[_mServerContexts[contextId] contextIdentifier] isEqualToString:identifier]) return _mServerContexts[contextId];
    }
    return nil;
}

- (void) createContextWithName:(NSString *)name meta:(NSDictionary *)meta withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/context/add"]
                parameters:@{@"name": name,
                             @"meta": meta}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) getContext:(NSString *)contextId withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/context"]
                parameters:@{@"id": contextId}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) getContextsWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/context/all"]
                parameters:@{}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) getContextsWithRange:(NSRange)range andBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/context/all"]
                parameters:@{@"offset": @(range.location),
                             @"limit": @(range.length)}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) getSchemasWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] get:[Telepat urlForEndpoint:@"/admin/schema/all"]
               parameters:@{}
                  headers:@{}
            responseBlock:^(NSDictionary *dictionary, NSError *error) {
                block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
            }];
}

- (void) updateSchema:(NSDictionary *)schema withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/schema/update"]
                parameters:schema
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) getCurrentAdminWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] get:[Telepat urlForEndpoint:@"/admin/me"]
               parameters:@{}
                  headers:@{}
            responseBlock:^(NSDictionary *dictionary, NSError *error) {
                block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
            }];
}

- (void) getCurrentUserWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] get:[Telepat urlForEndpoint:@"/user/me"]
               parameters:@{}
                  headers:@{}
            responseBlock:^(NSDictionary *dictionary, NSError *error) {
                block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
            }];
}

- (NSDictionary *) contextsMap {
    return _mServerContexts;
}

- (BOOL) isLoggedIn {
    return [self.bearer length] > 0;
}

- (void) createAppWithName:(NSString *)appName keys:(NSArray *)keys customFields:(NSDictionary *)fields block:(TelepatResponseBlock)block {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:fields];
    params[@"name"] = appName;
    params[@"keys"] = keys;
    
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/app/add"]
                parameters:[NSDictionary dictionaryWithDictionary:params]
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) listAppsWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] get:[Telepat urlForEndpoint:@"/admin/apps"]
               parameters:@{}
                  headers:@{}
            responseBlock:^(NSDictionary *dictionary, NSError *error) {
                block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
            }];
}

- (void) removeAppWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/app/remove"]
                parameters:@{}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) updateApp:(TelepatApp *)oldApp withApp:(TelepatApp *)newApp andBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/app/update"]
                parameters:[oldApp patchAgainst:newApp]
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) removeAppModel:(NSString *)modelName withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/schema/remove_model"]
                parameters:@{}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) removeContext:(NSString *)contextId withBlock:(TelepatResponseBlock)block {
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/context/remove"]
                parameters:@{@"id": contextId}
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) updateContext:(TelepatContext *)oldContext withContext:(TelepatContext *)newContext andBlock:(TelepatResponseBlock)block {
    NSMutableDictionary *mutablePatch = [NSMutableDictionary dictionaryWithDictionary:[oldContext patchAgainst:newContext]];
    mutablePatch[@"id"] = oldContext.context_id;
    
    [[Telepat client] post:[Telepat urlForEndpoint:@"/admin/context/update"]
                parameters:[NSDictionary dictionaryWithDictionary:mutablePatch]
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) sendProxiedRequest:(TelepatProxyRequest *)request withResponseBlock:(void (^)(NSData *responseData, NSError *error))block {
    self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    self.sessionManager.responseSerializer.acceptableContentTypes = nil;
    [self applyHeaders:@{}];
    
    [self.sessionManager POST:@"/proxy" parameters:request success:^(NSURLSessionDataTask *task, id responseObject) {
        if (block) block(responseObject, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (block) block(nil, error);
    }];
}

- (void) getUserMetadataWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] get:[Telepat urlForEndpoint:@"/user/metadata"]
               parameters:@{}
                  headers:@{}
            responseBlock:^(NSDictionary *dictionary, NSError *error) {
                block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
            }];
}

- (void) updateUserMetadata:(TelepatUserMetadata *)oldMetadata withUserMetadata:(TelepatUserMetadata *)newMetadata andBlock:(TelepatResponseBlock)block {
    NSDictionary *patch = [oldMetadata patchAgainst:newMetadata];
    [[Telepat client] post:[Telepat urlForEndpoint:@"/user/update_metadata"]
                parameters:patch
                   headers:@{}
             responseBlock:^(NSDictionary *dictionary, NSError *error) {
                 block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
             }];
}

- (void) setApiKey:(NSString *)apiKey {
    NSData *dataIn = [apiKey dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableData *dataOut = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(dataIn.bytes, (CC_LONG)dataIn.length, dataOut.mutableBytes);
    _apiKey = [[NSData dataWithData:dataOut] dataToHex];
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
        
        TelepatContext *context = [self contextWithIdentifier:ndict[@"subscription"]];
        if (context) {
            [self processNotification:createdTransportNotification];
            continue;
        }
        
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
        
        TelepatContext *context = [self contextWithIdentifier:ndict[@"subscription"]];
        if (context) {
            [self processNotification:updatedTransportNotification];
            continue;
        }
        
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
        
        TelepatContext *context = [self contextWithIdentifier:ndict[@"subscription"]];
        if (context) {
            [self processNotification:deletedTransportNotification];
            continue;
        }
        
        TelepatChannel *channel = [self channelWithSubscription:ndict[@"subscription"]];
        [channel processNotification:deletedTransportNotification];
    }
}

- (void) processNotification:(TelepatTransportNotification *)notification {
    switch (notification.type) {
        case TelepatNotificationTypeObjectAdded: {
            TelepatContext *context = [[TelepatContext alloc] initWithDictionary:notification.value error:nil];
            if ([_mServerContexts objectForKey:context.context_id] != nil) return;
            
            if (context) {
                [[NSNotificationCenter defaultCenter] postNotificationName:TelepatContextAdded object:context userInfo:@{kNotificationObject: context,
                                                                                                                      kNotificationOriginalContent: notification.value,
                                                                                                                      kNotificationOrigin: @(notification.origin)}];
                [_mServerContexts setObject:context forKey:context.context_id];
            }
            break;
        }
            
        case TelepatNotificationTypeObjectUpdated: {
            if (notification.value == nil || ([notification.value isKindOfClass:[NSString class]] && [notification.value length] == 0)) return;
            NSArray *pathComponents = [notification.path pathComponents];
            NSString *objectId = pathComponents[1];
            NSString *propertyName = pathComponents[2];
            TelepatContext *updatedContext = [_mServerContexts objectForKey:objectId];
            if (updatedContext == nil) return;
            NSString *transformedPropertyName = [[[updatedContext class] keyMapper] convertValue:propertyName isImportingToModel:NO];
            if ([updatedContext respondsToSelector:NSSelectorFromString(transformedPropertyName)] && [[updatedContext valueForKey:transformedPropertyName] isEqual:notification.value]) return;
            [updatedContext setValue:notification.value forProperty:transformedPropertyName];
            [[NSNotificationCenter defaultCenter] postNotificationName:TelepatContextUpdated object:updatedContext userInfo:@{kNotificationObject: updatedContext,
                                                                                                                    kNotificationOriginalContent: notification.value,
                                                                                                                    kNotificationPropertyName: transformedPropertyName,
                                                                                                                    kNotificationValue: notification.value,
                                                                                                                    kNotificationOrigin: @(notification.origin)}];
            break;
        }
            
        case TelepatNotificationTypeObjectDeleted: {
            NSArray *pathComponents = [notification.path pathComponents];
            NSString *objectId = pathComponents[1];
            TelepatContext *deletedContext = [_mServerContexts objectForKey:objectId];
            if (deletedContext == nil || deletedContext.context_id == nil) return;
            [_mServerContexts removeObjectForKey:deletedContext.context_id];
            [[NSNotificationCenter defaultCenter] postNotificationName:TelepatContextDeleted object:deletedContext userInfo:@{kNotificationObject: deletedContext,
                                                                                                                          kNotificationOrigin: @(notification.origin)}];
            break;
        }
            
        default:
            break;
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
