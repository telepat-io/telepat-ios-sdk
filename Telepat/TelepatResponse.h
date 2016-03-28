//
//  TelepatResponse.h
//  Kraken
//
//  Created by Ovidiu on 29/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KRResponse.h"
#import "TelepatBaseObject.h"
#import "TelepatErrors.h"

/**
 * On every request made with Telepat you will receive a `TelepatResponse` instance as an argument for response blocks. You can use this instance to retrieve the returned objects from the Telepat Sync API.
 *
 */
@interface TelepatResponse : NSObject

/**
 *  The status code of the response
 */
@property (nonatomic) NSInteger status;

/**
 *  The content of the response
 */
@property (nonatomic, strong) id content;

/**
 *  The message sent from Telepat Sync API
 */
@property (nonatomic, strong) NSString *message;

/**
 *  The code of the Telepat Error
 */
@property (nonatomic, strong) NSString *code;

/**
 *  The error (if any) from Telepat Sync API
 */
@property (nonatomic, strong) NSError *error;

/**
 *  Initialize a `TelepatResponse` instance based on a `KRResponse`
 *
 *  @param response The `KRResponse` returned by `KRRest` REST client
 */
- (id) initWithResponse:(KRResponse *)response;

/**
 *  Check if the request resulted into an error
 *
 *  @return YES if there was an error
 */
- (BOOL) isError;

/**
 *  Get an instance or a list of instances of `classType` returned by the Telepat Sync API.
 *  @warning This method will directly return the `classType` instance if the request returned just one object or will return a NSArray of `classType` instances if the request returned a list of objects.
 *
 *  @param classType The class of the expected object. Should be a subclass of `TelepatBaseObject`
 */
- (id) getObjectOfType:(Class)classType;

@end
