//
//  Telepat.h
//  Kraken
//
//  Created by Ovidiu on 24/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KRRest.h"
#import "TelepatConstants.h"
#import "TelepatResponse.h"
#import "TelepatDeviceIdentifier.h"
#import "TelepatAuthorization.h"
#import "TelepatChannel.h"
#import "TelepatContext.h"
#import "TelepatRegisterDeviceResponse.h"
#import "TelepatOperatorFilter.h"
#import "TelepatYapDB.h"

typedef void (^TelepatResponseBlock)(TelepatResponse *response);

@interface Telepat : NSObject

@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *appId;

+ (Telepat *) client;
+ (KRRest *) restClient;
+ (void) setApplicationId:(NSString *)clientAppId apiKey:(NSString *)clientApiKey;
+ (NSString *) deviceName;

- (TelepatDB *) dbInstance;

- (void) registerDeviceForWebsocketsWithBlock:(TelepatResponseBlock)block shouldUpdateBackend:(BOOL)shouldUpdateBackend;
- (void) registerDeviceWithToken:(NSString*)token withBlock:(TelepatResponseBlock)block;
- (void) registerDeviceWithToken:(NSString*)token shouldUpdateBackend:(BOOL)shouldUpdateBackend withBlock:(TelepatResponseBlock)block;
- (void) login:(NSString *)token withBlock:(TelepatResponseBlock)block;
- (void) login:(NSString *)username password:(NSString *)password withBlock:(TelepatResponseBlock)block;
- (void) logoutWithBlock:(TelepatResponseBlock)block;
- (void) getAll:(TelepatResponseBlock)block;
- (TelepatChannel *) subscribe:(TelepatContext *)context modelName:(NSString *)modelName classType:(Class)classType withBlock:(TelepatResponseBlock)block;
- (TelepatChannel *) subscribe:(TelepatContext *)context modelName:(NSString *)modelName classType:(Class)classType filter:(TelepatOperatorFilter *)filter params:(NSDictionary*)params withBlock:(TelepatResponseBlock)block;
- (void) removeSubscription:(TelepatChannel *)channel withBlock:(TelepatResponseBlock)block;
- (void) registerSubscription:(TelepatChannel *)channel;
- (void) unregisterSubscription:(TelepatChannel *)channel;
- (NSDictionary *) contextsMap;
- (TelepatContext *) contextWithId:(NSInteger)contextId;

- (BOOL) isLoggedIn;

@end