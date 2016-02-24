	//
//  KRRest.m
//  Kraken
//
//  Created by Ovidiu on 06/03/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "KRRest.h"
#import "NSString+MD5.h"
#import "Telepat.h"

#define DebugRequest(requestType) DDLogDebug(@"\n%@ %@\n%@\n%@\n----\nHTTP: %d\n%@\n", \
            requestType,\
            [url absoluteString], \
            manager.requestSerializer.HTTPRequestHeaders, \
            [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding], \
            response.statusCode, \
            responseObject)

#define DebugRequestError(requestType) DDLogDebug(@"\n%@ %@\n%@\n%@\n----\nHTTP: %d\n%@\n", \
                requestType, \
                [url absoluteString], \
                manager.requestSerializer.HTTPRequestHeaders, \
                [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding], \
                response.statusCode, \
                [[NSString alloc] initWithData:error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding])

@implementation KRRest

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

+ (instancetype) sharedClient {
    static KRRest *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[KRRest alloc] init];
    });
    return sharedClient;
}

- (AFHTTPSessionManager *) newManager {
    NSURL *url = [NSURL URLWithString:@"/" relativeToURL:[KRRest urlForEndpoint:@""]];
    return [[AFHTTPSessionManager alloc] initWithBaseURL:[url baseURL]];
}

#pragma mark Low level HTTP interface

- (NSDictionary *) mergedHeadersWithHeaders:(NSDictionary*)newHeaders {
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"kHTTPHeaders"]];
    [headers setObject:@"application/json" forKey:@"Content-Type"];
    self.device_id ? [headers setObject:self.device_id forKey:@"X-BLGREQ-UDID"] : [headers setObject:@"" forKey:@"X-BLGREQ-UDID"];
    if (self.bearer) [headers setObject:[NSString stringWithFormat:@"Bearer %@", self.bearer] forKey:@"Authorization"];
    if (self.api_key) [headers setObject:self.api_key forKey:@"X-BLGREQ-SIGN"];
    if (self.app_id) [headers setObject:self.app_id forKey:@"X-BLGREQ-APPID"];
    [headers addEntriesFromDictionary:newHeaders];
    return headers;
}

- (void) applyHeaders:(NSDictionary *)newHeaders forManager:(AFHTTPSessionManager *)manager {
    NSDictionary *headers = [self mergedHeadersWithHeaders:newHeaders];
    for (NSString *key in headers) {
        [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
    }
}

- (void) get:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block {
    AFHTTPSessionManager *manager = [self newManager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self applyHeaders:headers forManager:manager];
    
    [manager GET:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequest(@"GET");
        block([[KRResponse alloc] initWithDictionary:responseObject andStatus:response.statusCode]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequestError(@"GET");
        block([[KRResponse alloc] initWithError:error]);
    }];
}

- (void) post:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block {
    AFHTTPSessionManager *manager = [self newManager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self applyHeaders:headers forManager:manager];
    
    [manager POST:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequest(@"POST");
        block([[KRResponse alloc] initWithDictionary:responseObject andStatus:response.statusCode]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequestError(@"POST");
        block([[KRResponse alloc] initWithError:error]);
    }];
}

- (void) put:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block {
    AFHTTPSessionManager *manager = [self newManager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self applyHeaders:headers forManager:manager];
    
    [manager PUT:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequest(@"PUT");
        block([[KRResponse alloc] initWithDictionary:responseObject andStatus:response.statusCode]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequestError(@"PUT");
        block([[KRResponse alloc] initWithError:error]);
    }];
}

- (void) patch:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block {
    AFHTTPSessionManager *manager = [self newManager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self applyHeaders:headers forManager:manager];
    
    [manager PATCH:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequest(@"PATCH");
        block([[KRResponse alloc] initWithDictionary:responseObject andStatus:response.statusCode]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        DebugRequestError(@"PATCH");
        block([[KRResponse alloc] initWithError:error]);
    }];
}

- (void) sendProxiedRequest:(NSDictionary *)request withResponseBlock:(KRResponseBlock)block {
    AFHTTPSessionManager *manager = [self newManager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = nil;
    [self applyHeaders:@{} forManager:manager];
    
    [manager POST:@"/proxy" parameters:request success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        block([[KRResponse alloc] initWithData:responseObject andStatus:response.statusCode]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        block([[KRResponse alloc] initWithError:error]);
    }];
}

#pragma mark High level HTTP interface

- (void) registerDevice:(UIDevice *)device token:(NSString *)token update:(BOOL)update withBlock:(KRResponseBlock)block {
    NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionaryWithDictionary:@{@"os": [device systemName],
                                                                                          @"version": [device systemVersion],
                                                                                          @"manufacturer": @"Apple",
                                                                                          @"model": [device model]}];
    if (!update) infoDictionary[@"udid"] = [[device identifierForVendor] UUIDString];
    
    NSDictionary *persistentDictionary = @{@"type": @"ios",
                                           @"token": self.socketsEnabled ? @"" : token,
                                           @"active": self.socketsEnabled ? @(0) : @(1)};
    
    NSDictionary *volatileDictionary = @{@"type": @"sockets",
                                         @"token": self.socketsEnabled ? token : @"",
                                         @"active": self.socketsEnabled ? @(1) : @(0)};
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"info"] = [NSDictionary dictionaryWithDictionary:infoDictionary];
    params[@"volatile"] = volatileDictionary;
    params[@"persistent"] = persistentDictionary;
    
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/device/register"]
                     parameters:params
                        headers:@{}
                  responseBlock:block];
}

- (void) registerUserWithFacebookToken:(NSString *)token andBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/register-facebook"]
                     parameters:@{@"access_token": token}
                        headers:@{}
                  responseBlock:block];
}

- (void) registerUserWithTwitterToken:(NSString *)authToken secret:(NSString *)authSecret andBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/register-twitter"]
                     parameters:@{@"oauth_token": authToken,
                                  @"oauth_token_secret": authSecret}
                        headers:@{}
                  responseBlock:block];
}

- (void) registerUser:(NSString *)username withPassword:(NSString *)password name:(NSString *)name andBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/register-username"]
                     parameters:@{@"username": username,
                                  @"email": username,
                                  @"password": password,
                                  @"name": name}
                        headers:@{}
                  responseBlock:block];
}

- (void) registerUser:(NSDictionary *)userDict withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/register-username"]
                     parameters:userDict
                        headers:@{}
                  responseBlock:block];
}

- (void) adminDeleteUser:(NSString *)username withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/user/delete"]
                     parameters:@{@"username": username}
                        headers:@{}
                  responseBlock:block];
}

- (void) adminUpdateUser:(NSDictionary *)patch withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/user/update"]
                     parameters:patch
                        headers:@{}
                  responseBlock:block];
}

- (void) deleteUserWithID:(NSString *)userId andUsername:(NSString *)username andBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/delete"]
                     parameters:@{@"id": userId,
                                  @"username": username}
                        headers:@{}
                  responseBlock:block];
}

- (void) updateUser:(NSDictionary *)patch withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/update"]
                     parameters:patch
                        headers:@{}
                  responseBlock:block];
}

- (void) loginWithFacebookToken:(NSString*)token andBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/login-facebook"]
                     parameters:@{@"access_token": token}
                        headers:@{}
                  responseBlock:block];
}

- (void) loginWithTwitterToken:(NSString*)authToken secret:(NSString *)authSecret andBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/login-twitter"]
                     parameters:@{@"oauth_token": authToken,
                                  @"oauth_token_secret": authSecret}
                        headers:@{}
                  responseBlock:block];
}

- (void) loginWithUsername:(NSString *)username andPassword:(NSString *)password withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/login_password"]
                     parameters:@{@"username": username,
                                  @"password": password}
                        headers:@{}
                  responseBlock:block];
}

- (void) requestPasswordResetForUsername:(NSString*)username withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/request_password_reset"]
                     parameters:@{@"type": @"app",
                                  @"username": username}
                        headers:@{}
                  responseBlock:block];
}

- (void) resetPasswordWithToken:(NSString *)token forUserID:(NSString *)userID newPassword:(NSString *)newPassword withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/password_reset"]
                     parameters:@{@"token": token,
                                  @"user_id": userID,
                                  @"password": newPassword}
                        headers:@{}
                  responseBlock:block];
}

- (void) adminLoginWithUsername:(NSString *)username andPassword:(NSString *)password withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/login"]
                     parameters:@{@"email": username,
                                  @"password": password}
                        headers:@{}
                  responseBlock:block];
}

- (void) adminAuthorizeWithUsername:(NSString *)username andBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/app/authorize"]
                     parameters:@{@"email": username}
                        headers:@{}
                  responseBlock:block];
}

- (void) adminDeauthorizeWithUsername:(NSString *)username andBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/app/deauthorize"]
                     parameters:@{@"email": username}
                        headers:@{}
                  responseBlock:block];
}

- (void) adminAddWithUsername:(NSString *)username password:(NSString *)password name:(NSString *)name withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/add"]
                     parameters:@{@"email": username,
                                  @"password": password,
                                  @"name": name}
                        headers:@{}
                  responseBlock:block];
}

- (void) adminDeleteWithBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/delete"]
                     parameters:@{}
                        headers:@{}
                  responseBlock:block];
}

- (void) updateAdmin:(NSDictionary *)patch withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/update"]
                     parameters:patch
                        headers:@{}
                  responseBlock:block];
}

- (void) logoutWithBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/logout"]
                     parameters:@{}
                        headers:@{}
                  responseBlock:block];
}

- (void) updateContextsWithBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] get:[KRRest urlForEndpoint:@"/context/all"]
                    parameters:@{}
                       headers:@{}
                 responseBlock:block];
}

- (void) appCreate:(NSString *)appName apiKeys:(NSArray *)keys customFields:(NSDictionary *)fields withBlock:(KRResponseBlock)block {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:fields];
    params[@"name"] = appName;
    params[@"keys"] = keys;
    
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/app/add"]
                     parameters:[NSDictionary dictionaryWithDictionary:params]
                        headers:@{}
                  responseBlock:block];
}

- (void) updateApp:(NSDictionary *)patch withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/app/update"]
                     parameters:patch
                        headers:@{}
                  responseBlock:block];
}

- (void) listAppsWithBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] get:[KRRest urlForEndpoint:@"/admin/apps"]
                    parameters:@{}
                       headers:@{}
                 responseBlock:block];
}

- (void) listAppUsersWithBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] get:[KRRest urlForEndpoint:@"/admin/user/all"]
                    parameters:@{}
                       headers:@{}
                 responseBlock:block];
}

- (void) removeAppWithBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/app/remove"]
                     parameters:@{}
                        headers:@{}
                  responseBlock:block];
}

- (void) removeAppModel:(NSString *)modelName withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/schema/remove_model"]
                     parameters:@{}
                        headers:@{}
                  responseBlock:block];
}

- (void) removeContext:(NSString *)contextId withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/context/remove"]
                     parameters:@{@"id": contextId}
                        headers:@{}
                  responseBlock:block];
}

- (void) createContext:(NSString *)name meta:(NSDictionary *)meta withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/context/add"]
                     parameters:@{@"name": name,
                                  @"meta": meta}
                        headers:@{}
                  responseBlock:block];
}

- (void) getContext:(NSString *)contextId withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/context"]
                     parameters:@{@"id": contextId}
                        headers:@{}
                  responseBlock:block];
}

- (void) getContextsWithBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] get:[KRRest urlForEndpoint:@"/admin/contexts"]
                    parameters:@{}
                       headers:@{}
                 responseBlock:block];
}

- (void) updateContext:(NSDictionary *)patch withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/context/update"]
                     parameters:patch
                        headers:@{}
                  responseBlock:block];
}

- (void) getSchemasWithBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] get:[KRRest urlForEndpoint:@"/admin/schema/all"]
                    parameters:@{}
                       headers:@{}
                 responseBlock:block];
}

- (void) updateSchema:(NSDictionary *)patch withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/admin/schema/update"]
                     parameters:patch
                        headers:@{}
                  responseBlock:block];
}

- (void) getCurrentAdminWithBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] get:[KRRest urlForEndpoint:@"/admin/me"]
                    parameters:@{}
                       headers:@{}
                 responseBlock:block];
}

- (void) getCurrentUserWithBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] get:[KRRest urlForEndpoint:@"/user/me"]
                    parameters:@{}
                       headers:@{}
                 responseBlock:block];
}

- (void) getUserMetadataWithBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] get:[KRRest urlForEndpoint:@"/user/metadata"]
                    parameters:@{}
                       headers:@{}
                 responseBlock:block];
}

- (void) updateUserMetadata:(NSDictionary *)patch withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/update_metadata"]
                     parameters:patch
                        headers:@{}
                  responseBlock:block];
}

- (void) refreshTokenWithBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] get:[KRRest urlForEndpoint:@"/user/refresh_token"]
                    parameters:@{}
                       headers:@{}
                 responseBlock:block];
}

- (void) create:(id)body withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/object/create"]
                     parameters:body
                        headers:@{}
                  responseBlock:block];
}

- (void) update:(id)body withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/object/update"]
                     parameters:body
                        headers:@{}
                  responseBlock:block];
}

- (void) count:(id)body withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/object/count"]
                     parameters:body
                        headers:@{}
                  responseBlock:block];
}

@end
