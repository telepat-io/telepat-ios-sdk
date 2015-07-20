//
//  KRRest.m
//  Kraken
//
//  Created by Ovidiu on 06/03/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "KRRest.h"

@implementation KRRest

+ (NSURL *) urlForEndpoint:(NSString*) endpoint {
    if ([endpoint hasPrefix:@"/"]) endpoint = [endpoint substringFromIndex:1];
    NSString *apiBaseURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"kApiURL"];
    if (![apiBaseURL hasSuffix:@"/"]) apiBaseURL = [NSString stringWithFormat:@"%@/", apiBaseURL];
    NSString *finalURL = [NSString stringWithFormat:@"%@%@", apiBaseURL, endpoint];
    
    return [NSURL URLWithString:finalURL];
}

+ (instancetype) sharedClient {
    static KRRest *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[KRRest alloc] init];
        
        NSURL *url = [NSURL URLWithString:@"/" relativeToURL:[self urlForEndpoint:@""]];
        sharedClient.manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[url baseURL]];
    });
    return sharedClient;
}

#pragma mark Low level HTTP interface

- (NSDictionary *) mergedHeadersWithHeaders:(NSDictionary*)newHeaders {
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"kHTTPHeaders"]];
    [headers setObject:@"application/json" forKey:@"Content-Type"];
    self.device_id ? [headers setObject:self.device_id forKey:@"X-BLGREQ-UDID"] : [headers setObject:@"" forKey:@"X-BLGREQ-UDID"];
    if (self.bearer) [headers setObject:[NSString stringWithFormat:@"Bearer %@", self.bearer] forKey:@"Authorization"];
    if (self.api_key) [headers setObject:self.api_key forKey:@"X-BLGREQ-SIGN"];
    [headers addEntriesFromDictionary:newHeaders];
    return headers;
}

- (void) applyHeaders:(NSDictionary *)newHeaders {
    NSDictionary *headers = [self mergedHeadersWithHeaders:newHeaders];
    for (NSString *key in headers) {
        [self.manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
    }
}

- (void) get:(NSURL*)url parameters:(NSDictionary*)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block {
    self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self applyHeaders:headers];
    
    [self.manager GET:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        block([[KRResponse alloc] initWithDictionary:responseObject andStatus:response.statusCode]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        block([[KRResponse alloc] initWithError:error]);
    }];
}

- (void) post:(NSURL*)url parameters:(NSDictionary*)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block {
    self.manager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self applyHeaders:headers];
    
    [self.manager POST:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        block([[KRResponse alloc] initWithDictionary:responseObject andStatus:response.statusCode]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        block([[KRResponse alloc] initWithError:error]);
    }];
}

- (void) put:(NSURL*)url parameters:(NSDictionary*)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block {
    self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self applyHeaders:headers];
    
    [self.manager PUT:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        block([[KRResponse alloc] initWithDictionary:responseObject andStatus:response.statusCode]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        block([[KRResponse alloc] initWithError:error]);
    }];
}

- (void) patch:(NSURL*)url parameters:(NSDictionary*)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block {
    self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self applyHeaders:headers];
    
    [self.manager PATCH:[url path] parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        block([[KRResponse alloc] initWithDictionary:responseObject andStatus:response.statusCode]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        block([[KRResponse alloc] initWithError:error]);
    }];
}

#pragma mark High level HTTP interface

- (void) registerDevice:(UIDevice *)device token:(NSString *)token withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/device/register"]
                     parameters:@{@"info": @{@"os": [device systemName],
                                             @"version": [device systemVersion],
                                             @"manufacturer": @"Apple",
                                             @"model": [device model],
                                             @"udid": [[device identifierForVendor] UUIDString]},
                                  @"persistent": @{@"type": @"ios",
                                                   @"token": token}
                                  }
                        headers:@{}
                  responseBlock:block];
}

- (void) loginWithToken:(NSString*)token andBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/user/login"]
                     parameters:@{@"access_token": token}
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

- (void) create:(NSDictionary *)body withBlock:(KRResponseBlock)block {
    [[KRRest sharedClient] post:[KRRest urlForEndpoint:@"/object/create"]
                     parameters:body
                        headers:@{}
                  responseBlock:block];
}

@end
