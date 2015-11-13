//
//  TelepatErrors.h
//  Pods
//
//  Created by Ovidiu on 13/11/15.
//
//

#ifndef TelepatErrors_h
#define TelepatErrors_h

/**
 *  Unable to create: parent %s with ID %s does not exist
 */
#define kTelepatErrorParentObjectNotFound @"035"

/**
 *  Wrong user email address or password
 */
#define kTelepatErrorAdminBadLogin @"016"

/**
 *  Unspecified error
 */
#define kTelepatErrorUnspecifiedError @"032"

/**
 *  There is no route with this URL path
 */
#define kTelepatErrorNoRouteAvailable @"003"

/**
 *  User not found
 */
#define kTelepatErrorUserNotFound @"023"

/**
 *  Invalid patch: %s
 */
#define kTelepatErrorInvalidPatch @"042"

/**
 *  Admin with email address %s does not belong to this application
 */
#define kTelepatErrorAdminNotFoundInApplication @"019"

/**
 *  Could not fulfill request because application has no schema defined
 */
#define kTelepatErrorApplicationHasNoSchema @"043"

/**
 *  Required request body is empty
 */
#define kTelepatErrorRequestBodyEmpty @"005"

/**
 *  This context doesn't belong to you
 */
#define kTelepatErrorContextNotAllowed @"021"

/**
 *  Invalid authorization: %s
 */
#define kTelepatErrorInvalidAuthorization @"014"

/**
 *  Insufficient facebook permissions: %s
 */
#define kTelepatErrorInsufficientFacebookPermissions @"028"

/**
 *  User already exists
 */
#define kTelepatErrorUserAlreadyExists @"029"

/**
 *  The API server is unable to fulfil your request. Try again later
 */
#define kTelepatErrorServerNotAvailable @"001"

/**
 *  Cannot remove yourself from the application because you're the only authorized admin
 */
#define kTelepatErrorAdminDeauthorizeLastAdmin @"018"

/**
 *  Authorization header is not present
 */
#define kTelepatErrorAuthorizationMissing @"013"

/**
 *  Device with ID %s not found
 */
#define kTelepatErrorDeviceNotFound @"025"

/**
 *  Context with id %s does not belong to app with id %s
 */
#define kTelepatErrorInvalidContext @"026"

/**
 *  Expired authorization token
 */
#define kTelepatErrorExpiredAuthorizationToken @"046"

/**
 *  User does not belong to this application
 */
#define kTelepatErrorInvalidApplicationUser @"024"

/**
 *  Context not found
 */
#define kTelepatErrorContextNotFound @"020"

/**
 *  Object model %s with ID %s not found
 */
#define kTelepatErrorObjectNotFound @"034"

/**
 *  Request content type must be application/json
 */
#define kTelepatErrorInvalidContentType @"006"

/**
 *  Required application ID header is missing
 */
#define kTelepatErrorApplicationIdMissing @"010"

/**
 *  Application with ID %s does not have a model named %s
 */
#define kTelepatErrorApplicationSchemaModelNotFound @"022"

/**
 *  Login provider %s is not configured
 */
#define kTelepatErrorLoginProviderNotConfigured @"045"

/**
 *  You don't have the necessary privileges for this operation
 */
#define kTelepatErrorOperationNotAllowed @"015"

/**
 *  Admin with that email address is already authorized in this application
 */
#define kTelepatErrorAdminAlreadyAuthorized @"017"

/**
 *  Admin already exists
 */
#define kTelepatErrorAdminAlreadyExists @"030"

/**
 *  Malformed authorization token
 */
#define kTelepatErrorMalformedAuthorizationToken @"040"

/**
 *  API key is not valid for this application
 */
#define kTelepatErrorInvalidApikey @"008"

/**
 *  This application does not belong to you
 */
#define kTelepatErrorApplicationForbidden @"012"

/**
 *  Invalid admin
 */
#define kTelepatErrorInvalidAdmin @"041"

/**
 *  Invalid login provider. Possible choices: %s
 */
#define kTelepatErrorInvalidLoginProvider @"044"

/**
 *  Request body is missing a required field: %s
 */
#define kTelepatErrorMissingRequiredField @"004"

/**
 *  Required device ID header is missing
 */
#define kTelepatErrorDeviceIdMissing @"009"

/**
 *  Admin not found: %s
 */
#define kTelepatErrorAdminNotFound @"033"

/**
 *  API key is missing from the request headers
 */
#define kTelepatErrorApiKeySignatureMissing @"007"

/**
 *  Invalid field value: %s
 */
#define kTelepatErrorInvalidFieldValue @"038"

/**
 *  API internal server error: %s
 */
#define kTelepatErrorServerFailure @"002"

/**
 *  Generic bad request error: %s
 */
#define kTelepatErrorClientBadRequest @"039"

/**
 *  Unable to create: parent relation key %s is not valid. Must be at most %s
 */
#define kTelepatErrorInvalidObjectRelationKey @"036"

/**
 *  Requested application with ID %s does not exist
 */
#define kTelepatErrorApplicationNotFound @"011"

/**
 *  User email address or password do not match
 */
#define kTelepatErrorUserBadLogin @"031"

/**
 *  This user account has not been confirmed
 */
#define kTelepatErrorUnconfirmedAccount @"047"

/**
 *  Channel is invalid: %s
 */
#define kTelepatErrorInvalidChannel @"027"

/**
 *  Subscription not found
 */
#define kTelepatErrorSubscriptionNotFound @"037"

#endif /* TelepatErrors_h */
