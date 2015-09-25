//
//  TelepatProjectTests.m
//  TelepatProjectTests
//
//  Created by Ovidiu on 22/09/15.
//  Copyright © 2015 Telepat. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Telepat.h>

static NSString *username = @"nitanovidiu@gmail.com";
static NSString *password = @"abracadabra";
static NSString *authadminusername = @"ovidiu.nitan@appscend.com";
static NSString *name = @"Ovidiu N.";
static NSString *appName = @"iOS Test Application";
static NSString *updatedAppName = @"Updated iOS Test Application";
static NSString *contextInfo = @"A super context";
static NSString *apiKey = @"3406870085495689e34d878f09faf52c";

@interface TelepatProjectTests : XCTestCase

@end

@implementation TelepatProjectTests {
    TelepatContext *_createdContext;
}

- (void)setUp {
    [super setUp];
    
    BOOL __block finished = NO;
    
    NSLog(@"Creating admin");
    [[Telepat client] adminAdd:username password:password name:name withBlock:^(TelepatResponse *response) {
        if (response.status != 200) NSLog(@"%d Admin account could not be created: %@", response.status, response);
        NSLog(@"Signing in admin...");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[Telepat client] adminLogin:username password:password withBlock:^(TelepatResponse *response) {
                if ([response isError]) {
                    XCTFail(@"%d Could not log in admin: %@", response.status, response.message);
                } else {
                    NSLog(@"Signed in");
                }
                finished = YES;
            }];
        });
    }];
    
    while (!finished) [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
}

- (void)tearDown {
    BOOL __block finished = NO;
    
    [[Telepat client] deleteAdminWithBlock:^(TelepatResponse *response) {
        finished = YES;
    }];
    
    while (!finished) [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    
    [super tearDown];
}

- (void)testAdminLogin {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing admin login"];
    
    [[Telepat client] adminLogin:username password:password withBlock:^(TelepatResponse *response) {
        TelepatAuthorization *auth = [response getObjectOfType:[TelepatAuthorization class]];
        XCTAssertEqualObjects(auth.user.email, username, @"Logged in user's email is not the same as the expected one");
        [[Telepat client] getCurrentAdminWithBlock:^(TelepatResponse *response) {
            TelepatUser *adminUser = [response getObjectOfType:[TelepatUser class]];
            NSLog(@"adminUser: %@", adminUser);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void) testCreateRemoveApp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing application adding"];
    
    [[Telepat client] createAppWithName:appName keys:@[apiKey] customFields:@{} block:^(TelepatResponse *response) {
        [[Telepat client] setApiKey:apiKey];
        TelepatApp *resultedApp = [response getObjectOfType:[TelepatApp class]];
        XCTAssertNotNil(resultedApp, @"createAppWithName didn't returned a valid application");
        XCTAssertNotNil(resultedApp.app_id, @"createAppWithName didn't returned a valid app_id");
        [[Telepat client] setAppId:resultedApp.app_id];
        [[Telepat client] listAppsWithBlock:^(TelepatResponse *response) {
            NSArray *apps = [response getObjectOfType:[TelepatApp class]];
            XCTAssertGreaterThanOrEqual([apps count], 1, @"listAppsWithBlock: %lu applications found, expected at least 1", (unsigned long)[apps count]);
            XCTAssertEqualObjects(resultedApp, [apps lastObject], @"listAppsWithBlock: received app is not the same like the created one");
            TelepatApp *updatedApp = [[TelepatApp alloc] initWithDictionary:[resultedApp toDictionary] error:nil];
            updatedApp.name = updatedAppName;
            [[Telepat client] updateApp:resultedApp withApp:updatedApp andBlock:^(TelepatResponse *response) {
                XCTAssertEqual(response.status, 200, @"updateApp: app update error");
                [[Telepat client] createContextWithName:@"TestContext" meta:@{@"info": contextInfo} withBlock:^(TelepatResponse *response) {
                    _createdContext = [response getObjectOfType:[TelepatContext class]];
                    XCTAssertNotNil([response getObjectOfType:[TelepatContext class]], @"createContextWithName: The server returned an invalid context");
                    XCTAssertEqualObjects(_createdContext.meta[@"info"], contextInfo, @"createContextWithName: context info doesn't match");
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [[Telepat client] getContextsWithBlock:^(TelepatResponse *response) {
                            XCTAssertGreaterThanOrEqual([[response getObjectOfType:[TelepatContext class]] count], 1, @"getContextsWithBlock: there should be at least one context");
                            [[Telepat client] getContext:_createdContext.context_id withBlock:^(TelepatResponse *response) {
                                TelepatContext *retrievedContext = [response getObjectOfType:[TelepatContext class]];
                                XCTAssertEqualObjects(_createdContext.meta[@"info"], retrievedContext.meta[@"info"]);
                                [[Telepat client] removeAppWithBlock:^(TelepatResponse *response) {
                                    XCTAssertEqual(response.status, 200);
                                    [expectation fulfill];
                                }];
                            }];
                        }];
                    });
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if(error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void) testRegisterUser {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing application adding"];
    
    NSLog(@"Registering device...");
    [[Telepat client] registerDeviceForWebsocketsWithBlock:^(TelepatResponse *response) {
        [[Telepat client] createAppWithName:appName keys:@[apiKey] customFields:@{} block:^(TelepatResponse *response) {
            [[Telepat client] setApiKey:apiKey];
            TelepatApp *resultedApp = [response getObjectOfType:[TelepatApp class]];
            XCTAssertNotNil(resultedApp, @"createAppWithName didn't returned a valid application");
            XCTAssertNotNil(resultedApp.app_id, @"createAppWithName didn't returned a valid app_id");
            [[Telepat client] setAppId:resultedApp.app_id];
            [[Telepat client] registerUser:username withPassword:password name:name andBlock:^(TelepatResponse *response) {
                XCTAssertEqual(response.status, 202, @"registerUser failed");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [[Telepat client] listAppUsersWithBlock:^(TelepatResponse *response) {
                        XCTAssertGreaterThanOrEqual([[response getObjectOfType:[TelepatUser class]] count], 1, @"listAppUsersWithBlock: at least one user should be returned");
                        [[Telepat client] deleteUser:username withBlock:^(TelepatResponse *response) {
                            [[Telepat client] removeAppWithBlock:^(TelepatResponse *response) {
                                [expectation fulfill];
                            }];
                        }];
                    }];
                });
            }];
        }];
    } shouldUpdateBackend:NO];
    
    [self waitForExpectationsWithTimeout:25.0 handler:^(NSError *error) {
        if(error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void) testAuthorizeAdmin {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing application adding"];
    
    [[Telepat client] adminAdd:authadminusername password:password name:name withBlock:^(TelepatResponse *response) {
        [[Telepat client] createAppWithName:appName keys:@[apiKey] customFields:@{} block:^(TelepatResponse *response) {
            [[Telepat client] setApiKey:apiKey];
            TelepatApp *resultedApp = [response getObjectOfType:[TelepatApp class]];
            XCTAssertNotNil(resultedApp, @"createAppWithName didn't returned a valid application");
            XCTAssertNotNil(resultedApp.app_id, @"createAppWithName didn't returned a valid app_id");
            [[Telepat client] setAppId:resultedApp.app_id];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [[Telepat client] authorizeAdmin:authadminusername withBlock:^(TelepatResponse *response) {
                    XCTAssertEqual(response.status, 200);
                    [[Telepat client] deauthorizeAdmin:authadminusername withBlock:^(TelepatResponse *response) {
                        XCTAssertEqual(response.status, 200);
                        [[Telepat client] removeAppWithBlock:^(TelepatResponse *response) {
                            [[Telepat client] deleteAdminWithBlock:^(TelepatResponse *response) {
                                [expectation fulfill];
                            }];
                        }];
                    }];
                }];
            });
        }];
    }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if(error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)testAdminDelete {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing application adding"];
    
    [[Telepat client] deleteAdminWithBlock:^(TelepatResponse *response) {
        XCTAssertEqual(response.status, 200, @"%ld Admin could not be deleted: %@", (long)response.status, response.message);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
