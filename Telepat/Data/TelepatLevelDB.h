//
//  TelepatLevelDB.h
//  Kraken
//
//  Created by Ovidiu on 15/07/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "LevelDB.h"
#import "TelepatDatabaseProtocol.h"

@interface TelepatLevelDB : LevelDB <TelepatDatabaseProtocol>

@end
