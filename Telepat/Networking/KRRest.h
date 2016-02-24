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
#define kTelepatWebSocketsURL @"kTelepatWebSocketsURL"

typedef void (^KRResponseBlock)(KRResponse *response);

@interface KRRest : NSObject

@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) NSString *device_id;
@property (nonatomic, strong) NSString *bearer;
@property (nonatomic, strong) NSString *api_key;
@property (nonatomic, strong) NSString *app_id;

+ (instancetype) sharedClient;
+ (NSURL *) urlForEndpoint:(NSString*) endpoint;
+ (NSURL *) socketURL;

- (void) get:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;
- (void) post:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;
- (void) put:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;
- (void) patch:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;

- (void) registerDevice:(UIDevice *)device token:(NSString *)token update:(BOOL)update withBlock:(KRResponseBlock)block;
- (void) registerDeviceWithWebsockets:(UIDevice *)device token:(NSString *)token serverName:(NSString *)serverName update:(BOOL)update withBlock:(KRResponseBlock)block;
- (void) registerUserWithFacebookToken:(NSString *)token andBlock:(KRResponseBlock)block;
- (void) registerUserWithTwitterToken:(NSString *)authToken secret:(NSString *)authSecret andBlock:(KRResponseBlock)block;
- (void) registerUser:(NSString *)username withPassword:(NSString *)password name:(NSString *)name andBlock:(KRResponseBlock)block;
- (void) registerUser:(NSDictionary *)userDict withBlock:(KRResponseBlock)block;
- (void) loginWithFacebookToken:(NSString*)token andBlock:(KRResponseBlock)block;
- (void) loginWithTwitterToken:(NSString*)authToken secret:(NSString *)authSecret andBlock:(KRResponseBlock)block;
- (void) loginWithUsername:(NSString *)username andPassword:(NSString *)password withBlock:(KRResponseBlock)block;
- (void) requestPasswordResetForUsername:(NSString*)username withBlock:(KRResponseBlock)block;
- (void) resetPasswordWithToken:(NSString *)token forUserID:(NSString *)userID newPassword:(NSString *)newPassword withBlock:(KRResponseBlock)block;
- (void) adminLoginWithUsername:(NSString *)username andPassword:(NSString *)password withBlock:(KRResponseBlock)block;
- (void) adminAuthorizeWithUsername:(NSString *)username andBlock:(KRResponseBlock)block;
- (void) adminDeauthorizeWithUsername:(NSString *)username andBlock:(KRResponseBlock)block;
- (void) adminGetContext:(NSString *)contextId withBlock:(KRResponseBlock)block;
- (void) adminGetContextsWithBlock:(KRResponseBlock)block;
- (void) adminGetContextsWithRange:(NSRange)range andBlock:(KRResponseBlock)block;
- (void) adminAddWithUsername:(NSString *)username password:(NSString *)password name:(NSString *)name withBlock:(KRResponseBlock)block;
- (void) adminDeleteWithBlock:(KRResponseBlock)block;
- (void) updateAdmin:(NSDictionary *)patch withBlock:(KRResponseBlock)block;
- (void) adminDeleteUser:(NSString *)username withBlock:(KRResponseBlock)block;
- (void) adminUpdateUser:(NSDictionary *)patch withBlock:(KRResponseBlock)block;
- (void) deleteUserWithID:(NSString *)userId andUsername:(NSString *)username andBlock:(KRResponseBlock)block;
- (void) updateUser:(NSDictionary *)patch withBlock:(KRResponseBlock)block;
- (void) logoutWithBlock:(KRResponseBlock)block;
- (void) getContextsWithBlock:(KRResponseBlock)block;
- (void) getContextsWithRange:(NSRange)range andBlock:(KRResponseBlock)block;
- (void) create:(id)body withBlock:(KRResponseBlock)block;
- (void) update:(id)body withBlock:(KRResponseBlock)block;
- (void) count:(id)body withBlock:(KRResponseBlock)block;
- (void) appCreate:(NSString *)appName apiKeys:(NSArray *)keys customFields:(NSDictionary *)fields withBlock:(KRResponseBlock)block;
- (void) updateApp:(NSDictionary *)patch withBlock:(KRResponseBlock)block;
- (void) listAppsWithBlock:(KRResponseBlock)block;
- (void) listAppUsersWithRange:(NSRange)range andBlock:(KRResponseBlock)block;
- (void) listAppUsersWithBlock:(KRResponseBlock)block;
- (void) removeAppWithBlock:(KRResponseBlock)block;
- (void) removeAppModel:(NSString *)modelName withBlock:(KRResponseBlock)block;
- (void) removeContext:(NSString *)contextId withBlock:(KRResponseBlock)block;
- (void) createContext:(NSString *)name meta:(NSDictionary *)meta withBlock:(KRResponseBlock)block;
- (void) updateContext:(NSDictionary *)dictionary withBlock:(KRResponseBlock)block;
- (void) getSchemasWithBlock:(KRResponseBlock)block;
- (void) updateSchema:(NSDictionary *)patch withBlock:(KRResponseBlock)block;
- (void) getCurrentAdminWithBlock:(KRResponseBlock)block;
- (void) getCurrentUserWithBlock:(KRResponseBlock)block;
- (void) refreshTokenWithBlock:(KRResponseBlock)block;

@end
