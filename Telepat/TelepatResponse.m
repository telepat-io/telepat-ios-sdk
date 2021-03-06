//
//  TelepatResponse.m
//  Kraken
//
//  Created by Ovidiu on 29/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "TelepatResponse.h"
#import "Telepat.h"

@interface TelepatResponseModel : JSONModel
@property (nonatomic) NSInteger status;
@property (nonatomic, strong) id<Optional, NSObject> content;
@property (nonatomic, strong) NSString<Optional> *message;
@property (nonatomic, strong) NSError<Ignore> *error;
@end

@implementation TelepatResponseModel

@end

@implementation TelepatResponse

- (id) initWithDictionary:(NSDictionary *)dictionary error:(NSError *)error {
    if (self = [super init]) {
        if (error) {
            self.error = error;
            self.status = dictionary[@"status"] ? [dictionary[@"status"] integerValue] : error.code;
            self.message = dictionary[@"message"];
            self.code = dictionary[@"code"];
            return self;
        }
        
        NSError *err;
        TelepatResponseModel *responseModel = [[TelepatResponseModel alloc] initWithDictionary:dictionary error:&err];
        
        if (err) {
            self.error = err;
            return self;
        } else {
            self.status = responseModel.status;
            self.content = responseModel.content;
            self.message = responseModel.message;
        }
    }
    
    return self;
}

- (BOOL) isError {
    return self.error != nil;
}

- (id) getObjectOfType:(Class)classType {
    id obj;
    if ([self.content isKindOfClass:[NSDictionary class]]) {
        NSError *err;
        obj = [[classType alloc] initWithDictionary:(NSDictionary*)self.content error:&err];
        if (err) {
            self.error = err;
            if (err) DDLogError(@"%@", err.userInfo);
        }
    } else if ([self.content isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (NSDictionary *dict in (NSArray *)self.content) {
            NSError *err;
            obj = [[classType alloc] initWithDictionary:dict error:&err];
            if (err) DDLogError(@"%@", err.userInfo);
            else [array addObject:obj];
        }
        obj = array;
    }
    return obj;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"<TelepatResponse: %p>\nstatus: %ld\ncontent: %@", self, (long)self.status, self.content ? self.content : self.message];
}

@end
