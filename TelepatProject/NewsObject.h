//
//  NewsObject.h
//  TelepatProject
//
//  Created by Ovidiu D. Nitan on 15/11/2016.
//  Copyright © 2016 Telepat. All rights reserved.
//

#import <Telepat/Telepat.h>

@interface NewsObject : TelepatBaseObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSString *body;
@property (nonatomic) CLLocationCoordinate2D location_geolocation;

@end
