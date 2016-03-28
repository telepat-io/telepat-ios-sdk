//
//  TelepatProxyRequest.h
//  Pods
//
//  Created by Ovidiu on 28/03/16.
//
//

#import <Foundation/Foundation.h>
#import <JSONModel.h>

typedef NS_ENUM(NSInteger, HTTPMethod) {
    HTTPMethodPost,
    HTTPMethodGet,
    HTTPMethodPut,
    HTTPMethodDelete
};

@interface TelepatProxyRequest : JSONModel

@property (nonatomic, strong) NSURL *url;
@property (nonatomic) HTTPMethod method;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSString *body;

- (id) initWithURL:(NSURL *)url method:(HTTPMethod)method headers:(NSDictionary *)headers body:(NSString *)body;

@end
