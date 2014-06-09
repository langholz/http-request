//
//  http_request.m
//  http-request
//
//  Created by Elmar Langholz on 4/10/14.
//  Copyright (c) 2014 Elmar Langholz. All rights reserved.
//

#import "http_request.h"

@interface http_request()

+ (void)throwIfNil:(id)parameter withName:(NSString *)parameterName;
+ (BOOL)isNotNil:(id)value;
+ (int)getMostSignificantDigit:(int)value;
+ (BOOL)mostSignificantDigitEquals:(int)value1 equals:(int)value2;
+ (void)raiseExceptionOnInvalidStatusCodeRange:(int)statusCode;

- (void)configureBodyParser;
- (void)configureBodySerializer;
- (void)configureResponseValidator;

- (NSURLSessionDataTask *)callBodySerializeAndExecuteAsync:(NSString *)method
                                                       url:(NSURL *)url
                                               withHeaders:(NSDictionary *)headers
                                                  withBody:(id)body
                                                 onSuccess:(void (^)(NSURLResponse *, id))success
                                                   onError:(void (^)(NSError *))error;
- (void)dataTaskCompletionHandler:(NSURLResponse *)response
                         withBody:(NSData *)data
                   withBodyParser:(id (^)(NSURLResponse *, NSData *, NSError *__autoreleasing *))bodyParser
           withResponseValidation:(BOOL (^)(NSURLResponse *, id, NSError *__autoreleasing *))validateResponse
                            error:(NSError *)error
                        onSuccess:(void(^)(NSURLResponse *, id))successCallback
                          onError:(void(^)(NSError *))errorCallback;

@end

@implementation http_request

#pragma mark - Public API

+ (BOOL)isInformationalStatusCode:(int)statusCode
{
    [http_request raiseExceptionOnInvalidStatusCodeRange:statusCode];
    return [http_request mostSignificantDigitEquals:statusCode equals:1];
}

+ (BOOL)isSuccessStatusCode:(int)statusCode
{
    [http_request raiseExceptionOnInvalidStatusCodeRange:statusCode];
    return [http_request mostSignificantDigitEquals:statusCode equals:2];
}

+ (BOOL)isRedirectionStatusCode:(int)statusCode
{
    [http_request raiseExceptionOnInvalidStatusCodeRange:statusCode];
    return [http_request mostSignificantDigitEquals:statusCode equals:3];
}

+ (BOOL)isClientErrorStatusCode:(int)statusCode
{
    [http_request raiseExceptionOnInvalidStatusCodeRange:statusCode];
    return [http_request mostSignificantDigitEquals:statusCode equals:4];
}

+ (BOOL)isServerErrorStatusCode:(int)statusCode
{
    [http_request raiseExceptionOnInvalidStatusCodeRange:statusCode];
    return [http_request mostSignificantDigitEquals:statusCode equals:5];
}

+ (NSMutableURLRequest *)constructRequest:(NSString *)method
                                  withUrl:(NSURL *)url
                              withHeaders:(NSDictionary *)headers
                                 withBody:(NSData *)data
{
    [http_request throwIfNil:method withName:@"method"];
    [http_request throwIfNil:url withName:@"url"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:[method uppercaseString]];
    
    if (headers)
    {
        [request setAllHTTPHeaderFields:headers];
    }
    
    if (data)
    {
        [request setHTTPBody:data];
    }
    
    return request;
}

+ (BOOL)isValidResponse:(NSURLResponse *)response withBody:(id)body error:(NSError *__autoreleasing *)error
{
    [http_request throwIfNil:response withName:@"response"];
    
    *error = nil;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    BOOL successStatusCode = [http_request isSuccessStatusCode:(int)httpResponse.statusCode];
    if (!successStatusCode)
    {
        NSString *localizedErrorAsString = [NSString
                                            stringWithFormat:@"Unsuccessful response. Status code: %ld",
                                            httpResponse.statusCode];
        *error = [[NSError alloc]
                  initWithDomain:kHttpRequestDomain
                  code:-1011
                  userInfo:@{NSLocalizedDescriptionKey:localizedErrorAsString,
                             @"Response": httpResponse,
                             @"Body": body}];
    }
    
    return successStatusCode;
}

+ (id)parseBody:(NSURLResponse *)response withBody:(NSData *)data error:(NSError *__autoreleasing *)error
{
    [http_request throwIfNil:response withName:@"response"];

    *error = nil;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    id parsedData = data;
    NSString *contentType = [[httpResponse allHeaderFields] valueForKey:@"Content-Type"];
    if ([http_request isNotNil:contentType] && [http_request isNotNil:data])
    {
        if ([contentType caseInsensitiveCompare:kApplicationJsonContentType] == NSOrderedSame)
        {
            parsedData = [http_request jsonDataParser:data error:error];
        }
        else if ([contentType caseInsensitiveCompare:kTextHtmlContentType] == NSOrderedSame)
        {
            parsedData = [http_request stringDataParser:data error:error];
        }
    }
    
    return parsedData;
}

+ (NSData *)serializeBody:(id)body error:(NSError *__autoreleasing *)error
{
    *error = nil;
    NSData *bodyAsData = nil;
    if ([http_request isNotNil:body])
    {
        if ([body isKindOfClass:[NSString class]])
        {
            bodyAsData = [http_request serializeString:body error:error];
        }
        else if ([body isKindOfClass:[NSDictionary class]])
        {
            bodyAsData = [http_request serializeJson:body error:error];
        }
        else if ([body isKindOfClass:[NSData class]])
        {
            bodyAsData = body;
        }
        else
        {
            *error = [[NSError alloc]
                      initWithDomain:kHttpRequestDomain
                      code:-1
                      userInfo:@{NSLocalizedDescriptionKey:@"Unknown body data type"}];
        }
    }
    
    return bodyAsData;
}

+ (id)jsonDataParser:(NSData *)data error:(NSError *__autoreleasing *)error
{
    *error = nil;
    NSDictionary *jsonResponse = nil;
    if ([http_request isNotNil:data])
    {
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:error];
    }

    return jsonResponse;
}

+ (id)stringDataParser:(NSData *)data error:(NSError *__autoreleasing *)error
{
    *error = nil;
    NSString *stringResponse = nil;
    if ([http_request isNotNil:data])
    {
        stringResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }

    return stringResponse;
}

+ (NSData *)serializeString:(NSString *)str error:(NSError *__autoreleasing *)error
{
    *error = nil;
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

+ (NSData *)serializeJson:(NSDictionary *)dict error:(NSError *__autoreleasing *)error
{
    *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:error];
    return data;
}

- (NSURLSessionDataTask *)getAsync:(NSURL *)url
                         onSuccess:(void (^)(NSURLResponse *, id))success
                           onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self getAsync:url withHeaders:nil onSuccess:success onError:error];
    return task;
}

- (NSURLSessionDataTask *)getAsync:(NSURL *)url
                       withHeaders:(NSDictionary *)headers
                         onSuccess:(void (^)(NSURLResponse *, id))success
                           onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSMutableURLRequest *request = [http_request constructRequest:kGetHttpMethod withUrl:url withHeaders:headers withBody:nil];
    NSURLSessionDataTask *task = [self issueAsync:request onSuccess:success onError:error];
    return task;
}

- (NSURLSessionDataTask *)putAsync:(NSURL *)url
                          withBody:(NSData *)data
                         onSuccess:(void (^)(NSURLResponse *, id))success
                           onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self putAsync:url withHeaders:nil withBody:data onSuccess:success onError:error];
    return task;
}

- (NSURLSessionDataTask *)putAsync:(NSURL *)url
                          withJson:(NSDictionary *)dict
                         onSuccess:(void (^)(NSURLResponse *, id))success
                           onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  callBodySerializeAndExecuteAsync:kPutHttpMethod
                                  url:url
                                  withHeaders:nil
                                  withBody:dict
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)putAsync:(NSURL *)url
                        withString:(NSString *)str
                         onSuccess:(void (^)(NSURLResponse *, id))success
                           onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  callBodySerializeAndExecuteAsync:kPutHttpMethod
                                  url:url
                                  withHeaders:nil
                                  withBody:str
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)putAsync:(NSURL *)url
                       withHeaders:(NSDictionary *)headers
                          withBody:(NSData *)data
                         onSuccess:(void (^)(NSURLResponse *, id))success
                           onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSMutableURLRequest *request = [http_request constructRequest:kPutHttpMethod withUrl:url withHeaders:headers withBody:data];
    NSURLSessionDataTask *task = [self issueAsync:request onSuccess:success onError:error];
    return task;
}

- (NSURLSessionDataTask *)putAsync:(NSURL *)url
                       withHeaders:(NSDictionary *)headers
                        withString:(NSString *)str
                         onSuccess:(void (^)(NSURLResponse *, id))success
                           onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  callBodySerializeAndExecuteAsync:kPutHttpMethod
                                  url:url
                                  withHeaders:headers
                                  withBody:str
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)putAsync:(NSURL *)url
                       withHeaders:(NSDictionary *)headers
                          withJson:(NSDictionary *)dict
                         onSuccess:(void (^)(NSURLResponse *, id))success
                           onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  callBodySerializeAndExecuteAsync:kPutHttpMethod
                                  url:url
                                  withHeaders:headers
                                  withBody:dict
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)postAsync:(NSURL *)url
                           withBody:(NSData *)data
                          onSuccess:(void (^)(NSURLResponse *, id))success
                            onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self postAsync:url withHeaders:nil withBody:data onSuccess:success onError:error];
    return task;
}

- (NSURLSessionDataTask *)postAsync:(NSURL *)url
                           withJson:(NSDictionary *)dict
                          onSuccess:(void (^)(NSURLResponse *, id))success
                            onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  callBodySerializeAndExecuteAsync:kPostHttpMethod
                                  url:url
                                  withHeaders:nil
                                  withBody:dict
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)postAsync:(NSURL *)url
                         withString:(NSString *)str
                          onSuccess:(void (^)(NSURLResponse *, id))success
                            onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  callBodySerializeAndExecuteAsync:kPostHttpMethod
                                  url:url
                                  withHeaders:nil
                                  withBody:str
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)postAsync:(NSURL *)url
                        withHeaders:(NSDictionary *)headers
                           withBody:(NSData *)data
                          onSuccess:(void (^)(NSURLResponse *, id))success
                            onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSMutableURLRequest *request = [http_request constructRequest:kPostHttpMethod withUrl:url withHeaders:headers withBody:data];
    NSURLSessionDataTask *task = [self issueAsync:request onSuccess:success onError:error];
    return task;
}

- (NSURLSessionDataTask *)postAsync:(NSURL *)url
                        withHeaders:(NSDictionary *)headers
                           withJson:(NSDictionary *)dict
                          onSuccess:(void (^)(NSURLResponse *, id))success
                            onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  callBodySerializeAndExecuteAsync:kPostHttpMethod
                                  url:url
                                  withHeaders:headers
                                  withBody:dict
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)postAsync:(NSURL *)url
                        withHeaders:(NSDictionary *)headers
                         withString:(NSString *)str
                          onSuccess:(void (^)(NSURLResponse *, id))success
                            onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  callBodySerializeAndExecuteAsync:kPostHttpMethod
                                  url:url
                                  withHeaders:headers
                                  withBody:str
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)patchAsync:(NSURL *)url
                            withBody:(NSData *)data
                           onSuccess:(void (^)(NSURLResponse *, id))success
                             onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self patchAsync:url withHeaders:nil withBody:data onSuccess:success onError:error];
    return task;
}

- (NSURLSessionDataTask *)patchAsync:(NSURL *)url
                            withJson:(NSDictionary *)dict
                           onSuccess:(void (^)(NSURLResponse *, id))success
                             onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  callBodySerializeAndExecuteAsync:kPatchHttpMethod
                                  url:url
                                  withHeaders:nil
                                  withBody:dict
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)patchAsync:(NSURL *)url
                          withString:(NSString *)str
                           onSuccess:(void (^)(NSURLResponse *, id))success
                             onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  callBodySerializeAndExecuteAsync:kPatchHttpMethod
                                  url:url
                                  withHeaders:nil
                                  withBody:str
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)patchAsync:(NSURL *)url
                         withHeaders:(NSDictionary *)headers
                            withBody:(NSData *)data
                           onSuccess:(void (^)(NSURLResponse *, id))success
                             onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSMutableURLRequest *request = [http_request constructRequest:kPatchHttpMethod withUrl:url withHeaders:headers withBody:data];
    NSURLSessionDataTask *task = [self issueAsync:request onSuccess:success onError:error];
    return task;
}

- (NSURLSessionDataTask *)patchAsync:(NSURL *)url
                         withHeaders:(NSDictionary *)headers
                            withJson:(NSDictionary *)dict
                           onSuccess:(void (^)(NSURLResponse *, id))success
                             onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  callBodySerializeAndExecuteAsync:kPatchHttpMethod
                                  url:url
                                  withHeaders:headers
                                  withBody:dict
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)patchAsync:(NSURL *)url
                         withHeaders:(NSDictionary *)headers
                          withString:(NSString *)str
                           onSuccess:(void (^)(NSURLResponse *, id))success
                             onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  callBodySerializeAndExecuteAsync:kPatchHttpMethod
                                  url:url
                                  withHeaders:headers
                                  withBody:str
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)deleteAsync:(NSURL *)url
                            onSuccess:(void (^)(NSURLResponse *, id))success
                              onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    return [self deleteAsync:url withHeaders:nil onSuccess:success onError:error];
}

- (NSURLSessionDataTask *)deleteAsync:(NSURL *)url
                          withHeaders:(NSDictionary *)headers
                            onSuccess:(void (^)(NSURLResponse *, id))success
                              onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:url withName:@"url"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSMutableURLRequest *request = [http_request constructRequest:kDeleteHttpMethod withUrl:url withHeaders:headers withBody:nil];
    NSURLSessionDataTask *task = [self issueAsync:request onSuccess:success onError:error];
    return task;
}

- (NSURLSessionDataTask *)issueAsync:(NSMutableURLRequest *)request
                           onSuccess:(void (^)(NSURLResponse *, id))success
                             onError:(void (^)(NSError *))error
{
    [http_request throwIfNil:request withName:@"request"];
    [http_request throwIfNil:success withName:@"success"];
    [http_request throwIfNil:error withName:@"error"];

    NSURLSessionDataTask *task = [self
                                  issueAsync:request
                                  withBodyParser:self.bodyParser
                                  withResponseValidation:self.responseValidator
                                  onSuccess:success
                                  onError:error];
    return task;
}

- (NSURLSessionDataTask *)issueAsync:(NSMutableURLRequest *)request
                      withBodyParser:(id (^)(NSURLResponse *, NSData *, NSError *__autoreleasing *))bodyParser
              withResponseValidation:(BOOL (^)(NSURLResponse *, id, NSError *__autoreleasing *))validateResponse
                           onSuccess:(void (^)(NSURLResponse *, id))successCallback
                             onError:(void (^)(NSError *))errorCallback
{
    [http_request throwIfNil:request withName:@"request"];
    [http_request throwIfNil:successCallback withName:@"successCallback"];
    [http_request throwIfNil:errorCallback withName:@"errorCallback"];

    NSURLSessionDataTask *dataTask = [_session
                                      dataTaskWithRequest:request
                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          [self
                                           dataTaskCompletionHandler:response
                                           withBody:data
                                           withBodyParser:bodyParser
                                           withResponseValidation:validateResponse
                                           error:error
                                           onSuccess:successCallback
                                           onError:errorCallback];
                                      }];
    [dataTask resume];
    return dataTask;
}

#pragma mark - Internal API

+ (void)throwIfNil:(id)parameter withName:(NSString *)parameterName
{
    if (![http_request isNotNil:parameter])
    {
        [NSException
         raise:kHttpRequestDomain
         format:@"Invalid parameter value%@. Expected non-nil value!",
         parameterName
         ? [NSString stringWithFormat:@"%@%@%@", @" \"", parameterName, @"\""]
         : @""];
    }
}

+ (BOOL)isNotNil:(id)value
{
    return value && ![value isKindOfClass:[NSNull class]];
}

+ (void)raiseExceptionOnInvalidStatusCodeRange:(int)statusCode
{
    if (statusCode < 100 || statusCode >= 600)
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Invalid status code value: not within range"
                                     userInfo:nil];
    }
}

+ (BOOL)mostSignificantDigitEquals:(int)value1 equals:(int)value2
{
    int mostSignificantDigit = [http_request getMostSignificantDigit:(int)value1];
    BOOL equals = mostSignificantDigit == value2;
    return equals;
}

+ (int)getMostSignificantDigit:(int)value
{
    int numberOfDigits = (int)log10(value);
    return value / pow(10, numberOfDigits);
}

- (NSURLSessionDataTask *)callBodySerializeAndExecuteAsync:(NSString *)method
                                                       url:(NSURL *)url
                                               withHeaders:(NSDictionary *)headers
                                                  withBody:(id)body
                                                 onSuccess:(void (^)(NSURLResponse *, id))success
                                                   onError:(void (^)(NSError *))error
{
    NSError *serializationError = nil;
    NSData *data = self.bodySerializer(body, &serializationError);
    NSURLSessionDataTask *task = nil;
    if (!serializationError)
    {
        if ([kPutHttpMethod caseInsensitiveCompare:method] == NSOrderedSame)
        {
            task = [self putAsync:url withHeaders:headers withBody:data onSuccess:success onError:error];
        }
        else if ([kPostHttpMethod caseInsensitiveCompare:method] == NSOrderedSame)
        {
            task = [self postAsync:url withHeaders:headers withBody:data onSuccess:success onError:error];
        }
        else if ([kPatchHttpMethod caseInsensitiveCompare:method] == NSOrderedSame)
        {
            task = [self patchAsync:url withHeaders:headers withBody:data onSuccess:success onError:error];
        }
    }
    else
    {
        error(serializationError);
    }
    
    return task;
}

- (void)dataTaskCompletionHandler:(NSURLResponse *)response
                         withBody:(NSData *)data
                   withBodyParser:(id (^)(NSURLResponse *, NSData *, NSError *__autoreleasing *))bodyParser
           withResponseValidation:(BOOL (^)(NSURLResponse *, id, NSError *__autoreleasing *))validateResponse
                            error:(NSError *)error
                        onSuccess:(void (^)(NSURLResponse *, id))successCallback
                          onError:(void (^)(NSError *))errorCallback
{
    if (!error)
    {
        id parsedData = data;
        NSError *parsingError = nil;
        if (bodyParser && data)
        {
            parsedData = bodyParser(response, data, &parsingError);
        }

        if (!parsingError)
        {
            if (validateResponse)
            {
                NSError *validationError = nil;
                BOOL validResponse = validateResponse(response, parsedData, &validationError);
                if (validResponse)
                {
                    successCallback(response, parsedData);
                }
                else
                {
                    errorCallback(validationError);
                }
            }
            else
            {
                successCallback(response, parsedData);
            }
        }
        else
        {
            NSError *verboseParsingError = [[NSError alloc]
                                            initWithDomain:kHttpRequestDomain
                                            code:-3
                                            userInfo:@{NSLocalizedDescriptionKey:@"Unsuccessful body parsing.",
                                                       @"Error":parsingError,
                                                       @"Response":(NSHTTPURLResponse *)response,
                                                       @"Body":data}];
            errorCallback(verboseParsingError);
        }
    }
    else
    {
        errorCallback(error);
    }
}

- (void)configureBodyParser
{
    self.bodyParser = ^id (NSURLResponse *response, NSData *data, NSError *__autoreleasing *error)
    {
        return [http_request parseBody:response withBody:data error:error];
    };
}

- (void)configureBodySerializer
{
    self.bodySerializer = ^NSData *(id body, NSError *__autoreleasing *error)
    {
        return [http_request serializeBody:body error:error];
    };
}

- (void)configureResponseValidator
{
    self.responseValidator = ^BOOL (NSURLResponse *response, id body, NSError *__autoreleasing *error)
    {
        return [http_request isValidResponse:response withBody:body error:error];
    };
}

#pragma mark - Initialization

- (id)initWithConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
{
    self = [super init];
    if (self)
    {
        [self configureBodyParser];
        [self configureBodySerializer];
        [self configureResponseValidator];
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    }

    return self;
}

- (id)init
{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [sessionConfiguration setHTTPAdditionalHeaders:@{@"Content-Type":kApplicationJsonContentType}];
    [sessionConfiguration setHTTPAdditionalHeaders:@{@"Accept":kApplicationJsonContentType}];
    return [self initWithConfiguration:sessionConfiguration];
}

@end
