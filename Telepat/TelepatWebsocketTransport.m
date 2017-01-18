//
//  TelepatWebsocketTransport.m
//  GW Sales
//
//  Created by Ovidiu on 03/08/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatWebsocketTransport.h"
#import "Telepat.h"
#import "TelepatConstants.h"

static TelepatWebsocketTransport *sharedClient;

@interface TelepatWebsocketTransport ()
@property (nonatomic, strong) SIOSocket *socket;
@end

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
        __weak typeof(self) _weakSelf = self;
        self.socket.onConnect = ^void() {
            NSLog(@"Websockets: connection succeeded");
            NSString *deviceId = [[Telepat client] deviceId];
            NSString *application_id = [[Telepat client] appId];
            NSDictionary *object = @{@"device_id": deviceId, @"application_id": application_id};
            SIOParameterArray *params = [SIOParameterArray arrayWithObject:object];
            [_weakSelf.socket emit:@"bind_device" args:params];
        };
        
        self.socket.onDisconnect = ^void() {
            NSLog(@"Websockets: disconnected");
        };
        
        self.socket.onError = ^void(NSDictionary *errorInfo) {
            NSLog(@"Websockets: error %@", errorInfo);
        };
        
        self.socket.onReconnect = ^void(NSInteger numberOfAttempts) {
            NSLog(@"Websockets: reconnect (%d attempts)", numberOfAttempts);
        };
        
        self.socket.onReconnectionAttempt = ^void(NSInteger numberOfAttempts) {
            NSLog(@"Websockets: attempting reconnection (%d attempts)", numberOfAttempts);
        };
        
        self.socket.onReconnectionError = ^void(NSDictionary *errorInfo) {
            NSLog(@"Websockets: reconnection error %@", errorInfo);
        };
        
        [self.socket on:@"message" callback:^(NSArray *args) {
            NSLog(@"Websockets: message: %@", [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:args[0] options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding]);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:TelepatRemoteNotificationReceived object:args[0] userInfo:@{@"source": @(TelepatNotificationOriginWebsockets)}];
            });
        }];
        
        [self.socket on:@"ready" callback:^(SIOParameterArray *args) {
            NSLog(@"Websockets: ready");
            [[NSNotificationCenter defaultCenter] postNotificationName:TelepatWebsocketsReady object:[NSArray arrayWithArray:args]];
            block();
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
