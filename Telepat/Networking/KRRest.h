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
/**
 *  Stores the device identifier
 */
@property (nonatomic, strong) NSString *device_id;

/**
 *  The Authentication HTTP header
 */
@property (nonatomic, strong) NSString *bearer;

/**
 *  Stores the API Key
 */
@property (nonatomic, strong) NSString *api_key;

/**
 *  Stores the Application Identifier
 */
@property (nonatomic, strong) NSString *app_id;

/**
 *  Set to `YES` to enable WebSockets instead of APNs
 */
@property (nonatomic) BOOL socketsEnabled;

/**
 *  Returns the KRRest singleton instance
 *
 *  @return The current instance
 */
+ (instancetype) sharedClient;

/**
 *  Returns the complete URL for a given endpoint
 *
 *  @param endpoint The endpoint to be called, e.g. "/login"
 *
 *  @return A `NSURL` object pointing to the specified endpoint
 */
+ (NSURL *) urlForEndpoint:(NSString*) endpoint;

/**
 *  The url to the WS server
 *
 *  @return a `NSURL` object containing the address to the WS server
 */
+ (NSURL *) socketURL;

/**
 *  Peform a GET request
 *
 *  @param url     The URL
 *  @param params  A dictionary of GET parameters
 *  @param headers The headers to be added to the request
 *  @param block   A `KRResponseBlock` which will be called when the request is completed
 */
- (void) get:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;

/**
 *  Perform a POST request
 *
 *  @param url     The URL
 *  @param params  A dictionary of parameters to be sent as the request body
 *  @param headers The headers to be added to the request
 *  @param block   A `KRResponseBlock` which will be called when the request is completed
 */
- (void) post:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;

/**
 *  Perform a PUT request
 *
 *  @param url     The URL
 *  @param params  A dictionary of parameters to be sent as the request body
 *  @param headers The headers to be added to the request
 *  @param block   A `KRResponseBlock` which will be called when the request is completed
 */
- (void) put:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;

/**
 *  Perform a PATCH request
 *
 *  @param url     The URL
 *  @param params  A dictionary of parameters to be sent as the request body
 *  @param headers The headers to be added to the request
 *  @param block   A `KRResponseBlock` which will be called when the request is completed
 */
- (void) patch:(NSURL*)url parameters:(id)params headers:(NSDictionary*)headers responseBlock:(KRResponseBlock)block;

/**
 *  Peform a proxy request
 *
 *  @param request A `TelepatProxyRequest` object instance configured with the necessary
 *                 data for the request
 *  @param block   A `KRResponseBlock` which will be called when the request is completed
 */
- (void) sendProxiedRequest:(NSDictionary *)request withResponseBlock:(KRResponseBlock)block;

/**
 *  Register a device with a given token
 *
 *  @param device The `UIDevice` to be registered
 *  @param token  The APNs token or the token received from the WS server
 *  @param update `YES` if the device should be updated in the backend
 *  @param block  A `KRResponseBlock` which will be called when the request is completed
 */
- (void) registerDevice:(UIDevice *)device token:(NSString *)token update:(BOOL)update withBlock:(KRResponseBlock)block;

/**
 *  Register an user via Facebook
 *
 *  @param token The token returned by Facebook
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) registerUserWithFacebookToken:(NSString *)token andBlock:(KRResponseBlock)block;

/**
 *  Register an user via Twitter
 *
 *  @param authToken  The token returned by Twitter
 *  @param authSecret The authorization token secret returned by Twitter
 *  @param block      A `KRResponseBlock` which will be called when the request is completed
 */
- (void) registerUserWithTwitterToken:(NSString *)authToken secret:(NSString *)authSecret andBlock:(KRResponseBlock)block;

/**
 *  Register an user with an username and a password
 *
 *  @param username The user's username
 *  @param password The user's password
 *  @param name     The user's visible name
 *  @param block    A `KRResponseBlock` which will be called when the request is completed
 */
- (void) registerUser:(NSString *)username withPassword:(NSString *)password name:(NSString *)name andBlock:(KRResponseBlock)block;

/**
 *  Register an user with an username and a password
 *
 *  @param userDict A `NSDictionary` containing `username`, `password` and `name` keys with their corresponding values
 *  @param block    A `KRResponseBlock` which will be called when the request is completed
 */
- (void) registerUser:(NSDictionary *)userDict withBlock:(KRResponseBlock)block;

/**
 *  Login with a Facebook token
 *
 *  @param token The token returned by Facebook SDK
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) loginWithFacebookToken:(NSString*)token andBlock:(KRResponseBlock)block;

/**
 *  Login with a Twitter token
 *
 *  @param authToken  The token returned by Twitter SDK
 *  @param authSecret The authorization token secret returned by Twitter
 *  @param block      A `KRResponseBlock` which will be called when the request is completed
 */
- (void) loginWithTwitterToken:(NSString*)authToken secret:(NSString *)authSecret andBlock:(KRResponseBlock)block;

/**
 *  Login with a username and a password
 *
 *  @param username The user's username
 *  @param password The user's password
 *  @param block    A `KRResponseBlock` which will be called when the request is completed
 */
- (void) loginWithUsername:(NSString *)username andPassword:(NSString *)password withBlock:(KRResponseBlock)block;

/**
 *  Start a reset password request
 *
 *  @param username The user's username
 *  @param block    A `KRResponseBlock` which will be called when the request is completed
 */
- (void) requestPasswordResetForUsername:(NSString*)username withBlock:(KRResponseBlock)block;

/**
 *  Reset a user's password
 *
 *  @param token       The password reset token received from the backend
 *  @param userID      The user's identifier
 *  @param newPassword The new password
 *  @param block       A `KRResponseBlock` which will be called when the request is completed
 */
- (void) resetPasswordWithToken:(NSString *)token forUserID:(NSString *)userID newPassword:(NSString *)newPassword withBlock:(KRResponseBlock)block;

/**
 *  Link a user's account with a Facebook account
 *
 *  @param token    The token returned by Facebook SDK
 *  @param username The user's username
 *  @param block    A `KRResponseBlock` which will be called when the request is completed
 */
- (void) linkWithFacebookToken:(NSString *)token username:(NSString *)username andBlock:(KRResponseBlock)block;

/**
 *  Log in as an admin
 *
 *  @param username The admin's username
 *  @param password The admin's password
 *  @param block    A `KRResponseBlock` which will be called when the request is completed
 */
- (void) adminLoginWithUsername:(NSString *)username andPassword:(NSString *)password withBlock:(KRResponseBlock)block;

/**
 *  Authorize an admin
 *
 *  @param username The admin's username
 *  @param block    A `KRResponseBlock` which will be called when the request is completed
 */
- (void) adminAuthorizeWithUsername:(NSString *)username andBlock:(KRResponseBlock)block;

/**
 *  Deauthorize an admin
 *
 *  @param username The admin's username
 *  @param block    A `KRResponseBlock` which will be called when the request is completed
 */
- (void) adminDeauthorizeWithUsername:(NSString *)username andBlock:(KRResponseBlock)block;

/**
 *  Add a new admin to the current application
 *
 *  @param username The new admin's username
 *  @param password The new admin's password
 *  @param name     The new admin's name
 *  @param block    A `KRResponseBlock` which will be called when the request is completed
 */
- (void) adminAddWithUsername:(NSString *)username password:(NSString *)password name:(NSString *)name withBlock:(KRResponseBlock)block;

/**
 *  Delete an admin from the current application
 *
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) adminDeleteWithBlock:(KRResponseBlock)block;

/**
 *  Update an admin
 *
 *  @param patch The patch body
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) updateAdmin:(NSDictionary *)patch withBlock:(KRResponseBlock)block;

/**
 *  Delete an user from the current app
 *
 *  @param username User's username to be deleted
 *  @param block    A `KRResponseBlock` which will be called when the request is completed
 */
- (void) adminDeleteUser:(NSString *)username withBlock:(KRResponseBlock)block;

/**
 *  Update an user
 *
 *  @param patch The patch body
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) adminUpdateUser:(NSDictionary *)patch withBlock:(KRResponseBlock)block;

/**
 *  Delete an user from the current app by its identifier
 *
 *  @param userId   The user's identifier
 *  @param username The user's username
 *  @param block    A `KRResponseBlock` which will be called when the request is completed
 */
- (void) deleteUserWithID:(NSString *)userId andUsername:(NSString *)username andBlock:(KRResponseBlock)block;

/**
 *  Update the current user
 *
 *  @param patch The patch body
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) updateUser:(NSDictionary *)patch withBlock:(KRResponseBlock)block;

/**
 *  Log out the current user
 *
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) logoutWithBlock:(KRResponseBlock)block;

/**
 *  Update contexts
 *
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) updateContextsWithBlock:(KRResponseBlock)block;

/**
 *  Create an object
 *
 *  @param body  The request body
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) create:(id)body withBlock:(KRResponseBlock)block;

/**
 *  Update an object
 *
 *  @param body  The request body
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) update:(id)body withBlock:(KRResponseBlock)block;

/**
 *  Count objects
 *
 *  @param body  The request body
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) count:(id)body withBlock:(KRResponseBlock)block;

/**
 *  Create an app
 *
 *  @param appName The name of the newly created app
 *  @param keys    A `NSArray` of keys to be used with this app
 *  @param fields  A `NSDictionary` of custom fields to be added to this app
 *  @param block   A `KRResponseBlock` which will be called when the request is completed
 */
- (void) appCreate:(NSString *)appName apiKeys:(NSArray *)keys customFields:(NSDictionary *)fields withBlock:(KRResponseBlock)block;

/**
 *  Update an app
 *
 *  @param patch The patch body
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) updateApp:(NSDictionary *)patch withBlock:(KRResponseBlock)block;

/**
 *  Get a list of apps
 *
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) listAppsWithBlock:(KRResponseBlock)block;

/**
 *  Get a list of the users belonging to the current app
 *
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) listAppUsersWithBlock:(KRResponseBlock)block;

/**
 *  Delete an application
 *
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) removeAppWithBlock:(KRResponseBlock)block;

/**
 *  Remove a model from the app
 *
 *  @param modelName The name of the model
 *  @param block     A `KRResponseBlock` which will be called when the request is completed
 */
- (void) removeAppModel:(NSString *)modelName withBlock:(KRResponseBlock)block;

/**
 *  Remove a context from the app
 *
 *  @param contextId The context identifier
 *  @param block     A `KRResponseBlock` which will be called when the request is completed
 */
- (void) removeContext:(NSString *)contextId withBlock:(KRResponseBlock)block;

/**
 *  Create a new context in the current app
 *
 *  @param name  The context's name
 *  @param meta  A `NSDictionary` containing meta informations for this context
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) createContext:(NSString *)name meta:(NSDictionary *)meta withBlock:(KRResponseBlock)block;

/**
 *  Get a context by its identifier
 *
 *  @param contextId The context identifier
 *  @param block     A `KRResponseBlock` which will be called when the request is completed
 */
- (void) getContext:(NSString *)contextId withBlock:(KRResponseBlock)block;

/**
 *  Get all contexts
 *
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) getContextsWithBlock:(KRResponseBlock)block;

/**
 *  Update a context
 *
 *  @param dictionary The patch body
 *  @param block      A `KRResponseBlock` which will be called when the request is completed
 */
- (void) updateContext:(NSDictionary *)dictionary withBlock:(KRResponseBlock)block;

/**
 *  Get the app schema
 *
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) getSchemasWithBlock:(KRResponseBlock)block;

/**
 *  Update an app's schema
 *
 *  @param patch The patch body
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) updateSchema:(NSDictionary *)patch withBlock:(KRResponseBlock)block;

/**
 *  Get the current admin
 *
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) getCurrentAdminWithBlock:(KRResponseBlock)block;

/**
 *  Get the current user
 *
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) getCurrentUserWithBlock:(KRResponseBlock)block;

/**
 *  Request a new authentication token
 *
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) refreshTokenWithBlock:(KRResponseBlock)block;

/**
 *  Request current user's metadata
 *
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) getUserMetadataWithBlock:(KRResponseBlock)block;

/**
 *  Update current user's metadata
 *
 *  @param patch Metadata patch
 *  @param block A `KRResponseBlock` which will be called when the request is completed
 */
- (void) updateUserMetadata:(NSDictionary *)patch withBlock:(KRResponseBlock)block;

@end
