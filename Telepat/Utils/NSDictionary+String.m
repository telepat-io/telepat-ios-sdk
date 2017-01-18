//
//  NSDictionary+String.m
//  Pods
//
//  Created by Ovidiu D. Nitan on 05/01/2017.
//
//

#import "NSDictionary+String.h"

@implementation NSDictionary (String)

- (NSString *) stringRepresentation {
    NSMutableString *outputString = [[NSMutableString alloc] initWithString:@"{\n"];
    for (NSString *key in self.allKeys) {
        [outputString appendFormat:@"    %@: %@\n", key, [self objectForKey:key]];
    }
    [outputString appendString:@"}"];
    
    return [[NSString alloc] initWithString:outputString];
}

@end
