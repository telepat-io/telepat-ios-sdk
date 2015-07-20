//
//  KRRest.h
//  Kraken
//
//  Created by Ovidiu on 06/03/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "KRResponse.h"

typedef void (^KRResponseBlock)(KRResponse *response);

@interface KRRest : NSObject

@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) NSString *device_id;
@property (nonatomic, strong) NSString *bearer;
@property (nonatomic, strong) NSString *api_key;

+ (instancetype) sharedClient;
+ (NSURL *) urlForEndpoint:(NSString*) endpoint;

- (void) get:(NSURL*)url parameters:(NSDictionary*)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;
- (void) post:(NSURL*)url parameters:(NSDictionary*)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;
- (void) put:(NSURL*)url parameters:(NSDictionary*)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;
- (void) patch:(NSURL*)url parameters:(NSDictionary*)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;

- (void) registerDevice:(UIDevice *)device token:(NSString *)token withBlock:(KRResponseBlock)block;
- (void) loginWithToken:(NSString*)token andBlock:(KRResponseBlock)block;
- (void) logoutWithBlock:(KRResponseBlock)block;
- (void) updateContextsWithBlock:(KRResponseBlock)block;
- (void) create:(NSDictionary *)body withBlock:(KRResponseBlock)block;

@end
