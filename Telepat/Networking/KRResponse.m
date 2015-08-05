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
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.dict options:NSJSONWritingPrettyPrinted error:nil];
    if (jsonData) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (NSString *) description {
    if (self.error) {
        return [NSString stringWithFormat:@"<KRResponse %p> status: %ld  content: %@ </KRResponse>", self, (long)self.status, [self asString]];
    }
    
    return [NSString stringWithFormat:@"<KRResponse %p> status: %ld  content: %@ </KRResponse>", self, (long)self.status, [self asString]];
}

@end
