//
//  http_request.h
//  http-request
//
//  Created by Elmar Langholz on 4/10/14.
//  Copyright (c) 2014 Elmar Langholz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface http_request : NSObject
{
    NSURLSession *_session;
}

+ (id)shared;
- (BOOL)isInformationalStatusCode:(int)statusCode;
- (BOOL)isSuccessStatusCode:(int)statusCode;
- (BOOL)isRedirectionStatusCode:(int)statusCode;
- (BOOL)isClientErrorStatusCode:(int)statusCode;
- (BOOL)isServerErrorStatusCode:(int)statusCode;
- (NSURLSessionDataTask *)issueHttpRequestAsync:(NSURL *)url
                                    withRequest:(NSMutableURLRequest *)request
                                      onSuccess:(void(^)(NSDictionary *))successCallback
                                        onError:(void(^)(NSError*))errorCallback;

@end
