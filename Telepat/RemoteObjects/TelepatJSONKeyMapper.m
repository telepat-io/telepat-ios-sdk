//
//  TelepatJSONKeyMapper.m
//  Pods
//
//  Created by Ovidiu on 19/11/15.
//
//

#import "TelepatJSONKeyMapper.h"

@interface JSONKeyMapper()

- (NSDictionary *)swapKeysAndValuesInDictionary:(NSDictionary *)dictionary;

@end

@implementation TelepatJSONKeyMapper
@synthesize JSONToModelKeyBlock, modelToJSONKeyBlock;

- (instancetype)initWithDictionary:(NSDictionary *)map {
    self = [super initWithDictionary:map];
    if (self) {
        self.map = map;
    }
    return self;
}

- (instancetype) newKeyMapperWithDictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *mutableMap = [NSMutableDictionary dictionaryWithDictionary:self.map];
    [mutableMap addEntriesFromDictionary:dictionary];
    
    TelepatJSONKeyMapper *keyMapper = [[TelepatJSONKeyMapper alloc] initWithDictionary:[NSDictionary dictionaryWithDictionary:mutableMap]];
    return keyMapper;
}

@end
