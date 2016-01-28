//
//  TelepatWebsocketTransport.m
//  GW Sales
//
//  Created by Ovidiu on 03/08/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatWebsocketTransport.h"
#import "Telepat.h"

static TelepatWebsocketTransport *sharedClient;

@implementation TelepatWebsocketTransport

+ (instancetype) sharedClient {
    if (!sharedClient) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedClient = [[TelepatWebsocketTransport alloc] init];
        });
    }
    
    return sharedClient;
}

- (void) connect:(NSURL *)url withBlock:(TelepatWebSocketWelcomeBlock)block {
    if (self.socket) [self.socket close];
    
    [SIOSocket socketWithHost:[url absoluteString] response:^(SIOSocket *socket) {
        self.socket = socket;
        self.socket.onConnect = ^void() {
            NSLog(@"Websockets: connection succeeded");
        };
        
        [self.socket on:@"welcome" callback:^(NSArray *args) {
            NSString *sessionID = [self __getValue:@"sessionId" fromArgs:args];
            NSLog(@"Welcomed with sessionID: %@", sessionID);
            NSString *deviceId = [[Telepat client] appId];
            NSString *application_id = [[Telepat client] appId];
            NSDictionary *object = @{@"deviceId": deviceId, @"application_id": application_id};
            SIOParameterArray *params = @[[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding]];
            [self.socket emit:@"bindDevice" args:params];
            dispatch_async(dispatch_get_main_queue(), ^{
                block(sessionID);
            });
        }];
        
        [self.socket on:@"message" callback:^(NSArray *args) {
            NSLog(@"Websockets: message");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:TelepatRemoteNotificationReceived object:args[0] userInfo:@{@"source": @(TelepatNotificationOriginWebsockets)}];
            });
        }];
    }];
}

- (void) disconnect {
    NSLog(@"sockets disconnected");
    [self.socket close];
}

- (id) __getValue:(NSString *)valueName fromArgs:(NSArray *)args {
    for (NSDictionary *arg in args) {
        id value = [arg objectForKey:valueName];
        if (value) return value;
    }
    
    return nil;
}

@end
