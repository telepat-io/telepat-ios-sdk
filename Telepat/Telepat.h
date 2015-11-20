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
#import "TelepatApp.h"
#import "TelepatRegisterDeviceResponse.h"
#import "TelepatOperatorFilter.h"
#import "TelepatYapDB.h"

extern const int ddLogLevel;

#pragma mark Keys

#define kTelepatInvalidApiURL @"InvalidAPIURL"
#define kTelepatInvalidClass @"InvalidClassException"
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
 *  Register a new user account using Facebook
 *
 *  @param token The token string returned from Facebook (accessed via `[[FBSDKAccessToken currentAccessToken] tokenString]`)
 *  @param block A `TelepatResponseBlock` which will be called when the user registration is completed.
 */
- (void) registerFacebookUserWithToken:(NSString *)token andBlock:(TelepatResponseBlock)block;

/*
 *  Register a new user account using Twitter
 *
 *  @param token The value of `authToken` property in TWTRSession class instance
 *  @param secret The value of `authTokenSecret` property in TWTRSession class instance
 *  @param block A `TelepatResponseBlock` which will be called when the user registration is completed.
 */
- (void) registerTwitterUserWithToken:(NSString *)token secret:(NSString *)secret andBlock:(TelepatResponseBlock)block;

/*
 *  Register a new user account using an email address and a password
 *
 *  @param username The username of the new user
 *  @param password The password of the newly created account
 *  @param name The name of the user
 *  @param block A `TelepatResponseBlock` which will be called when the user registration is completed.
 */
- (void) registerUser:(NSString *)username withPassword:(NSString *)password name:(NSString *)name andBlock:(TelepatResponseBlock)block;

/*
 *  Register a new user account
 *
 *  @param user A TelepatUser or TelepatUser-like object
 *  @param block A `TelepatResponseBlock` which will be called when the user registration is completed.
 */
- (void) registerUser:(TelepatUser *)user withBlock:(TelepatResponseBlock)block;

/*
 *  Deletes an user from an app as an admin
 *
 *  @param username The username of the user to be deleted
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) adminDeleteUser:(NSString *)username withBlock:(TelepatResponseBlock)block;

/*
 *  Updates an user from an app as an admin
 *
 *  @param oldUser Old, original TelepatUser
 *  @param newUser, New, updated TelepatUser
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) adminUpdateUser:(TelepatUser *)oldUser withUser:(TelepatUser *)newUser andBlock:(TelepatResponseBlock)block;

/*
 *  Sends a new authentication token to the user
 *
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) refreshTokenWithBlock:(TelepatResponseBlock)block;

/*
 *  Delete a user
 *
 *  @param user the TelepatUser to delete
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) deleteUser:(TelepatUser *)user withBlock:(TelepatResponseBlock)block;

/*
 *  Updates the user information
 *
 *  @param oldUser Old, original TelepatUser
 *  @param newUser, New, updated TelepatUser
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) updateUser:(TelepatUser *)oldUser withUser:(TelepatUser *)newUser andBlock:(TelepatResponseBlock)block;

/*
 *  Gets all users of the app
 *
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) listAppUsersWithBlock:(TelepatResponseBlock)block;

/*
 *  Login with a Facebook token
 *
 *  @param token The token returned from Facebook (accessed via `[[FBSDKAccessToken currentAccessToken] tokenString]`)
 *  @param block A `TelepatResponseBlock` which will be called when the login completed.
 */
- (void) loginWithFacebook:(NSString *)token andBlock:(TelepatResponseBlock)block;

/*
 *  Login with a Twitter token
 *
 *  @param authToken The value of the `authToken` property of the given `TWTRSession` instance by Twitter SDK
 *  @param secret The value of the `authTokenSecret` property of the given `TWTRSession` instance by Twitter SDK
 *  @param block A `TelepatResponseBlock` which will be called when the login completed.
 */
- (void) loginWithTwitter:(NSString *)authToken secret:(NSString *)secret andBlock:(TelepatResponseBlock)block;

/*
 *  Login with an username and a password
 *
 *  @param username Username of the account to log in
 *  @param password Password to login, in clear
 *  @param block A `TelepatResponseBlock` which will be called when the login completed.
 */
- (void) login:(NSString *)username password:(NSString *)password withBlock:(TelepatResponseBlock)block;

/*
 *  Request a password reset
 *
 *  @param username Username of the account to request the password reset link
 */
- (void) requestPasswordResetForUsername:(NSString *)username withBlock:(TelepatResponseBlock)block;

/*
 *  Reset password using a token retrieved from a password reset request
 *
 *  @param token The token retrieved from the password reset request
 *  @param userID The ID of the user to reset the password
 *  @param password The new password, in clear
 *  @param block A `TelepatResponseBlock` which will be called when the login completed.
 */
- (void) resetPasswordWithToken:(NSString *)token forUserID:(NSString *)userID newPassword:(NSString *)newPassword withBlock:(TelepatResponseBlock)block;

/*
 *  Authenticate an admin
 *
 *  @param username Username of the admin to authenticate
 *  @param password Password to login, in clear
 *  @param block A `TelepatResponseBlock` which will be called when the login completed.
 */
- (void) adminLogin:(NSString *)username password:(NSString *)password withBlock:(TelepatResponseBlock)block;

/*
 *  Authorizes an admin to an application
 *
 *  @param username Username of the admin to authorize
 *  @param block A `TelepatResponseBlock` which will be called when the login completed.
 */
- (void) authorizeAdmin:(NSString *)username withBlock:(TelepatResponseBlock)block;

/*
 *  Deauthorizes an admin from an application
 *
 *  @param username Username of the admin to authorize
 *  @param block A `TelepatResponseBlock` which will be called when the login completed.
 */
- (void) deauthorizeAdmin:(NSString *)username withBlock:(TelepatResponseBlock)block;

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
 *  Deletes the currently logged admin.
 *
 *  @param block A `TelepatResponseBlock` which will be called when the admin creation is completed.
 */
- (void) deleteAdminWithBlock:(TelepatResponseBlock)block;

/*
 *  Updates the currently logged admin. Every property in the request body is used to udpate the admin.
 *
 *  @param oldUser Old, original admin TelepatUser
 *  @param newUser, New, updated admin TelepatUser
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) updateAdmin:(TelepatUser *)oldAdmin withUser:(TelepatUser *)newAdmin andBlock:(TelepatResponseBlock)block;

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
 *  Subscribe to a `TelepatContext`. A new `TelepatChannel` object will be instantiated and returned
 *
 *  @param context A `TelepatContext` to subscribe to
 *  @param modelName The name of the model to subscribe to
 *  @param classType The kind of objects which will be stored in the `TelepatChannel` instance. Used for instantiating the proper objects when notifications arrives.
 *  @param filter Filters to use when subscribing
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (TelepatChannel *) subscribe:(TelepatContext *)context modelName:(NSString *)modelName classType:(Class)classType filter:(TelepatOperatorFilter*)filter withBlock:(TelepatResponseBlock)block;

/*
 *  Unsubscribe from a channel
 *
 *  @param channel The channel to unsubscribe fromrea
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
 *  Create a new Context in the current application
 *
 *  @param name The name of the new context
 *  @param meta A NSDictionary containing metainformation to be aatributed to the context
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) createContextWithName:(NSString *)name meta:(NSDictionary *)meta withBlock:(TelepatResponseBlock)block;

/*
 *  Retrieves a context
 *
 *  @param contextId The id of the context to retrieve
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) getContext:(NSString *)contextId withBlock:(TelepatResponseBlock)block;

/*
 *  Get all contexts
 *
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) getContextsWithBlock:(TelepatResponseBlock)block;

/*
 *  Gets the model schema for an application
 *
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) getSchemasWithBlock:(TelepatResponseBlock)block;

/*
 *  Updates the model schema
 *
 *  @param schema The new schema
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) updateSchema:(NSDictionary *)schema withBlock:(TelepatResponseBlock)block;

/*
 *  Get information about the logged admin
 *
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) getCurrentAdminWithBlock:(TelepatResponseBlock)block;

/*
 *  Check if a user is logged in
 *
 *  @return YES if logged in, NO if not logged in
 */
- (BOOL) isLoggedIn;

/*
 *  Creates an app for the current admin.
 *
 *  @param appName The name of the application
 *  @param fields Custom fields to be added to this app
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) createAppWithName:(NSString *)appName keys:(NSArray *)keys customFields:(NSDictionary *)fields block:(TelepatResponseBlock)block;

/*
 *  Lists the application for the current admin
 *
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) listAppsWithBlock:(TelepatResponseBlock)block;

/*
 *  Remove the current application
 *
 *  @param A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) removeAppWithBlock:(TelepatResponseBlock)block;

/*
 *  Updates an app
 *
 *  @param oldApp Old, original `TelepatApp`
 *  @param newApp New, updated `TelepatApp`
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) updateApp:(TelepatApp *)oldApp withApp:(TelepatApp *)newApp andBlock:(TelepatResponseBlock)block;

/*
 *  Removes a model from the application (all items of this type will be deleted)
 *
 *  @param modelName The name of the model
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) removeAppModel:(NSString *)modelName withBlock:(TelepatResponseBlock)block;

/*
 *  Removes a context and all associated objects
 *
 *  @param contextId The ID of the context to be deleted
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) removeContext:(NSString *)contextId withBlock:(TelepatResponseBlock)block;

/*
 *  Updates the context object
 *
 *  @param oldContext Old, original `TelepatContext`
 *  @param newContext New, updated `TelepatContext`
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) updateContext:(TelepatContext *)oldContext withContext:(TelepatContext *)newContext andBlock:(TelepatResponseBlock)block;

@end