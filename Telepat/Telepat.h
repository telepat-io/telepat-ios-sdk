//
//  Telepat.h
//  Kraken
//
//  Created by Ovidiu on 24/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLog.h"
#import "DDTTYLogger.h"
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

extern const int ddLogLevel;

#pragma mark Keys

#define kTelepatInvalidApiURL @"InvalidAPIURL"
#define kTelepatInvalidClass @"InvalidSubclassException"
#define kTelepatInvalidFilterType @"InvalidFilterType"
#define kTelepatInvalidFilterRelationType @"InvalidRelationType"

#pragma mark -

/**
 *  A block used for asynchronious network requests made using `Telepat`
 */
typedef void (^TelepatResponseBlock)(TelepatResponse *response);

/**
 *  The Telepat iOS SDK provides the necessary bindings to interact with the Telepat Sync API, as well as a Apple Push Notifications transport implementation for receiving updates from a Telepat cloud instance.
 */
@interface Telepat : NSObject

/**
 *  The apiKey used to connect to the Telepat server
 */
@property (nonatomic, strong) NSString *apiKey;

/**
 *  The appId used to connect to the Telepat server
 */
@property (nonatomic, strong) NSString *appId;

/**
 *  Instantiate (if needed) and returns a `Telepat` singleton instance.
 *
 *  @return a `Telepat` singleton instance
 */
+ (Telepat *) client;

/**
 *  Returns the underlying REST client which Telepat uses for REST requests
 *
 *  @return The current `KRRest` instance
 */
+ (KRRest *) restClient;

/**
 *  Set the application ID and the API key
 *
 *  @param clientAppId The application ID
 *  @param clientApiKey The API key
 */
+ (void) setApplicationId:(NSString *)clientAppId apiKey:(NSString *)clientApiKey;

/**
 *  Get the current device description
 *
 *  @return A string describing the current device
 */
+ (NSString *) deviceName;

/**
 *  Get an instance of the underlying database manager
 *
 *  @return A `TelepatDB` subclass instance
 */
- (TelepatDB *) dbInstance;

/**
 *  Register for receiving updates via Websockets. Use this if using Apple Push Notifications service is impossible.
 *
 *  @param block A `TelepatResponseBlock` which will be called when the registration completed.
 *  @param shouldUpdateBackend Set to YES if the backend should update the current device
 */
- (void) registerDeviceForWebsocketsWithBlock:(TelepatResponseBlock)block shouldUpdateBackend:(BOOL)shouldUpdateBackend;

/*
 *  Register for receiving updates via Push Notifications.
 *
 *  @param token The token returned by `didRegisterForRemoteNotificationsWithDeviceToken` method in your AppDelegate, as HEX.
 *  @param block A `TelepatResponseBlock` which will be called when the registration completed.
 */
- (void) registerDeviceWithToken:(NSString*)token withBlock:(TelepatResponseBlock)block;

/*
 *  Register for receiving updates via Push Notifications.
 *
 *  @param token The token returned by `didRegisterForRemoteNotificationsWithDeviceToken` method in your AppDelegate, as HEX.
 *  @param shouldUpdateBackend Set to YES if the backend should update the current device
 *  @param block A `TelepatResponseBlock` which will be called when the registration completed.
 */
- (void) registerDeviceWithToken:(NSString*)token shouldUpdateBackend:(BOOL)shouldUpdateBackend withBlock:(TelepatResponseBlock)block;

/*
 *  Register a new account using a Facebook token
 *
 *  @param token The token returned from Facebook (accessed via `[[FBSDKAccessToken currentAccessToken] tokenString]`)
 *  @param block A `TelepatResponseBlock` which will be called when the user registration is completed.
 */
- (void) registerUser:(NSString *)token withBlock:(TelepatResponseBlock)block;

/*
 *  Login with a Facebook token
 *
 *  @param token The token returned from Facebook (accessed via `[[FBSDKAccessToken currentAccessToken] tokenString]`)
 *  @param block A `TelepatResponseBlock` which will be called when the login completed.
 */
- (void) login:(NSString *)token withBlock:(TelepatResponseBlock)block;

/*
 *  Login with an username and a password
 *
 *  @param username Username of the account to log in
 *  @param password Password to login, in clear
 *  @param block A `TelepatResponseBlock` which will be called when the login completed.
 */
- (void) login:(NSString *)username password:(NSString *)password withBlock:(TelepatResponseBlock)block;

/*
 *  Authenticate an admin
 *
 *  @param username Username of the admin to authenticate
 *  @param password Password to login, in clear
 *  @param block A `TelepatResponseBlock` which will be called when the login completed.
 */
- (void) adminLogin:(NSString *)username password:(NSString *)password withBlock:(TelepatResponseBlock)block;

/*
 *  Add a new admin account
 *
 *  @param username Username of the new admin
 *  @param password Password of the new admin account, in clear
 *  @param name Name of the admin
 *  @param block A `TelepatResponseBlock` which will be called when the admin creation is completed.
 */
- (void) adminAdd:(NSString *)username password:(NSString *)password name:(NSString *)name withBlock:(TelepatResponseBlock)block;

/*
 *  Logout from the current account
 *
 *  @param block A `TelepatResponseBlock` which will be called when the login completed.
 */
- (void) logoutWithBlock:(TelepatResponseBlock)block;

/*
 *  Get all available contexts.
 *  To retrieve the list of returned contexts call `[response getObjectOfType:[TelepatContext class]]`
 *
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) getAll:(TelepatResponseBlock)block;

/*
 *  Subscribe to a `TelepatContext`. A new `TelepatChannel` object will be instantiated and returned
 *
 *  @param context A `TelepatContext` to subscribe to
 *  @param modelName The name of the model to subscribe to
 *  @param classType The kind of objects which will be stored in the `TelepatChannel` instance. Used for instantiating the proper objects when notifications arrives.
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (TelepatChannel *) subscribe:(TelepatContext *)context modelName:(NSString *)modelName classType:(Class)classType withBlock:(TelepatResponseBlock)block;

/*
 *  Unsubscribe from a channel
 *
 *  @param channel The channel to unsubscribe from
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) removeSubscription:(TelepatChannel *)channel withBlock:(TelepatResponseBlock)block;

/*
 *  Register a channel as a subscription. Called from `TelepatChannel`
 *
 *  @param channel The channel to register
 */
- (void) registerSubscription:(TelepatChannel *)channel;

/*
 *  Unregister a channel as a subscription. Called from `TelepatChannel`
 *
 *  @param channel The channel to unregister
 */
- (void) unregisterSubscription:(TelepatChannel *)channel;

/*
 *  Get all the current contexts as a NSDictionary with context IDs as key and the `TelepatContext` instances as values.
 *
 *  @return A `NSDictionary` of context_ID : `TelepatContext` instance
 */
- (NSDictionary *) contextsMap;

/*
 *  Get the context with specified ID
 *
 *  @param contextId The numeric ID of context to return
 *  @return The context with specified ID or nil, if a context with that ID doesn't exists.
 */
- (TelepatContext *) contextWithId:(NSInteger)contextId;

/*
 *  Check if a user is logged in
 *
 *  @return YES if logged in, NO if not logged in
 */
- (BOOL) isLoggedIn;

/*
 *  Creates an app for the admin.
 *
 *  @param appName The name of the application
 *  @param fields Custom fields to be added to this app
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) createAppWithName:(NSString *)appName fields:(NSDictionary *)fields block:(TelepatResponseBlock)block;

/*
 *  Lists the application for the current admin
 *
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) listAppsWithBlock:(TelepatResponseBlock)block;

@end