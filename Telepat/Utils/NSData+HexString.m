//
//  NSData+HexString.m
//  GW Sales
//
//  Created by Ovidiu on 21/07/15.
//  Copyright (c) 2015 Appscend. All rights reserved.
//

#import "NSData+HexString.h"

@implementation NSData (HexString)

-(NSString*) dataToHex {
    const unsigned char *dbytes = [self bytes];
    NSMutableString *hexStr =
    [NSMutableString stringWithCapacity:[self length]*2];
    int i;
    for (i = 0; i < [self length]; i++) {
        [hexStr appendFormat:@"%02x", dbytes[i]];
    }
    return [NSString stringWithString: hexStr];
}

@end
