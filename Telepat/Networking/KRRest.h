//
//  KRRest.h
//  Kraken
//
//  Created by Ovidiu on 06/03/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AFNetworking.h"
#import "KRResponse.h"

#define kTelepatAPIURL @"kTelepatAPIURL"

typedef void (^KRResponseBlock)(KRResponse *response);

@interface KRRest : NSObject

@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) NSString *device_id;
@property (nonatomic, strong) NSString *bearer;
@property (nonatomic, strong) NSString *api_key;
@property (nonatomic, strong) NSString *app_id;
@property (nonatomic) BOOL socketsEnabled;

+ (instancetype) sharedClient;
+ (NSURL *) urlForEndpoint:(NSString*) endpoint;
+ (NSURL *) socketURL;

- (void) get:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;
- (void) post:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;
- (void) put:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;
- (void) patch:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;

- (void) registerDevice:(UIDevice *)device token:(NSString *)token update:(BOOL)update withBlock:(KRResponseBlock)block;
- (void) registerUserWithFacebookToken:(NSString *)token andBlock:(KRResponseBlock)block;
- (void) registerUserWithTwitterToken:(NSString *)authToken secret:(NSString *)authSecret andBlock:(KRResponseBlock)block;
- (void) registerUser:(NSString *)username withPassword:(NSString *)password name:(NSString *)name andBlock:(KRResponseBlock)block;
- (void) loginWithFacebookToken:(NSString*)token andBlock:(KRResponseBlock)block;
- (void) loginWithTwitterToken:(NSString*)authToken secret:(NSString *)authSecret andBlock:(KRResponseBlock)block;
- (void) loginWithUsername:(NSString *)username andPassword:(NSString *)password withBlock:(KRResponseBlock)block;
- (void) adminLoginWithUsername:(NSString *)username andPassword:(NSString *)password withBlock:(KRResponseBlock)block;
- (void) adminAuthorizeWithUsername:(NSString *)username andBlock:(KRResponseBlock)block;
- (void) adminDeauthorizeWithUsername:(NSString *)username andBlock:(KRResponseBlock)block;
- (void) adminAddWithUsername:(NSString *)username password:(NSString *)password name:(NSString *)name withBlock:(KRResponseBlock)block;
- (void) adminDeleteWithBlock:(KRResponseBlock)block;
- (void) updateAdmin:(NSDictionary *)patch withBlock:(KRResponseBlock)block;
- (void) deleteUser:(NSString *)username withBlock:(KRResponseBlock)block;
- (void) updateUser:(NSDictionary *)patch withBlock:(KRResponseBlock)block;
- (void) logoutWithBlock:(KRResponseBlock)block;
- (void) updateContextsWithBlock:(KRResponseBlock)block;
- (void) create:(id)body withBlock:(KRResponseBlock)block;
- (void) update:(id)body withBlock:(KRResponseBlock)block;
- (void) count:(id)body withBlock:(KRResponseBlock)block;
- (void) appCreate:(NSString *)appName apiKeys:(NSArray *)keys customFields:(NSDictionary *)fields withBlock:(KRResponseBlock)block;
- (void) updateApp:(NSDictionary *)patch withBlock:(KRResponseBlock)block;
- (void) listAppsWithBlock:(KRResponseBlock)block;
- (void) listAppUsersWithBlock:(KRResponseBlock)block;
- (void) removeAppWithBlock:(KRResponseBlock)block;
- (void) removeAppModel:(NSString *)modelName withBlock:(KRResponseBlock)block;
- (void) removeContext:(NSString *)contextId withBlock:(KRResponseBlock)block;
- (void) createContext:(NSString *)name meta:(NSDictionary *)meta withBlock:(KRResponseBlock)block;
- (void) getContext:(NSString *)contextId withBlock:(KRResponseBlock)block;
- (void) getContextsWithBlock:(KRResponseBlock)block;
- (void) updateContext:(NSDictionary *)dictionary withBlock:(KRResponseBlock)block;
- (void) getSchemasWithBlock:(KRResponseBlock)block;
- (void) updateSchema:(NSDictionary *)patch withBlock:(KRResponseBlock)block;
- (void) getMeWithBlock:(KRResponseBlock)block;

@end
