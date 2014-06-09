//
//  http_request.h
//  http-request
//
//  Created by Elmar Langholz on 4/10/14.
//  Copyright (c) 2014 Elmar Langholz. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kHttpRequestDomain              @"http-request"

#define kApplicationJsonContentType     @"application/json"
#define kTextHtmlContentType            @"text/html"

#define kGetHttpMethod                  @"GET"
#define kPatchHttpMethod                @"PATCH"
#define kPutHttpMethod                  @"PUT"
#define kPostHttpMethod                 @"POST"
#define kDeleteHttpMethod               @"DELETE"

/**
 *  http_request is an iOS light-weight library that simplifies asynchronous HTTP operations.
 */
@interface http_request : NSObject
{
    NSURLSession *_session;
}

/**
 *  The body parser block property.
 */
@property (copy) id (^bodyParser)(NSURLResponse *, NSData *, NSError *__autoreleasing *);

/**
 *  The body serializer block property.
 */
@property (copy) NSData *(^bodySerializer)(id, NSError *__autoreleasing *);

/**
 *  The response validator block property.
 */
@property (copy) BOOL (^responseValidator)(NSURLResponse *, id body, NSError *__autoreleasing *);

/**
 *  Determines whether or not the status code is informational.
 *
 *  @param statusCode The HTTP status code.
 *
 *  @return YES if it is informational; otherwise, NO.
 */
+ (BOOL)isInformationalStatusCode:(int)statusCode;

/**
 *  Determines whether or not the status code is successful.
 *
 *  @param statusCode The HTTP status code.
 *
 *  @return YES if it is successful; otherwise, NO.
 */
+ (BOOL)isSuccessStatusCode:(int)statusCode;

/**
 *  Determines whether or not the status code is redirection.
 *
 *  @param statusCode The HTTP status code.
 *
 *  @return YES if it is redirection; otherwise, NO.
 */
+ (BOOL)isRedirectionStatusCode:(int)statusCode;

/**
 *  Determines whether or not the status code is a client error.
 *
 *  @param statusCode The HTTP status code.
 *
 *  @return YES if it is a client error; otherwise, NO.
 */
+ (BOOL)isClientErrorStatusCode:(int)statusCode;

/**
 *  Determines whether or not the status code is a server error.
 *
 *  @param statusCode The HTTP status code.
 *
 *  @return YES if it is a server error; otherwise, NO.
 */
+ (BOOL)isServerErrorStatusCode:(int)statusCode;

/**
 *  Constructs an HTTP request given the provided parameters.
 *
 *  @param method  The HTTP method (e.g. @"GET", @"PUT", @"POST, @"PATCH", @"DELETE", ...). Must not be nil.
 *  @param url     The uniform resource locator to retrieve the content from. Must not be nil.
 *  @param headers The HTTP headers to provide as part of the request. Optional, can be nil.
 *  @param data    The data to use in the body of the request. Optional, can be nil.
 *
 *  @return The constructed HTTP request.
 */
+ (NSMutableURLRequest *)constructRequest:(NSString *)method
                                  withUrl:(NSURL *)url
                              withHeaders:(NSDictionary *)headers
                                 withBody:(NSData *)data;

/**
 *  Validates the HTTP response of a request.
 *
 *  @param response The response to validate. Must not be nil.
 *  @param body     The response body. Optional, can be nil.
 *  @param error    The error, if any. Must not be nil.
 *
 *  @return Determines whether there was a reponse error or not.
 */
+ (BOOL)isValidResponse:(NSURLResponse *)response withBody:(id)body error:(NSError *__autoreleasing *)error;

/**
 *  Parses the data given a response.
 *
 *  @param response The response. Must not be nil.
 *  @param data     The data to parse as the body. Optional, can be nil.
 *  @param error    The error, if any. Must not be nil.
 *
 *  @return The parsed body in its corresponding representation.
 */
+ (id)parseBody:(NSURLResponse *)response withBody:(NSData *)data error:(NSError *__autoreleasing *)error;

/**
 *  Serializes the body for a request.
 *
 *  @param body  The data to serialize as the body. Optional, can be nil.
 *  @param error The error, if any. Must not be nil.
 *
 *  @return The serialized body in its corresponding representation.
 */
+ (NSData *)serializeBody:(id)body error:(NSError *__autoreleasing *)error;

/**
 *  Converts the provided NSData into its JSON representation.
 *
 *  @param data  The data to parse. Optional, can be nil.
 *  @param error The error, if any. Must not be nil.
 *
 *  @return The NSDictionary representing the parsed data.
 */
+ (id)jsonDataParser:(NSData *)data error:(NSError *__autoreleasing *)error;

/**
 *  Converts the provided NSData into its String representation.
 *
 *  @param data  The data to parse. Optional, can be nil.
 *  @param error The error, if any. Must not be nil.
 *
 *  @return The NSString representing the parsed data.
 */
+ (id)stringDataParser:(NSData *)data error:(NSError *__autoreleasing *)error;

/**
 *  Converts the provided String into its NSData representation.
 *
 *  @param str   The String to serialize. Optional, can be nil.
 *  @param error The error, if any. Must not be nil.
 *
 *  @return The NSData representing the serialized String.
 */
+ (NSData *)serializeString:(NSString *)str error:(NSError *__autoreleasing *)error;

/**
 *  Converts the provided JSON into its NSData representation.
 *
 *  @param dict  The JSON to serialize. Optional, can be nil.
 *  @param error The error, if any. Must not be nil.
 *
 *  @return The NSData representing the serialized JSON.
 */
+ (NSData *)serializeJson:(NSDictionary *)dict error:(NSError *__autoreleasing *)error;

/**
 *  The default instance initializer.
 *
 *  @return An instance of class.
 */
- (id)init;

/**
 *  Initializes the instance with a provided configuration.
 *
 *  @param sessionConfiguration The session configuration used to initialize the instance.
 *
 *  @return An instance of class.
 */
- (id)initWithConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

/**
 *  Get the content for the provided url.
 *
 *  @param url     The uniform resource locator to retrieve the content from. Must not be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)getAsync:(NSURL *)url
                         onSuccess:(void(^)(NSURLResponse *, id))success
                           onError:(void(^)(NSError *))error;

/**
 *  Get the content for the provided url.
 *
 *  @param url     The uniform resource locator to retrieve the content from. Must not be nil.
 *  @param headers The HTTP headers to provide as part of the request. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)getAsync:(NSURL *)url
                       withHeaders:(NSDictionary *)headers
                         onSuccess:(void(^)(NSURLResponse *, id))success
                           onError:(void(^)(NSError *))error;

/**
 *  Put the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param data    The NSData to be used as the body of the request and with which to put the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)putAsync:(NSURL *)url
                          withBody:(NSData *)data
                         onSuccess:(void(^)(NSURLResponse *, id))success
                           onError:(void(^)(NSError *))error;

/**
 *  Put the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param str     The NSString to be used as the body of the request and with which to put the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)putAsync:(NSURL *)url
                        withString:(NSString *)str
                         onSuccess:(void(^)(NSURLResponse *, id))success
                           onError:(void(^)(NSError *))error;

/**
 *  Put the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param dict    The NSDictionary to be used as the body of the request and with which to put the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)putAsync:(NSURL *)url
                          withJson:(NSDictionary *)dict
                         onSuccess:(void(^)(NSURLResponse *, id))success
                           onError:(void(^)(NSError *))error;

/**
 *  Put the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param headers The NSDitionary representing the headers to set for the request. Optional, can be nil.
 *  @param data    The NSData to be used as the body of the request and with which to put the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)putAsync:(NSURL *)url
                       withHeaders:(NSDictionary *)headers
                          withBody:(NSData *)data
                         onSuccess:(void(^)(NSURLResponse *, id))success
                           onError:(void(^)(NSError *))error;

/**
 *  Put the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param headers The NSDitionary representing the headers to set for the request. Optional, can be nil.
 *  @param str     The NSString to be used as the body of the request and with which to put the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)putAsync:(NSURL *)url
                       withHeaders:(NSDictionary *)headers
                        withString:(NSString *)str
                         onSuccess:(void(^)(NSURLResponse *, id))success
                           onError:(void(^)(NSError *))error;

/**
 *  Put the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param headers The NSDitionary representing the headers to set for the request. Optional, can be nil.
 *  @param dict    The NSDictionary to be used as the body of the request and with which to put the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)putAsync:(NSURL *)url
                       withHeaders:(NSDictionary *)headers
                          withJson:(NSDictionary *)dict
                         onSuccess:(void(^)(NSURLResponse *, id))success
                           onError:(void(^)(NSError *))error;

/**
 *  Post the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param data    The NSData to be used as the body of the request and with which to post the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)postAsync:(NSURL *)url
                           withBody:(NSData *)data
                          onSuccess:(void(^)(NSURLResponse *, id))success
                            onError:(void(^)(NSError *))error;

/**
 *  Post the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param str     The NSString to be used as the body of the request and with which to post the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)postAsync:(NSURL *)url
                         withString:(NSString *)str
                          onSuccess:(void(^)(NSURLResponse *, id))success
                            onError:(void(^)(NSError *))error;

/**
 *  Post the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param dict    The NSDictionary to be used as the body of the request and with which to post the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)postAsync:(NSURL *)url
                           withJson:(NSDictionary *)dict
                          onSuccess:(void(^)(NSURLResponse *, id))success
                            onError:(void(^)(NSError *))error;

/**
 *  Post the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param headers The NSDitionary representing the headers to set for the request. Optional, can be nil.
 *  @param data    The NSData to be used as the body of the request and with which to post the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)postAsync:(NSURL *)url
                        withHeaders:(NSDictionary *)headers
                           withBody:(NSData *)data
                          onSuccess:(void(^)(NSURLResponse *, id))success
                            onError:(void(^)(NSError *))error;

/**
 *  Post the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param headers The NSDitionary representing the headers to set for the request. Optional, can be nil.
 *  @param str     The NSString to be used as the body of the request and with which to post the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)postAsync:(NSURL *)url
                        withHeaders:(NSDictionary *)headers
                         withString:(NSString *)str
                          onSuccess:(void(^)(NSURLResponse *, id))success
                            onError:(void(^)(NSError *))error;

/**
 *  Post the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param headers The NSDitionary representing the headers to set for the request. Optional, can be nil.
 *  @param dict    The NSDictionary to be used as the body of the request and with which to post the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)postAsync:(NSURL *)url
                        withHeaders:(NSDictionary *)headers
                           withJson:(NSDictionary *)dict
                          onSuccess:(void(^)(NSURLResponse *, id))success
                            onError:(void(^)(NSError *))error;

/**
 *  Patch the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param data    The NSData to be used as the body of the request and with which to patch the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)patchAsync:(NSURL *)url
                            withBody:(NSData *)data
                           onSuccess:(void(^)(NSURLResponse *, id))success
                             onError:(void(^)(NSError *))error;

/**
 *  Patch the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param str     The NSString to be used as the body of the request and with which to patch the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)patchAsync:(NSURL *)url
                          withString:(NSString *)str
                           onSuccess:(void(^)(NSURLResponse *, id))success
                             onError:(void(^)(NSError *))error;

/**
 *  Patch the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param dict    The NSDictionary to be used as the body of the request and with which to patch the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)patchAsync:(NSURL *)url
                            withJson:(NSDictionary *)dict
                           onSuccess:(void(^)(NSURLResponse *, id))success
                             onError:(void(^)(NSError *))error;

/**
 *  Patch the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param headers The NSDitionary representing the headers to set for the request. Optional, can be nil.
 *  @param data    The NSData to be used as the body of the request and with which to patch the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)patchAsync:(NSURL *)url
                         withHeaders:(NSDictionary *)headers
                            withBody:(NSData *)data
                           onSuccess:(void(^)(NSURLResponse *, id))success
                             onError:(void(^)(NSError *))error;

/**
 *  Patch the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param headers The NSDitionary representing the headers to set for the request. Optional, can be nil.
 *  @param str     The NSString to be used as the body of the request and with which to patch the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)patchAsync:(NSURL *)url
                         withHeaders:(NSDictionary *)headers
                          withString:(NSString *)str
                           onSuccess:(void(^)(NSURLResponse *, id))success
                             onError:(void(^)(NSError *))error;

/**
 *  Patch the content for the provided url.
 *
 *  @param url     The uniform resource locator to update the content with. Must not be nil.
 *  @param headers The NSDitionary representing the headers to set for the request. Optional, can be nil.
 *  @param dict    The NSDictionary to be used as the body of the request and with which to patch the url with. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)patchAsync:(NSURL *)url
                         withHeaders:(NSDictionary *)headers
                            withJson:(NSDictionary *)dict
                           onSuccess:(void(^)(NSURLResponse *, id))success
                             onError:(void(^)(NSError *))error;

/**
 *  Removes the content for the provided url.
 *
 *  @param url     The uniform resource locator to retrieve the content from. Must not be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)deleteAsync:(NSURL *)url
                            onSuccess:(void(^)(NSURLResponse *, id))success
                              onError:(void(^)(NSError *))error;

/**
 *  Removes the content for the provided url.
 *
 *  @param url     The uniform resource locator to retrieve the content from. Must not be nil.
 *  @param headers The HTTP headers to provide as part of the request. Optional, can be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)deleteAsync:(NSURL *)url
                          withHeaders:(NSDictionary *)headers
                            onSuccess:(void(^)(NSURLResponse *, id))success
                              onError:(void(^)(NSError *))error;

/**
 *  Issues an HTTP request, parses the response body and validates the status code.
 *
 *  @param request The HTTP request to issue. Must not be nil.
 *  @param success The callback called upon success; passes the response and the body. Must not be nil.
 *  @param error   The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)issueAsync:(NSMutableURLRequest *)request
                           onSuccess:(void(^)(NSURLResponse *, id))success
                             onError:(void(^)(NSError *))error;

/**
 *  Issues an HTTP request, parses the response body and validates the status code.
 *
 *  @param request          The HTTP request to issue. Must not be nil.
 *  @param bodyParser       The parser used to convert the body. Optional, can be nil.
 *  @param validateResponse The validator used to check the response. Optional, can be nil.
 *  @param successCallback  The callback called upon success; passes the response and the body. Must not be nil.
 *  @param errorCallback    The callback called upon error; passes an NSError. Must not be nil.
 *
 *  @return The task representing the operation.
 */
- (NSURLSessionDataTask *)issueAsync:(NSMutableURLRequest *)request
                      withBodyParser:(id (^)(NSURLResponse *, NSData *, NSError *__autoreleasing *))bodyParser
              withResponseValidation:(BOOL (^)(NSURLResponse *, id, NSError *__autoreleasing *))validateResponse
                           onSuccess:(void (^)(NSURLResponse *, id))successCallback
                             onError:(void (^)(NSError *))errorCallback;

@end
