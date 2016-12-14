//
//  NewsObject.m
//  TelepatProject
//
//  Created by Ovidiu D. Nitan on 15/11/2016.
//  Copyright © 2016 Telepat. All rights reserved.
//

#import "NewsObject.h"

@implementation NewsObject

+ (BOOL) propertyIsOptional:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"location_geolocation"]) return YES;
    
    return NO;
}

- (void) setLocation_geolocationWithNSString:(NSString *)string {
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    self.location_geolocation = CLLocationCoordinate2DMake([dictionary[@"lat"] floatValue], [dictionary[@"lon"] floatValue]);
}

- (void) setLocation_geolocationWithNSDictionary:(NSDictionary *)dictionary {
    self.location_geolocation = CLLocationCoordinate2DMake([dictionary[@"lat"] floatValue], [dictionary[@"lon"] floatValue]);
}

- (NSString *) JSONObjectForLocation_geolocation {
    NSDictionary *resultDict = @{@"lat": [NSString stringWithFormat:@"%f", self.location_geolocation.latitude],
                                 @"lon": [NSString stringWithFormat:@"%f", self.location_geolocation.longitude]};
    NSData *resultData = [NSJSONSerialization dataWithJSONObject:resultDict options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
}

@end
