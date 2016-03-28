//
//  TelepatProxyRequest.m
//  Pods
//
//  Created by Ovidiu on 28/03/16.
//
//

#import "TelepatProxyRequest.h"

@implementation TelepatProxyRequest

- (id) initWithURL:(NSURL *)url method:(HTTPMethod)method headers:(NSDictionary *)headers body:(NSString *)body {
    self = [super init];
    if (self) {
        self.url = url;
        self.method = method;
        self.headers = headers;
        self.body = body;
    }
    return self;
}

- (void) setMethodWithNSString:(NSString *)string {
    if ([string isEqualToString:@"GET"]) {
        self.method = HTTPMethodGet;
    } else if ([string isEqualToString:@"POST"]) {
        self.method = HTTPMethodPost;
    } else if ([string isEqualToString:@"PUT"]) {
        self.method = HTTPMethodPut;
    } else if ([string isEqualToString:@"DELETE"]) {
        self.method = HTTPMethodDelete;
    } else {
        self.method = HTTPMethodGet;
    }
}

- (NSString *) JSONObjectForMethod  {
    switch (self.method) {
        case HTTPMethodGet:
            return @"GET";
            break;
            
        case HTTPMethodPut:
            return @"PUT";
            break;
            
        case HTTPMethodPost:
            return @"POST";
            break;
            
        case HTTPMethodDelete:
            return @"DELETE";
            
        default:
            return @"GET";
            break;
    }
}

@end
