# Telepat iOS SDK Reference
## About
The Telepat iOS SDK provides the necessary bindings to interact with the Telepat Sync API, as well as a WebSocket and Apple Push Notifications transport implementation for receiving updates from a Telepat cloud instance.

---

## Setting up everything

### Using CocoaPods

To integrate Telepat in your project using Cocoapods just add `pod "Telepat", "~> 0.4"` under your target in your Podfile, then run `pod install`.

### Integrating manually

Clone this repository then drag'n'drop Telepat directory into your project. You'll also need to add [Objective-LevelDB](https://github.com/matehat/Objective-LevelDB) 2.1, [JSONModel](https://github.com/jsonmodel/jsonmodel) 1.1.0, [AFNetworking](https://github.com/AFNetworking/AFNetworking) 2.5.0, [SIOSocket](https://github.com/MegaBits/SIOSocket) 0.2.0 and [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack) 2.0.

## Usage

First add in your `Info.plist` file the following keys and values:

    <key>kTelepatAPIURL</key>
	<string>http://YOUR_API_SERVER:3000/</string>
	<key>kTelepatWebSocketsURL</key>
	<string>ws://YOUR_API_SERVER:80</string>
	
(of course, do not forget to replace _YOUR\_API\_SERVER_ with actual values. Also the port numbers may differ in your configuration).

Then in your `AppDelegate.m` file import Telepat:  
    
    #import <Telepat/Telepat.h>

In `[UIApplicationDelegate application:didFinishLaunchingWithOptions:]` initialize the Telepat with your application identifier and API key:

    [Telepat setApplicationId:@"your_application_id" apiKey:@"your_api_key"];
    
Now you're ready to register your device with Telepat. To receive updates you will need to register either with WebSockets or with Apple's Push Notifications system. You'll probably want to use APN so you can receive updates while your application is in background; if not you can use WebSockets which is simpler to configure.

For registering with WebSockets you just have to call:

    [[Telepat client] registerDeviceForWebsocketsWithBlock:^(TelepatResponse *response) {
        NSLog(@"Registered for websockets");
    } shouldUpdateBackend:YES];

If you want to register with Apple Push Notifications first enable your application to use [Remote Notifications](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/APNSOverview.html#//apple_ref/doc/uid/TP40008194-CH8-SW1). When you're ready and you received a `deviceToken` in `[UIApplicationDelegate application:didRegisterForRemoteNotificationsWithDeviceToken:]` send it to Telepat:

    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    
    [[Telepat client] registerDeviceWithToken:hexToken shouldUpdateBackend:YES withBlock:^(TelepatResponse *response) {
        if ([response isError]) {
            NSLog(@"Failed to register device: %@", response.error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to register device" message:response.message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
            [alert show];
        } else {
            NSLog(@"Registered device %@ for push notifications with token: %@", [Telepat client].deviceId, hexToken);
        }
    }];

Everytime there's an update coming from Telepat `[UIApplicationDelegate application:didReceiveRemoteNotification:fetchCompletionHandler:]` will be called. In this method please call

    [[NSNotificationCenter defaultCenter] postNotificationName:TelepatRemoteNotificationReceived object:userInfo];
   
so the Telepat SDK will be notified about those updates.

---

## Subscribing to and processing updates

To receive updates you have to subscribe to a context and a model name. You retrieve contexts by calling:

    [[Telepat client] getAll:^(TelepatResponse *response) {
        if (!response.isError) {
            NSArray *contexts = [response getObjectOfType:[TelepatContext class]];
            TelepatContext *myContext = [contexts firstObject];
        }
    }];
    
Then you subscribe:

    TelepatChannel *myChannel = [[Telepat client] subscribe:myContext 
                                                  modelName:@"model" 
                                                  classType:[MyObject class] 
                                                  withBlock:^(TelepatResponse *response) {
                                                    if (!response.isError) {
                                                        NSLog(@"Successfully subscribed!");
                                                    }
    }];

Now everytime an object in your subscription is modified, Telepat will receive an update and it will process the updated object in background, then will post a notification through NSNotificationCenter. A notification of type `TelepatChannelObjectAdded` will be posted if a new object was added, `TelepatChannelObjectUpdated` for an updated object and everytime a object is deleted `TelepatChannelObjectDeleted` will be posted. You will find the altered object in the `notification.userInfo` dictionary, at the `kNotificationObject` key.

