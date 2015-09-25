//
//  KRBaseObject.h
//  Kraken
//
//  Created by Ovidiu on 24/06/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "JSONModel.h"

@interface TelepatBaseObject : JSONModel

@property (nonatomic) NSString *object_id;
@property (nonatomic) NSString<Optional> *uuid;

- (NSDictionary *) patchAgainst:(TelepatBaseObject *)updatedObject;
- (NSArray *) propertiesList;

@end
