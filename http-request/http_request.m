//
//  http_request.m
//  http-request
//
//  Created by Elmar Langholz on 4/10/14.
//  Copyright (c) 2014 Elmar Langholz. All rights reserved.
//

#import "http_request.h"

@interface http_request()

- (int)getMostSignificantDigit:(int)value;
- (BOOL)mostSignificantDigitEquals:(int)value1 equals:(int)value2;
- (void)raiseExceptionOnInvalidStatusCodeRange:(int)statusCode;
- (void)sessionDataTaskCompletionHandler:(NSData *)data
                            withResponse:(NSURLResponse *)response
                                   error:(NSError *)error
                               onSuccess:(void(^)(NSDictionary *))successCallback
                                 onError:(void(^)(NSError*))errorCallback;

@end

@implementation http_request

static http_request *sharedInstance = nil;
static dispatch_once_t initializationLock;

#pragma mark - Public API

+ (id)shared
{
    dispatch_once(&initializationLock, ^{sharedInstance = [[http_request alloc] initInternal];});
    return sharedInstance;
}

- (BOOL)isInformationalStatusCode:(int)statusCode
{
    [self raiseExceptionOnInvalidStatusCodeRange:statusCode];
    return [self mostSignificantDigitEquals:statusCode equals:1];
}

- (BOOL)isSuccessStatusCode:(int)statusCode
{
    [self raiseExceptionOnInvalidStatusCodeRange:statusCode];
    return [self mostSignificantDigitEquals:statusCode equals:2];
}

- (BOOL)isRedirectionStatusCode:(int)statusCode
{
    [self raiseExceptionOnInvalidStatusCodeRange:statusCode];
    return [self mostSignificantDigitEquals:statusCode equals:3];
}

- (BOOL)isClientErrorStatusCode:(int)statusCode
{
    [self raiseExceptionOnInvalidStatusCodeRange:statusCode];
    return [self mostSignificantDigitEquals:statusCode equals:4];
}

- (BOOL)isServerErrorStatusCode:(int)statusCode
{
    [self raiseExceptionOnInvalidStatusCodeRange:statusCode];
    return [self mostSignificantDigitEquals:statusCode equals:5];
}

- (NSURLSessionDataTask *)issueHttpRequestAsync:(NSURL *)url
                                    withRequest:(NSMutableURLRequest *)request
                                      onSuccess:(void (^)(NSDictionary *))successCallback
                                        onError:(void (^)(NSError *))errorCallback
{
    NSURLSessionDataTask *dataTask = [_session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                                  {
                                                      [self sessionDataTaskCompletionHandler:data
                                                                                withResponse:response
                                                                                       error:error
                                                                                   onSuccess:successCallback
                                                                                     onError:errorCallback];
                                                  }];
    [dataTask resume];
    return dataTask;
}

#pragma mark - Internal API

- (void)raiseExceptionOnInvalidStatusCodeRange:(int)statusCode
{
    if (statusCode < 100 || statusCode >= 600)
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Invalid status code value: not within range"
                                     userInfo:nil];
    }
}

- (BOOL)mostSignificantDigitEquals:(int)value1 equals:(int)value2
{
    int mostSignificantDigit = [self getMostSignificantDigit:(int)value1];
    BOOL equals = mostSignificantDigit == value2;
    return equals;
}

- (int)getMostSignificantDigit:(int)value
{
    int numberOfDigits = (int)log10(value);
    return value / pow(10, numberOfDigits);
}

- (void)sessionDataTaskCompletionHandler:(NSData *)data
                            withResponse:(NSURLResponse *)response
                                   error:(NSError *)error
                               onSuccess:(void (^)(NSDictionary *))successCallback
                                 onError:(void (^)(NSError *))errorCallback
{
    if (!error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        BOOL successStatusCode = [self isSuccessStatusCode:(int)httpResponse.statusCode];
        if (successStatusCode) {
            NSError *jsonDeserializationError = nil;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                         options:0
                                                                           error:&jsonDeserializationError];
            if (jsonDeserializationError)
            {
                errorCallback(jsonDeserializationError);
            }
            else
            {
                successCallback(jsonResponse);
            }
        }
        else
        {
            NSError *statusCodeError = [[NSError alloc] initWithDomain:@"http_request.response"
                                                                  code:httpResponse.statusCode
                                                              userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Invalid response status code %ld", (long)httpResponse.statusCode] forKey:NSLocalizedDescriptionKey]];
            errorCallback(statusCodeError);
        }
    }
    else
    {
        errorCallback(error);
    }
}

#pragma mark - Initialization

- (id)initInternal
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        [sessionConfiguration setHTTPAdditionalHeaders:@{@"Accept": @"application/json"}];
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    }
    return self;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"There can only be one http_request instance."
                                 userInfo:nil];
    return nil;
}

@end
