//
//  TelepatJSONKeyMapper.h
//  Pods
//
//  Created by Ovidiu on 19/11/15.
//
//

#import <JSONModel/JSONModel.h>

@interface TelepatJSONKeyMapper : JSONKeyMapper

@property (nonatomic, strong) NSDictionary *map;
@property (nonatomic, copy, readwrite) JSONModelKeyMapBlock JSONToModelKeyBlock;
@property (nonatomic, copy, readwrite) JSONModelKeyMapBlock modelToJSONKeyBlock;

- (instancetype) newKeyMapperWithDictionary:(NSDictionary *)dictionary;

@end
