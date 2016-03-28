//
//  KRResponse.m
//  Kraken
//
//  Created by Ovidiu on 06/03/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "KRResponse.h"

@implementation KRResponse

- (id) initWithDictionary:(NSDictionary *)dict andStatus:(NSInteger)status {
    if (self = [super init]) {
        self.dict = dict ? dict : @{};
        self.status = status;
        self.data = [NSJSONSerialization dataWithJSONObject:self.dict options:NSJSONWritingPrettyPrinted error:nil];
    }
    
    return self;
}

- (id) initWithData:(NSData *)data andStatus:(NSInteger)status {
    if (self = [super init]) {
        self.dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        self.status = status;
        self.data = data;
    }
    
    return self;
}

- (id) initWithError:(NSError *)error {
    if (self = [super init]) {
        self.error = error;
        self.status = [error.userInfo[@"com.alamofire.serialization.response.error.response"] statusCode];
        if (self.error.userInfo[@"com.alamofire.serialization.response.error.data"])
            self.dict = [NSJSONSerialization JSONObjectWithData:self.error.userInfo[@"com.alamofire.serialization.response.error.data"] options:kNilOptions error:nil];
    }
    
    return self;
}

- (NSString *) asString {
    if (self.error) return [[NSString alloc] initWithData:self.error.userInfo[@"com.alamofire.serialization.response.error.data"] encoding:NSUTF8StringEncoding];
    return [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
}

- (NSString *) description {
    if (self.error) {
        return [NSString stringWithFormat:@"<KRResponse %p> status: %ld  content: %@ </KRResponse>", self, (long)self.status, [self asString]];
    }
    
    return [NSString stringWithFormat:@"<KRResponse %p> status: %ld  content: %@ </KRResponse>", self, (long)self.status, [self asString]];
}

@end
