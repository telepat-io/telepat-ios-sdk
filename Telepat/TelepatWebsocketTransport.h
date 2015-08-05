//
//  TelepatWebsocketTransport.h
//  GW Sales
//
//  Created by Ovidiu on 03/08/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SIOSocket/SIOSocket.h>

typedef void (^TelepatWebSocketMessageBlock)(id message);
typedef void (^TelepatWebSocketWelcomeBlock)(NSString *sessionId);

@interface TelepatWebsocketTransport : NSObject

@property (nonatomic, strong) SIOSocket *socket;

- (void) connect:(NSURL *)url withBlock:(TelepatWebSocketWelcomeBlock)block;
+ (instancetype) sharedClient;

@end
