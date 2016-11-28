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
        if (block) block(nil, error);
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

- (void) performRequestOfType:(NSString *)requestType withURL:(NSURL *)url params:(NSDictionary *)params headers:(NSDictionary *)headers andBlock:(HTTPResponseBlock)block {
    HTTPResponseBlock responseBlock = ^void (NSDictionary *dictionary, NSError *error) {
        if (error) {
            NSData *errorResponseData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            if (errorResponseData) {
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:errorResponseData options:0 error:nil];
                if (jsonDict && [jsonDict[@"code"] isEqualToString:@"046"]) {
                    [self refreshTokenWithBlock:^(TelepatResponse *response) {
                        [self performRequestOfType:requestType withURL:url params:params headers:headers andBlock:block];
                    }];
                } else {
                    block(nil, error);
                }
            } else {
                block(nil, error);
            }
        } else {
            block(dictionary, error);
        }
    };
    
    if ([requestType isEqualToString:@"GET"]) {
        [self get:url parameters:params headers:headers responseBlock:responseBlock];
    } else if ([requestType isEqualToString:@"POST"]) {
        [self post:url parameters:params headers:headers responseBlock:responseBlock];
    } else if ([requestType isEqualToString:@"PUT"]) {
        [self put:url parameters:params headers:headers responseBlock:responseBlock];
    } else if ([requestType isEqualToString:@"PATCH"]) {
        [self patch:url parameters:params headers:headers responseBlock:responseBlock];
    } else if ([requestType isEqualToString:@"DELETE"]) {
        [self delete:url parameters:params headers:headers responseBlock:responseBlock];
    }
}

- (void) registerDeviceForWebsocketsWithBlock:(TelepatResponseBlock)block shouldUpdateBackend:(BOOL)shouldUpdateBackend {
    NSString *udid = [_dbInstance getOperationsDataForKey:kUDID defaultValue:@""];
    if ([udid length] && !shouldUpdateBackend) {
        block(nil);
        return;
    }
    UIDevice *device = [UIDevice currentDevice];
    NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionaryWithDictionary:@{@"os": [device systemName],
                                                                                          @"version": [device systemVersion],
                                                                                          @"manufacturer": @"Apple",
                                                                                          @"model": [device model]}];
    NSDictionary *volatileDictionary = @{@"type": @"sockets",
                                         @"token": [NSNull null],
                                         @"active": @(1)};
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"info"] = [NSDictionary dictionaryWithDictionary:infoDictionary];
    params[@"volatile"] = volatileDictionary;
    
    self.updatesTransportType = TelepatUpdatesTransportTypeSockets;
    
    if ([udid length]) {
        infoDictionary[@"udid"] = [[device identifierForVendor] UUIDString];
        self.deviceId = udid;
    }
    
    [self performRequestOfType:@"POST"
                       withURL:[Telepat urlForEndpoint:@"/device/register"]
                        params:params
                       headers:@{}
                      andBlock:^(NSDictionary *dictionary, NSError *error) {
                          TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithDictionary:dictionary error:error];
                          if (![registerResponse isError]) {
                              TelepatDeviceIdentifier *deviceIdentifier = [registerResponse getObjectOfType:[TelepatDeviceIdentifier class]];
                              if (deviceIdentifier.identifier) {
                                  self.deviceId = deviceIdentifier.identifier;
                                  [_dbInstance setOperationsDataWithObject:deviceIdentifier.identifier forKey:kUDID];
                              }
                              [[TelepatWebsocketTransport sharedClient] connect:[Telepat socketURL] withBlock:^() {
                                  block(registerResponse);
                              }];
                          } else {
                              NSLog(@"register response: %@", registerResponse);
                          }
                      }];
}

- (void) registerDeviceWithToken:(NSString*)token withBlock:(TelepatResponseBlock)block {
    [self registerDeviceWithToken:token shouldUpdateBackend:NO withBlock:block];
}

- (void) registerDeviceWithToken:(NSString*)token shouldUpdateBackend:(BOOL)shouldUpdateBackend withBlock:(TelepatResponseBlock)block {
    NSString *udid = [_dbInstance getOperationsDataForKey:kUDID defaultValue:@""];
    
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
                                           @"token": token,
                                           @"active": @(1)};
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"info"] = [NSDictionary dictionaryWithDictionary:infoDictionary];
    params[@"persistent"] = persistentDictionary;
    
    self.updatesTransportType = TelepatUpdatesTransportTypeiOS;
    
    if ([udid length]) {
        infoDictionary[@"udid"] = [[device identifierForVendor] UUIDString];
        self.deviceId = udid;
    }
    
    [self performRequestOfType:@"POST"
                       withURL:[Telepat urlForEndpoint:@"/device/register"]
                        params:params
                       headers:@{}
                      andBlock:^(NSDictionary *dictionary, NSError *error) {
                          TelepatResponse *registerResponse = [[TelepatResponse alloc] initWithDictionary:dictionary error:error];
                          if (![registerResponse isError]) {
                              TelepatDeviceIdentifier *deviceIdentifier = [registerResponse getObjectOfType:[TelepatDeviceIdentifier class]];
                              if (deviceIdentifier.identifier) {
                                  self.deviceId = deviceIdentifier.identifier;
                                  [_dbInstance setOperationsDataWithObject:deviceIdentifier.identifier forKey:kUDID];
                              }
                          }
                          block(registerResponse);
                      }];
}

- (void) registerFacebookUserWithToken:(NSString *)token andBlock:(TelepatResponseBlock)block {
    [self performRequestOfType:@"POST"
                       withURL:[Telepat urlForEndpoint:@"/user/register-facebook"]
                        params:@{@"access_token": token}
                       headers:@{}
                      andBlock:^(NSDictionary *dictionary, NSError *error) {
                          block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                      }];
}

- (void) registerTwitterUserWithToken:(NSString *)token secret:(NSString *)secret andBlock:(TelepatResponseBlock)block {
    [self performRequestOfType:@"POST"
                       withURL:[Telepat urlForEndpoint:@"/user/register-twitter"]
                        params:@{@"oauth_token": token, @"oauth_token_secret": secret}
                       headers:@{}
                      andBlock:^(NSDictionary *dictionary, NSError *error) {
                          block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                      }];
}

- (void) registerUser:(NSString *)username withPassword:(NSString *)password name:(NSString *)name andBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/user/register-username"]
                                    params:@{@"username": username,
                                             @"password": password,
                                             @"name": name,
                                             @"callbackUrl": [NSString stringWithFormat:@"telepat-%@://reset-password", self.appId]}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) registerUser:(TelepatUser *)user withBlock:(TelepatResponseBlock)block {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[user toDictionary]];
    params[@"callbackUrl"] = [NSString stringWithFormat:@"telepat-%@://reset-password", self.appId];
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/user/register-username"]
                                    params:[NSDictionary dictionaryWithDictionary:params]
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) adminDeleteUser:(NSString *)username withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/user/delete"]
                                    params:@{@"username": username}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) adminUpdateUser:(TelepatUser *)oldUser withUser:(TelepatUser *)newUser andBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/user/update"]
                                    params:[oldUser patchAgainst:newUser]
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) refreshTokenWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] get:[Telepat urlForEndpoint:@"/user/refresh_token"]
               parameters:@{}
                  headers:@{}
            responseBlock:^(NSDictionary *dictionary, NSError *error) {
                TelepatResponse *loginResponse = [[TelepatResponse alloc] initWithDictionary:dictionary error:error];
                if (![loginResponse isError]) {
                    TelepatAuthorization *tokenObj = [loginResponse getObjectOfType:[TelepatAuthorization class]];
                    [_dbInstance setOperationsDataWithObject:tokenObj forKey:kJWT];
                    [_dbInstance setOperationsDataWithObject:[NSDate date] forKey:kJWT_TIMESTAMP];
                    self.bearer = tokenObj.token;
                }
                block(loginResponse);
            }];
}

- (void) deleteUser:(TelepatUser *)user withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/user/delete"]
                                    params:@{@"id": user.user_id,
                                             @"username": user.username}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) updateUser:(TelepatUser *)oldUser withUser:(TelepatUser *)newUser andBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/user/update"]
                                    params:[oldUser patchAgainst:newUser]
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) listAppUsersWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"GET"
                                   withURL:[Telepat urlForEndpoint:@"/admin/user/all"]
                                    params:@{}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) loginWithFacebook:(NSString *)token andBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/user/login-facebook"]
                                    params:@{@"access_token": token}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      [self processLoginResponse:[[TelepatResponse alloc] initWithDictionary:dictionary error:error] withBlock:block];
                                  }];
}

- (void) loginWithTwitter:(NSString *)authToken secret:(NSString *)authSecret andBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/user/login-twitter"]
                                    params:@{@"oauth_token": authToken,
                                             @"oauth_token_secret": authSecret}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      [self processLoginResponse:[[TelepatResponse alloc] initWithDictionary:dictionary error:error] withBlock:block];
                                  }];
}

- (void) login:(NSString *)username password:(NSString *)password withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/user/login_password"]
                                    params:@{@"username": username,
                                             @"password": password}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      [self processLoginResponse:[[TelepatResponse alloc] initWithDictionary:dictionary error:error] withBlock:block];
                                  }];
}

- (void) requestPasswordResetForUsername:(NSString *)username withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/user/request_password_reset"]
                                    params:@{@"type": @"app",
                                             @"username": username,
                                             @"callbackUrl": [NSString stringWithFormat:@"telepat-%@://reset-password", self.appId]}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) resetPasswordWithToken:(NSString *)token forUserID:(NSString *)userID newPassword:(NSString *)newPassword withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/user/password_reset"]
                                    params:@{@"token": token,
                                             @"user_id": userID,
                                             @"password": newPassword}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) linkAccountWithFacebook:(NSString *)username token:(NSString *)token withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/user/login-facebook"]
                                    params:@{@"access_token": token,
                                             @"username": username}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) adminLogin:(NSString *)username password:(NSString *)password withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/login"]
                                    params:@{@"email": username,
                                             @"password": password}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) authorizeAdmin:(NSString *)username withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/app/authorize"]
                                    params:@{@"email": username}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) deauthorizeAdmin:(NSString *)username withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/app/deauthorize"]
                                    params:@{@"email": username}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) adminAdd:(NSString *)username password:(NSString *)password name:(NSString *)name withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/add"]
                                    params:@{@"email": username,
                                             @"password": password,
                                             @"name": name}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) deleteAdminWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/delete"]
                                    params:@{}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) updateAdmin:(TelepatUser *)oldAdmin withUser:(TelepatUser *)newAdmin andBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/update"]
                                    params:[oldAdmin patchAgainst:newAdmin]
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
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
    
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/user/logout"]
                                    params:@{}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
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
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/object/create"]
                                    params:@{@"model": modelName,
                                             @"context": context.context_id,
                                             @"content": [object toDictionary]}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      if (block) block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
    return object.uuid;
}

- (void) updateObject:(TelepatBaseObject *)oldObject withObject:(TelepatBaseObject *)newObject withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/object/update"]
                                    params:[oldObject patchAgainst:newObject]
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      if (block) block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) count:(id)body withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/object/count"]
                                    params:body
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (TelepatChannel *) subscribe:(TelepatContext *)context modelName:(NSString *)modelName classType:(Class)classType withBlock:(TelepatResponseBlock)block {
    return [self subscribe:context modelName:modelName classType:classType filter:nil range:NSMakeRange(0, INT_MAX) withBlock:block];
}

- (TelepatChannel *) subscribe:(TelepatContext *)context modelName:(NSString *)modelName classType:(Class)classType filter:(TelepatOperatorFilter*)filter range:(NSRange)range withBlock:(TelepatResponseBlock)block {
    if (![classType isSubclassOfClass:[TelepatBaseObject class]])
        @throw([NSException exceptionWithName:kTelepatInvalidClass reason:@"classType parameter must be a subclass of TelepatBaseObject" userInfo:@{@"classType": classType}]);
    
    TelepatChannel *channel = [[TelepatChannel alloc] initWithModelName:modelName context:context objectType:classType];
    if (filter) channel.opFilter = filter;
    [channel subscribeWithRange:range withBlock:^(TelepatResponse *response) {
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
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/context/add"]
                                    params:@{@"name": name,
                                             @"meta": meta}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) getContext:(NSString *)contextId withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/context"]
                                    params:@{@"id": contextId}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) getContextsWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/context/all"]
                                    params:@{}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) getContextsWithRange:(NSRange)range andBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/context/all"]
                                    params:@{@"offset": @(range.location),
                                             @"limit": @(range.length)}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) getSchemasWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"GET"
                                   withURL:[Telepat urlForEndpoint:@"/admin/schema/all"]
                                    params:@{}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) updateSchema:(NSDictionary *)schema withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/schema/update"]
                                    params:schema
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) getCurrentAdminWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"GET"
                                   withURL:[Telepat urlForEndpoint:@"/admin/me"]
                                    params:@{}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) getCurrentUserWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"GET"
                                   withURL:[Telepat urlForEndpoint:@"/user/me"]
                                    params:@{}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
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
    
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/app/add"]
                                    params:[NSDictionary dictionaryWithDictionary:params]
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) listAppsWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"GET"
                                   withURL:[Telepat urlForEndpoint:@"/admin/apps"]
                                    params:@{}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) removeAppWithBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/app/remove"]
                                    params:@{}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) updateApp:(TelepatApp *)oldApp withApp:(TelepatApp *)newApp andBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/app/update"]
                                    params:[oldApp patchAgainst:newApp]
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) removeAppModel:(NSString *)modelName withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/schema/remove_model"]
                                    params:@{}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) removeContext:(NSString *)contextId withBlock:(TelepatResponseBlock)block {
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/context/remove"]
                                    params:@{@"id": contextId}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) updateContext:(TelepatContext *)oldContext withContext:(TelepatContext *)newContext andBlock:(TelepatResponseBlock)block {
    NSMutableDictionary *mutablePatch = [NSMutableDictionary dictionaryWithDictionary:[oldContext patchAgainst:newContext]];
    mutablePatch[@"id"] = oldContext.context_id;
    
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/admin/context/update"]
                                    params:[NSDictionary dictionaryWithDictionary:mutablePatch]
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
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
    [[Telepat client] performRequestOfType:@"GET"
                                   withURL:[Telepat urlForEndpoint:@"/user/metadata"]
                                    params:@{}
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) updateUserMetadata:(TelepatUserMetadata *)oldMetadata withUserMetadata:(TelepatUserMetadata *)newMetadata andBlock:(TelepatResponseBlock)block {
    NSDictionary *patch = [oldMetadata patchAgainst:newMetadata];
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/user/update_metadata"]
                                    params:patch
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
                                      block([[TelepatResponse alloc] initWithDictionary:dictionary error:error]);
                                  }];
}

- (void) sendEmailToRecipients:(NSArray *)recipients from:(NSString *)from fromName:(NSString *)fromName subject:(NSString *)subject body:(NSString *)body withBlock:(TelepatResponseBlock)block {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"recipients"] = recipients;
    params[@"from"] = from;
    if (fromName) params[@"fromName"] = fromName;
    if (subject) params[@"subject"] = subject;
    params[@"body"] = body;
    
    [[Telepat client] performRequestOfType:@"POST"
                                   withURL:[Telepat urlForEndpoint:@"/email"]
                                    params:[NSDictionary dictionaryWithDictionary:params]
                                   headers:@{}
                                  andBlock:^(NSDictionary *dictionary, NSError *error) {
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
        TelepatTransportNotification *createdTransportNotification = [TelepatTransportNotification notificationFromDictionary:ndict withOrigin:origin];
        
        if ([createdTransportNotification.value isKindOfClass:[NSDictionary class]]
            && [createdTransportNotification.value[@"type"] isEqualToString:@"context"]
            && !createdTransportNotification.value[@"context_id"]) {
                // This is a new context
                [self processNotification:createdTransportNotification];
                continue;
        }
        
        for (NSString *subscriptionId in ndict[@"subscriptions"]) {
            TelepatChannel *channel = [self channelWithSubscription:subscriptionId];
            [channel processNotification:createdTransportNotification];
        }
    }
    
    // process "updated" notifications
    for (NSDictionary *ndict in data[@"updated"]) {
        TelepatTransportNotification *updatedTransportNotification = [TelepatTransportNotification notificationFromDictionary:ndict withOrigin:origin];
        
        NSMutableSet *affectedSubscriptionsSet = [NSMutableSet setWithArray:ndict[@"subscriptions"]];
        if ([affectedSubscriptionsSet intersectsSet:[NSSet setWithArray:[_mServerContexts.allValues valueForKey:@"contextIdentifier"]]]) {
            [self processNotification:updatedTransportNotification];
            continue;
        }
        
        for (NSString *subscriptionId in ndict[@"subscriptions"]) {
            TelepatChannel *channel = [self channelWithSubscription:subscriptionId];
            [channel processNotification:updatedTransportNotification];
        }
    }
    
    // process "deleted" notifications
    for (NSDictionary *ndict in data[@"deleted"]) {
        TelepatTransportNotification *deletedTransportNotification = [TelepatTransportNotification notificationFromDictionary:ndict withOrigin:origin];
        
        NSMutableSet *affectedSubscriptionsSet = [NSMutableSet setWithArray:ndict[@"subscriptions"]];
        if ([affectedSubscriptionsSet intersectsSet:[NSSet setWithArray:[_mServerContexts.allValues valueForKey:@"contextIdentifier"]]]) {
            [self processNotification:deletedTransportNotification];
            continue;
        }
        
        for (NSString *subscriptionId in ndict[@"subscriptions"]) {
            TelepatChannel *channel = [self channelWithSubscription:subscriptionId];
            [channel processNotification:deletedTransportNotification];
        }
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
            TelepatContext *deletedContext = [_mServerContexts objectForKey:notification.value[@"id"]];
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
