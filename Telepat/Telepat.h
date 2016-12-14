//
//  Telepat.h
//  Kraken
//
//  Created by Ovidiu on 24/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "TelepatConstants.h"
#import "TelepatResponse.h"
#import "TelepatDeviceIdentifier.h"
#import "TelepatAuthorization.h"
#import "TelepatChannel.h"
#import "TelepatContext.h"
#import "TelepatApp.h"
#import "TelepatRegisterDeviceResponse.h"
#import "TelepatOperatorFilter.h"
#import "TelepatLevelDB.h"
#import "TelepatProxyRequest.h"

@import CocoaLumberjack;

extern const int ddLogLevel;
typedef NS_ENUM(NSInteger, TelepatUpdatesTransportType) {
    TelepatUpdatesTransportTypeSockets,
    TelepatUpdatesTransportTypeiOS
};

#pragma mark Keys

#define kTelepatAPIURL @"kTelepatAPIURL"
#define kTelepatWebSocketsURL @"kTelepatWebSocketsURL"

#define kTelepatInvalidApiURL @"InvalidAPIURL"
#define kTelepatInvalidClass @"InvalidClassException"
#define kTelepatInvalidFilterType @"InvalidFilterType"
#define kTelepatInvalidFilterRelationType @"InvalidRelationType"

#pragma mark -

/**
 *  A block used for asynchronious network requests made using `Telepat`
 */
typedef void (^HTTPResponseBlock)(NSDictionary *dictionary, NSError *error);

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
 *  Stores the device identifier
 */
@property (nonatomic, strong) NSString *deviceId;

/**
 *  The `AFHTTPSessionManager` object used for HTTP requests
 */
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

/**
 *  The kind of transport Telepat uses to receive updates
 */
@property (nonatomic) TelepatUpdatesTransportType updatesTransportType;

/**
 *  Instantiate (if needed) and returns a `Telepat` singleton instance.
 *
 *  @return a `Telepat` singleton instance
 */
+ (Telepat *) client;

/**
 *  Set the application ID and the API key
 *
 *  @param clientAppId The application ID
 *  @param clientApiKey The API key
 */
+ (void) setApplicationId:(NSString *)clientAppId apiKey:(NSString *)clientApiKey;

/**
 *  The Authentication HTTP header
 */
@property (nonatomic, strong) NSString *bearer;

/**
 *  Get the current device description
 *
 *  @return A string describing the current device
 */
+ (NSString *) deviceName;

/**
 *  The url to the WS server
 *
 *  @return a `NSURL` object containing the address to the WS server
 */
+ (NSURL *) socketURL;

/**
 *  Get an instance of the underlying database manager
 *
 *  @return A `TelepatDB` subclass instance
 */
- (TelepatDB *) dbInstance;

/**
 *  Returns the complete URL for a given endpoint
 *
 *  @param endpoint The endpoint to be called, e.g. "/login"
 *
 *  @return A `NSURL` object pointing to the specified endpoint
 */
+ (NSURL *) urlForEndpoint:(NSString*) endpoint;

/**
 *  Peform a GET request
 *
 *  @param url     The URL
 *  @param params  A dictionary of GET parameters
 *  @param headers The headers to be added to the request
 *  @param block   A `HTTPResponseBlock` which will be called when the request is completed
 */
- (void) get:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(HTTPResponseBlock)block;

/**
 *  Perform a POST request
 *
 *  @param url     The URL
 *  @param params  A dictionary of parameters to be sent as the request body
 *  @param headers The headers to be added to the request
 *  @param block   A `HTTPResponseBlock` which will be called when the request is completed
 */
- (void) post:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(HTTPResponseBlock)block;

/**
 *  Perform a PUT request
 *
 *  @param url     The URL
 *  @param params  A dictionary of parameters to be sent as the request body
 *  @param headers The headers to be added to the request
 *  @param block   A `HTTPResponseBlock` which will be called when the request is completed
 */
- (void) put:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(HTTPResponseBlock)block;

/**
 *  Perform a PATCH request
 *
 *  @param url     The URL
 *  @param params  A dictionary of parameters to be sent as the request body
 *  @param headers The headers to be added to the request
 *  @param block   A `HTTPResponseBlock` which will be called when the request is completed
 */
- (void) patch:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(HTTPResponseBlock)block;

/**
 *  Perform a DELETE request
 *
 *  @param url     The URL
 *  @param params  A dictionary of parameters to be sent as the request body
 *  @param headers The headers to be added to the request
 *  @param block   A `HTTPResponseBlock` which will be called when the request is completed
 */
- (void) delete:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(HTTPResponseBlock)block;

/**
 *  Perform a HTTP request
 *
 *  @discussion This method performs a HTTP request while making sure that the authorization token (bearer) is valid.
 *  If the token is expired this method calls /user/refresh_token, updates the token and repeats the request. Call this
 *  method everytime you need to perform a request which needs a valid auth token, otherwise use other methods such
 *  as `post:parameters:headers:responseBlock`.
 *
 *  @param requestType The type of the HTTP request ("GET", "POST", "PUT", "PATCH", "DELETE")
 *  @param params  A dictionary of parameters to be sent as the request body
 *  @param headers The headers to be added to the request
 *  @param block   A `HTTPResponseBlock` which will be called when the request is completed
 */
- (void) performRequestOfType:(NSString *)requestType withURL:(NSURL *)url params:(NSDictionary *)params headers:(NSDictionary *)headers andBlock:(HTTPResponseBlock)block;

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
- (void) loginWithTwitter:(NSString *)authToken secret:(NSString *)authSecret andBlock:(TelepatResponseBlock)block;

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

/**
 *  Link a Telepat account with Facebook
 *
 *  @param username Username of the Telepat account to be linked
 *  @param token    The token returned from Facebook (accessed via `[[FBSDKAccessToken currentAccessToken] tokenString]`)
 *  @param block    A `TelepatResponseBlock` which will be called when the login completed.
 */
- (void) linkAccountWithFacebook:(NSString *)username token:(NSString *)token withBlock:(TelepatResponseBlock)block;

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
- (TelepatChannel *) subscribe:(TelepatContext *)context modelName:(NSString *)modelName classType:(Class)classType filter:(TelepatOperatorFilter*)filter range:(NSRange)range withBlock:(TelepatResponseBlock)block;

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
 *  @param contextId The ID of context to return
 *  @return The context with specified ID or nil, if a context with that ID doesn't exists.
 */
- (TelepatContext *) contextWithId:(NSString *)contextId;

/*
 *  Get the context with specified ID
 *
 *  @param contextId The identifier of context to return
 *  @return The context with specified identifier or nil, if a context with that identifier doesn't exists.
 */
- (TelepatContext *) contextWithIdentifier:(NSString *)identifier;

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
 *  Get all contexts within a range
 *
 *  @param range A `NSRange` with the start offset and the number of objects to be returned
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) getContextsWithRange:(NSRange)range andBlock:(TelepatResponseBlock)block;

/*
 *  Create an object in a context
 *
 *  @param object    The `TelepatObject` to be created
 *  @param context   The context where the new object should be created
 *  @param modelName The model name
 *  @param block     A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (NSString *) createObject:(TelepatBaseObject *)object inContext:(TelepatContext *)context model:(NSString *)modelName withBlock:(TelepatResponseBlock)block;

/*
 *  Update an object
 *
 *  @param oldObject The old version of the object
 *  @param newObject The updated version of the object
 *  @param block     A `TelepatResponseBlock` which will be called when the request is completed.
 *
 */
- (void) updateObject:(TelepatBaseObject *)oldObject withObject:(TelepatBaseObject *)newObject withBlock:(TelepatResponseBlock)block;

/**
 *  Count objects
 *
 *  @param body  The request body
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed
 */
- (void) count:(id)body withBlock:(TelepatResponseBlock)block;

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

/**
 *  Info about logged user
 *
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) getCurrentUserWithBlock:(TelepatResponseBlock)block;

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

/**
 *  Sends a proxied request. See `TelepatProxyRequest` for more details
 *
 *  @param request The `TelepatProxyRequest` object
 *  @param block   A `KRResponseBlock` which will be called when the request is completed.
 */
- (void) sendProxiedRequest:(TelepatProxyRequest *)request withResponseBlock:(void (^)(NSData *responseData, NSError *error))block;

/*
 *  Get current's user metadata info
 *
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) getUserMetadataWithBlock:(TelepatResponseBlock)block;

/*
 *  Updates the user metadata
 *
 *  @param oldMetadata Old, original TelepatUserMetadata
 *  @param newMetadata, New, updated TelepatUserMetadata
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) updateUserMetadata:(TelepatUserMetadata *)oldMetadata withUserMetadata:(TelepatUserMetadata *)newMetadata andBlock:(TelepatResponseBlock)block;

/*
 *  Send an email through the Telepat API
 *
 *  @param recipients A `NSArray` of the email addresses of the recipients
 *  @param from Email address of the sender
 *  @param fromName Name of the sender (can be nil)
 *  @param subject Subject line (can be nil)
 *  @param body Body of the email. Can be plain text or html formatted
 *  @param block A `TelepatResponseBlock` which will be called when the request is completed.
 */
- (void) sendEmailToRecipients:(NSArray *)recipients from:(NSString *)from fromName:(NSString *)fromName subject:(NSString *)subject body:(NSString *)body withBlock:(TelepatResponseBlock)block;

@end
