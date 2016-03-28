//
//  KRResponse.h
//  Kraken
//
//  Created by Ovidiu on 06/03/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KRResponse : NSObject

@property (nonatomic, strong) NSDictionary *dict;
@property (nonatomic, strong) NSData *data;
@property (nonatomic) NSInteger status;
@property (nonatomic, strong) NSError *error;

- (id) initWithDictionary:(NSDictionary *)dict andStatus:(NSInteger)status;
- (id) initWithData:(NSData *)data andStatus:(NSInteger)status;
- (id) initWithError:(NSError *)error;

- (NSData *) asData;
- (NSString *) asString;

@end
