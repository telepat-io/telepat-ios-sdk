//
//  TelepatWebsocketTransport.h
//  GW Sales
//
//  Created by Ovidiu on 03/08/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SIOSocket/SIOSocket.h>

/**
 *  A block to be called everytime a message comes over socket.io
 */
typedef void (^TelepatWebSocketMessageBlock)(id message);

/**
 *  A block to be called everytime a welcome message comes over socket.io
 */
typedef void (^TelepatWebSocketWelcomeBlock)();

/**
 *  `TelepatWebsocketTransport` is a alternative to get updates when using Apple's Push Notifications is not possible
 */

@interface TelepatWebsocketTransport : NSObject

/**
 *  Connect to a websockets server
 *
 *  @param url The address of the websockets server (e.g. ws://localhost:3001)
 *  @param block The block which will be called on "on_welcome"
 */
- (void) connect:(NSURL *)url withBlock:(TelepatWebSocketWelcomeBlock)block;

/**
 *  Disconnect from the current websocket connection
 */
- (void) disconnect;

/**
 *  Get the `TelepatWebsocketTransport` singleton
 *
 *  @return The `TelepatWebsocketTransport` singleton instance
 */
+ (instancetype) sharedClient;

@end
