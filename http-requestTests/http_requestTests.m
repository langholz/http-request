//
//  http_requestTests.m
//  http-requestTests
//
//  Created by Elmar Langholz on 4/10/14.
//  Copyright (c) 2014 Elmar Langholz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "http_request.h"

#define kTestUrl @"http://www.langholz.net"

static NSURL *_testUrl      = nil;
static NSArray *_methods    = nil;

@interface http_requestTests : XCTestCase
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@end

@implementation http_requestTests

- (void)runTestWithBlock:(void (^)(void))block
{
    self.semaphore = dispatch_semaphore_create(0);
    block();
    while (dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_NOW))
    {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, YES);
    }
}

- (void)blockTestCompletedWithBlock:(void (^)(void))block
{
    dispatch_semaphore_signal(self.semaphore);
    if (block)
    {
        block();
    }
}

- (void)setUp
{
    [super setUp];
    [OHHTTPStubs removeAllStubs];
    _testUrl = [[NSURL alloc] initWithString:kTestUrl];
    _methods = @[kGetHttpMethod, kPutHttpMethod, kPatchHttpMethod, kPostHttpMethod, kDeleteHttpMethod];
}

- (void)tearDown
{
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

- (void)test_that_http_request_can_be_constructed
{
    http_request *httpRequest = [http_request new];
    XCTAssertNotNil(httpRequest, @"httpRequest should not be nil");
}

- (void)test_that_http_request_can_be_constructed_with_configuration
{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    http_request *httpRequest = [[http_request alloc] initWithConfiguration:sessionConfiguration];
    XCTAssertNotNil(httpRequest, @"httpRequest should not be nil");
}

- (void)test_that_http_request_issueAsync_with_nil_parser_and_nil_validator_call_success_block
{
    for (NSString *method in _methods)
    {
        [OHHTTPStubs removeAllStubs];
        
        NSString *expectedHeaderKey = @"Hello";
        NSString *expectedHeaderValue = @"World";
        NSString *expectedBodyKey = @"key";
        NSString *expectedBodyValue = @"value";
        NSDictionary *json = @{expectedBodyKey:expectedBodyValue};
        NSError *error = nil;
        NSData *jsonAsData = [http_request serializeJson:json error:&error];
        XCTAssertNil(error, "json serialization should not have errors");
        NSMutableURLRequest *request = [http_request
                                        constructRequest:method
                                        withUrl:_testUrl
                                        withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                        withBody:jsonAsData];
        
        [OHHTTPStubs
         stubRequestsPassingTest:^BOOL(NSURLRequest *request)
         {
             BOOL processRequest = NO;
             if (request && request.URL && request.URL.host
                 && [method caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
                 && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
             {
                 NSString *url = [[request.URL absoluteString] lowercaseString];
                 processRequest = [url hasPrefix:kTestUrl];
             }
             
             return processRequest;
         }
         withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
         {
             NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedBodyKey, expectedBodyValue];
             NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
             return [OHHTTPStubsResponse
                     responseWithData:responseData
                     statusCode:500
                     headers:@{@"Content-Type":@"application/json"}];
         }];
        
        [self
         runTestWithBlock:^
         {
             http_request *httpRequest = [http_request new];
             NSURLSessionDataTask *task = [httpRequest
                                           issueAsync:request
                                           withBodyParser:nil
                                           withResponseValidation:nil
                                           onSuccess:^(NSURLResponse *response, id body)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTAssertNotNil(response, @"response should not be nil");
                                                    XCTAssertNotNil(body, @"body should not be nil");
                                                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                    XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                    XCTAssertTrue([body isKindOfClass:[NSData class]], @"body should be NSData");
                                                    NSError *parseError = nil;
                                                    NSDictionary *bodyAsDictionary = [http_request parseBody:response withBody:body error:&parseError];
                                                    XCTAssertNil(parseError, @"parsing error should be nil");
                                                    NSString *actualBodyValue = [bodyAsDictionary objectForKey:expectedBodyKey];
                                                    XCTAssertTrue([expectedBodyValue compare:actualBodyValue] == NSOrderedSame,
                                                                  @"value mismatch: expected['%@'], actual['%@']",
                                                                  expectedBodyValue,
                                                                  actualBodyValue);
                                                }];
                                           }
                                           onError:^(NSError *error)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTFail(@"error block should not have been called");
                                                }];
                                           }];
             XCTAssertNotNil(task, @"returned task should not be nil");
         }];
    }
}

- (void)test_that_http_request_issueAsync_with_nil_parser_and_nil_validator_call_error_block
{
    for (NSString *method in _methods)
    {
        [OHHTTPStubs removeAllStubs];
        
        NSString *expectedHeaderKey = @"Hello";
        NSString *expectedHeaderValue = @"World";
        NSString *expectedBodyKey = @"key";
        NSString *expectedBodyValue = @"value";
        NSDictionary *json = @{expectedBodyKey:expectedBodyValue};
        NSError *error = nil;
        NSData *jsonAsData = [http_request serializeJson:json error:&error];
        XCTAssertNil(error, "json serialization should not have errors");
        NSMutableURLRequest *request = [http_request
                                        constructRequest:method
                                        withUrl:_testUrl
                                        withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                        withBody:jsonAsData];
        
        [OHHTTPStubs
         stubRequestsPassingTest:^BOOL(NSURLRequest *request)
         {
             BOOL processRequest = NO;
             if (request && request.URL && request.URL.host
                 && [method caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
                 && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
             {
                 NSString *url = [[request.URL absoluteString] lowercaseString];
                 processRequest = [url hasPrefix:kTestUrl];
             }
             
             return processRequest;
         }
         withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
         {
             NSError *error = [[NSError alloc]
                               initWithDomain:NSPOSIXErrorDomain
                               code:-1011
                               userInfo:@{NSLocalizedDescriptionKey:@"Unable to establish connection"}];
             return [OHHTTPStubsResponse responseWithError:error];
         }];
        
        [self
         runTestWithBlock:^
         {
             http_request *httpRequest = [http_request new];
             NSURLSessionDataTask *task = [httpRequest
                                           issueAsync:request
                                           withBodyParser:nil
                                           withResponseValidation:nil
                                           onSuccess:^(NSURLResponse *response, id body)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTFail(@"success block should not have been called");
                                                }];
                                           }
                                           onError:^(NSError *error)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTAssertNotNil(error, @"error should not be nil");
                                                    XCTAssertEqual(-1011, error.code, @"invalid error code, expected -1011");
                                                    XCTAssertEqual([@"Unable to establish connection" compare:[error localizedDescription]], NSOrderedSame, @"invalid error description");
                                                }];
                                           }];
             XCTAssertNotNil(task, @"returned task should not be nil");
         }];
    }
}

- (void)test_that_http_request_issueAsync_with_parser_and_nil_validator_call_success_block
{
    for (NSString *method in _methods)
    {
        [OHHTTPStubs removeAllStubs];
        
        NSString *expectedHeaderKey = @"Hello";
        NSString *expectedHeaderValue = @"World";
        NSString *expectedBodyKey = @"key";
        NSString *expectedBodyValue = @"value";
        NSDictionary *json = @{expectedBodyKey:expectedBodyValue};
        NSError *error = nil;
        NSData *jsonAsData = [http_request serializeJson:json error:&error];
        XCTAssertNil(error, "json serialization should not have errors");
        NSMutableURLRequest *request = [http_request
                                        constructRequest:method
                                        withUrl:_testUrl
                                        withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                        withBody:jsonAsData];
        
        [OHHTTPStubs
         stubRequestsPassingTest:^BOOL(NSURLRequest *request)
         {
             BOOL processRequest = NO;
             if (request && request.URL && request.URL.host
                 && [method caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
                 && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
             {
                 NSString *url = [[request.URL absoluteString] lowercaseString];
                 processRequest = [url hasPrefix:kTestUrl];
             }
             
             return processRequest;
         }
         withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
         {
             NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedBodyKey, expectedBodyValue];
             NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
             return [OHHTTPStubsResponse
                     responseWithData:responseData
                     statusCode:500
                     headers:@{@"Content-Type":@"application/json"}];
         }];
        
        [self
         runTestWithBlock:^
         {
             http_request *httpRequest = [http_request new];
             NSURLSessionDataTask *task = [httpRequest
                                           issueAsync:request
                                           withBodyParser:httpRequest.bodyParser
                                           withResponseValidation:nil
                                           onSuccess:^(NSURLResponse *response, id body)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTAssertNotNil(response, @"response should not be nil");
                                                    XCTAssertNotNil(body, @"body should not be nil");
                                                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                    XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                    XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                    NSString *actualBodyValue = [body objectForKey:expectedBodyKey];
                                                    XCTAssertTrue([expectedBodyValue compare:actualBodyValue] == NSOrderedSame,
                                                                  @"value mismatch: expected['%@'], actual['%@']",
                                                                  expectedBodyValue,
                                                                  actualBodyValue);
                                                }];
                                           }
                                           onError:^(NSError *error)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTFail(@"error block should not have been called");
                                                }];
                                           }];
             XCTAssertNotNil(task, @"returned task should not be nil");
         }];
    }
}

- (void)test_that_http_request_issueAsync_with_parser_and_nil_validator_call_error_block
{
    for (NSString *method in _methods)
    {
        [OHHTTPStubs removeAllStubs];
        
        NSString *expectedHeaderKey = @"Hello";
        NSString *expectedHeaderValue = @"World";
        NSString *expectedBodyKey = @"key";
        NSString *expectedBodyValue = @"value";
        NSDictionary *json = @{expectedBodyKey:expectedBodyValue};
        NSError *error = nil;
        NSData *jsonAsData = [http_request serializeJson:json error:&error];
        XCTAssertNil(error, "json serialization should not have errors");
        NSMutableURLRequest *request = [http_request
                                        constructRequest:method
                                        withUrl:_testUrl
                                        withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                        withBody:jsonAsData];
        
        [OHHTTPStubs
         stubRequestsPassingTest:^BOOL(NSURLRequest *request)
         {
             BOOL processRequest = NO;
             if (request && request.URL && request.URL.host
                 && [method caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
                 && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
             {
                 NSString *url = [[request.URL absoluteString] lowercaseString];
                 processRequest = [url hasPrefix:kTestUrl];
             }
             
             return processRequest;
         }
         withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
         {
             NSString *responseString = @"\\\\{";
             NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
             return [OHHTTPStubsResponse
                     responseWithData:responseData
                     statusCode:200
                     headers:@{@"Content-Type":@"application/json"}];
         }];
        
        [self
         runTestWithBlock:^
         {
             http_request *httpRequest = [http_request new];
             NSURLSessionDataTask *task = [httpRequest
                                           issueAsync:request
                                           withBodyParser:httpRequest.bodyParser
                                           withResponseValidation:nil
                                           onSuccess:^(NSURLResponse *response, id body)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTFail(@"success block should not have been called");
                                                }];
                                           }
                                           onError:^(NSError *error)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTAssertNotNil(error, @"error should not be nil");
                                                    NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                    id body = error.userInfo[@"Body"];
                                                    XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                    XCTAssertNotNil(body, @"the body should not be nil");
                                                    XCTAssertTrue([body isKindOfClass:[NSData class]], @"body should be NSData");
                                                }];
                                           }];
             XCTAssertNotNil(task, @"returned task should not be nil");
         }];
    }
}

- (void)test_that_http_request_issueAsync_with_nil_parser_and_validator_call_success_block
{
    for (NSString *method in _methods)
    {
        [OHHTTPStubs removeAllStubs];
        
        NSString *expectedHeaderKey = @"Hello";
        NSString *expectedHeaderValue = @"World";
        NSString *expectedBodyKey = @"key";
        NSString *expectedBodyValue = @"value";
        NSDictionary *json = @{expectedBodyKey:expectedBodyValue};
        NSError *error = nil;
        NSData *jsonAsData = [http_request serializeJson:json error:&error];
        XCTAssertNil(error, "json serialization should not have errors");
        NSMutableURLRequest *request = [http_request
                                        constructRequest:method
                                        withUrl:_testUrl
                                        withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                        withBody:jsonAsData];
        
        [OHHTTPStubs
         stubRequestsPassingTest:^BOOL(NSURLRequest *request)
         {
             BOOL processRequest = NO;
             if (request && request.URL && request.URL.host
                 && [method caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
                 && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
             {
                 NSString *url = [[request.URL absoluteString] lowercaseString];
                 processRequest = [url hasPrefix:kTestUrl];
             }
             
             return processRequest;
         }
         withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
         {
             NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedBodyKey, expectedBodyValue];
             NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
             return [OHHTTPStubsResponse
                     responseWithData:responseData
                     statusCode:200
                     headers:@{@"Content-Type":@"application/json"}];
         }];
        
        [self
         runTestWithBlock:^
         {
             http_request *httpRequest = [http_request new];
             NSURLSessionDataTask *task = [httpRequest
                                           issueAsync:request
                                           withBodyParser:nil
                                           withResponseValidation:httpRequest.responseValidator
                                           onSuccess:^(NSURLResponse *response, id body)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTAssertNotNil(response, @"response should not be nil");
                                                    XCTAssertNotNil(body, @"body should not be nil");
                                                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                    XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 500");
                                                    XCTAssertTrue([body isKindOfClass:[NSData class]], @"body should be NSData");
                                                    NSError *parseError = nil;
                                                    NSDictionary *bodyAsDictionary = [http_request parseBody:response withBody:body error:&parseError];
                                                    XCTAssertNil(parseError, @"parsing error should be nil");
                                                    NSString *actualBodyValue = [bodyAsDictionary objectForKey:expectedBodyKey];
                                                    XCTAssertTrue([expectedBodyValue compare:actualBodyValue] == NSOrderedSame,
                                                                  @"value mismatch: expected['%@'], actual['%@']",
                                                                  expectedBodyValue,
                                                                  actualBodyValue);
                                                }];
                                           }
                                           onError:^(NSError *error)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTFail(@"error block should not have been called");
                                                }];
                                           }];
             XCTAssertNotNil(task, @"returned task should not be nil");
         }];
    }
}

- (void)test_that_http_request_issueAsync_with_nil_parser_and_validator_call_error_block
{
    for (NSString *method in _methods)
    {
        [OHHTTPStubs removeAllStubs];
        
        NSString *expectedHeaderKey = @"Hello";
        NSString *expectedHeaderValue = @"World";
        NSString *expectedBodyKey = @"key";
        NSString *expectedBodyValue = @"value";
        NSDictionary *json = @{expectedBodyKey:expectedBodyValue};
        NSError *error = nil;
        NSData *jsonAsData = [http_request serializeJson:json error:&error];
        XCTAssertNil(error, "json serialization should not have errors");
        NSMutableURLRequest *request = [http_request
                                        constructRequest:method
                                        withUrl:_testUrl
                                        withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                        withBody:jsonAsData];
        
        [OHHTTPStubs
         stubRequestsPassingTest:^BOOL(NSURLRequest *request)
         {
             BOOL processRequest = NO;
             if (request && request.URL && request.URL.host
                 && [method caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
                 && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
             {
                 NSString *url = [[request.URL absoluteString] lowercaseString];
                 processRequest = [url hasPrefix:kTestUrl];
             }
             
             return processRequest;
         }
         withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
         {
             NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedBodyKey, expectedBodyValue];
             NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
             return [OHHTTPStubsResponse
                     responseWithData:responseData
                     statusCode:500
                     headers:@{@"Content-Type":@"application/json"}];
         }];
        
        [self
         runTestWithBlock:^
         {
             http_request *httpRequest = [http_request new];
             NSURLSessionDataTask *task = [httpRequest
                                           issueAsync:request
                                           withBodyParser:nil
                                           withResponseValidation:httpRequest.responseValidator
                                           onSuccess:^(NSURLResponse *response, id body)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTFail(@"success block should not have been called");
                                                }];
                                           }
                                           onError:^(NSError *error)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTAssertNotNil(error, @"error should not be nil");
                                                    NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                    id body = error.userInfo[@"Body"];
                                                    XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                    XCTAssertNotNil(body, @"the body should not be nil");
                                                    XCTAssertTrue([body isKindOfClass:[NSData class]], @"body should be NSData");
                                                }];
                                           }];
             XCTAssertNotNil(task, @"returned task should not be nil");
         }];
    }
}

- (void)test_that_http_request_issueAsync_call_success_block
{
    for (NSString *method in _methods)
    {
        [OHHTTPStubs removeAllStubs];
        
        NSString *expectedHeaderKey = @"Hello";
        NSString *expectedHeaderValue = @"World";
        NSString *expectedBodyKey = @"key";
        NSString *expectedBodyValue = @"value";
        NSDictionary *json = @{expectedBodyKey:expectedBodyValue};
        NSError *error = nil;
        NSData *jsonAsData = [http_request serializeJson:json error:&error];
        XCTAssertNil(error, "json serialization should not have errors");
        NSMutableURLRequest *request = [http_request
                                        constructRequest:method
                                        withUrl:_testUrl
                                        withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                        withBody:jsonAsData];
        
        [OHHTTPStubs
         stubRequestsPassingTest:^BOOL(NSURLRequest *request)
         {
             BOOL processRequest = NO;
             if (request && request.URL && request.URL.host
                 && [method caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
                 && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
             {
                 NSString *url = [[request.URL absoluteString] lowercaseString];
                 processRequest = [url hasPrefix:kTestUrl];
             }
             
             return processRequest;
         }
         withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
         {
             NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedBodyKey, expectedBodyValue];
             NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
             return [OHHTTPStubsResponse
                     responseWithData:responseData
                     statusCode:200
                     headers:@{@"Content-Type":@"application/json"}];
         }];
        
        [self
         runTestWithBlock:^
         {
             http_request *httpRequest = [http_request new];
             NSURLSessionDataTask *task = [httpRequest
                                           issueAsync:request
                                           onSuccess:^(NSURLResponse *response, id body)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTAssertNotNil(response, @"response should not be nil");
                                                    XCTAssertNotNil(body, @"body should not be nil");
                                                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                    XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 500");
                                                    XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                    NSString *actualBodyValue = [body objectForKey:expectedBodyKey];
                                                    XCTAssertTrue([expectedBodyValue compare:actualBodyValue] == NSOrderedSame,
                                                                  @"value mismatch: expected['%@'], actual['%@']",
                                                                  expectedBodyValue,
                                                                  actualBodyValue);
                                                }];
                                           }
                                           onError:^(NSError *error)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTFail(@"error block should not have been called");
                                                }];
                                           }];
             XCTAssertNotNil(task, @"returned task should not be nil");
         }];
    }
}

- (void)test_that_http_request_issueAsync_call_error_block_by_parsing_error
{
    for (NSString *method in _methods)
    {
        [OHHTTPStubs removeAllStubs];
        
        NSString *expectedHeaderKey = @"Hello";
        NSString *expectedHeaderValue = @"World";
        NSString *expectedBodyKey = @"key";
        NSString *expectedBodyValue = @"value";
        NSDictionary *json = @{expectedBodyKey:expectedBodyValue};
        NSError *error = nil;
        NSData *jsonAsData = [http_request serializeJson:json error:&error];
        XCTAssertNil(error, "json serialization should not have errors");
        NSMutableURLRequest *request = [http_request
                                        constructRequest:method
                                        withUrl:_testUrl
                                        withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                        withBody:jsonAsData];
        
        [OHHTTPStubs
         stubRequestsPassingTest:^BOOL(NSURLRequest *request)
         {
             BOOL processRequest = NO;
             if (request && request.URL && request.URL.host
                 && [method caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
                 && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
             {
                 NSString *url = [[request.URL absoluteString] lowercaseString];
                 processRequest = [url hasPrefix:kTestUrl];
             }
             
             return processRequest;
         }
         withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
         {
             NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"\\\\{}", expectedBodyKey, expectedBodyValue];
             NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
             return [OHHTTPStubsResponse
                     responseWithData:responseData
                     statusCode:200
                     headers:@{@"Content-Type":@"application/json"}];
         }];
        
        [self
         runTestWithBlock:^
         {
             http_request *httpRequest = [http_request new];
             NSURLSessionDataTask *task = [httpRequest
                                           issueAsync:request
                                           onSuccess:^(NSURLResponse *response, id body)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTFail(@"error success should not have been called");
                                                }];
                                           }
                                           onError:^(NSError *error)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTAssertNotNil(error, @"error should not be nil");
                                                    NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                    id body = error.userInfo[@"Body"];
                                                    XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                    XCTAssertNotNil(body, @"the body should not be nil");
                                                    XCTAssertTrue([body isKindOfClass:[NSData class]], @"body should be NSData");
                                                }];
                                           }];
             XCTAssertNotNil(task, @"returned task should not be nil");
         }];
    }
}

- (void)test_that_http_request_issueAsync_call_error_block_by_status_code_error
{
    for (NSString *method in _methods)
    {
        [OHHTTPStubs removeAllStubs];
        
        NSString *expectedHeaderKey = @"Hello";
        NSString *expectedHeaderValue = @"World";
        NSString *expectedBodyKey = @"key";
        NSString *expectedBodyValue = @"value";
        NSDictionary *json = @{expectedBodyKey:expectedBodyValue};
        NSError *error = nil;
        NSData *jsonAsData = [http_request serializeJson:json error:&error];
        XCTAssertNil(error, "json serialization should not have errors");
        NSMutableURLRequest *request = [http_request
                                        constructRequest:method
                                        withUrl:_testUrl
                                        withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                        withBody:jsonAsData];
        
        [OHHTTPStubs
         stubRequestsPassingTest:^BOOL(NSURLRequest *request)
         {
             BOOL processRequest = NO;
             if (request && request.URL && request.URL.host
                 && [method caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
                 && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
             {
                 NSString *url = [[request.URL absoluteString] lowercaseString];
                 processRequest = [url hasPrefix:kTestUrl];
             }
             
             return processRequest;
         }
         withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
         {
             NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedBodyKey, expectedBodyValue];
             NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
             return [OHHTTPStubsResponse
                     responseWithData:responseData
                     statusCode:500
                     headers:@{@"Content-Type":@"application/json"}];
         }];
        
        [self
         runTestWithBlock:^
         {
             http_request *httpRequest = [http_request new];
             NSURLSessionDataTask *task = [httpRequest
                                           issueAsync:request
                                           onSuccess:^(NSURLResponse *response, id body)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTFail(@"error success should not have been called");
                                                }];
                                           }
                                           onError:^(NSError *error)
                                           {
                                               [self blockTestCompletedWithBlock:^
                                                {
                                                    XCTAssertNotNil(error, @"error should not be nil");
                                                    NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                    id body = error.userInfo[@"Body"];
                                                    XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                    XCTAssertNotNil(body, @"the body should not be nil");
                                                    XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                    NSString *actualBodyValue = [body objectForKey:expectedBodyKey];
                                                    XCTAssertTrue([expectedBodyValue compare:actualBodyValue] == NSOrderedSame,
                                                                  @"value mismatch: expected['%@'], actual['%@']",
                                                                  expectedBodyValue,
                                                                  actualBodyValue);
                                                }];
                                           }];
             XCTAssertNotNil(task, @"returned task should not be nil");
         }];
    }
}

- (void)test_that_http_request_getAsync_call_success_block
{
    NSString *expectedKey = @"key";
    NSString *expectedValue = @"value";
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host && [kGetHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedKey, expectedValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       getAsync:_testUrl
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedKey];
                                                XCTAssertTrue([expectedValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_getAsync_with_parameters_call_success_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedKey = @"key";
    NSString *expectedValue = @"value";
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kGetHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedKey, expectedValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       getAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedKey];
                                                XCTAssertTrue([expectedValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_getAsync_call_error_block
{
    NSString *expectedKey = @"Error";
    NSString *expectedValue = @"This is an error!";
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host && [kGetHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedKey, expectedValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       getAsync:_testUrl
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                           
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedKey];
                                                XCTAssertTrue([expectedValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_putAsync_with_NSData_body_call_success_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    NSError *serializeError = nil;
    NSData *jsonAsData = [http_request serializeJson:requestBodyAsJson error:&serializeError];
    XCTAssertNil(serializeError, "json serialization should not have errors");
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host && [kPutHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       putAsync:_testUrl
                                       withBody:jsonAsData
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_putAsync_with_NSData_body_call_error_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    NSError *serializeError = nil;
    NSData *jsonAsData = [http_request serializeJson:requestBodyAsJson error:&serializeError];
    XCTAssertNil(serializeError, "json serialization should not have errors");
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host && [kPutHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       putAsync:_testUrl
                                       withBody:jsonAsData
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_putAsync_with_NSString_body_call_success_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBody = @"This is some test!";
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPutHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       putAsync:_testUrl
                                       withString:expectedRequestBody
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_putAsync_with_NSString_body_call_error_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBody = @"This is some test!";
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPutHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       putAsync:_testUrl
                                       withString:expectedRequestBody
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_putAsync_with_NSDictionary_body_call_success_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPutHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       putAsync:_testUrl
                                       withJson:requestBodyAsJson
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_putAsync_with_NSDictionary_body_call_error_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPutHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       putAsync:_testUrl
                                       withJson:requestBodyAsJson
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_putAsync_with_NSData_body_and_headers_call_success_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    NSError *serializeError = nil;
    NSData *jsonAsData = [http_request serializeJson:requestBodyAsJson error:&serializeError];
    XCTAssertNil(serializeError, "json serialization should not have errors");
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPutHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       putAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withBody:jsonAsData
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_putAsync_with_NSData_body_and_headers_call_error_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    NSError *serializeError = nil;
    NSData *jsonAsData = [http_request serializeJson:requestBodyAsJson error:&serializeError];
    XCTAssertNil(serializeError, "json serialization should not have errors");
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPutHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       putAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withBody:jsonAsData
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_putAsync_with_NSString_body_and_headers_call_success_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBody = @"This is some test!";
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPutHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       putAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withString:expectedRequestBody
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_putAsync_with_NSString_body_and_headers_call_error_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBody = @"This is some test!";
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPutHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       putAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withString:expectedRequestBody
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_putAsync_with_NSDictionary_body_and_headers_call_success_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPutHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       putAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withJson:requestBodyAsJson
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_putAsync_with_NSDictionary_body_and_headers_call_error_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPutHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       putAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withJson:requestBodyAsJson
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_postAsync_with_NSData_body_call_success_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    NSError *serializeError = nil;
    NSData *jsonAsData = [http_request serializeJson:requestBodyAsJson error:&serializeError];
    XCTAssertNil(serializeError, "json serialization should not have errors");
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host && [kPostHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       postAsync:_testUrl
                                       withBody:jsonAsData
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_postAsync_with_NSData_body_call_error_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    NSError *serializeError = nil;
    NSData *jsonAsData = [http_request serializeJson:requestBodyAsJson error:&serializeError];
    XCTAssertNil(serializeError, "json serialization should not have errors");
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host && [kPostHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       postAsync:_testUrl
                                       withBody:jsonAsData
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_postAsync_with_NSString_body_call_success_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBody = @"This is some test!";
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPostHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       postAsync:_testUrl
                                       withString:expectedRequestBody
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_postAsync_with_NSString_body_call_error_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBody = @"This is some test!";
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPostHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       postAsync:_testUrl
                                       withString:expectedRequestBody
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_postAsync_with_NSDictionary_body_call_success_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPostHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       postAsync:_testUrl
                                       withJson:requestBodyAsJson
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_postAsync_with_NSDictionary_body_call_error_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPostHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       postAsync:_testUrl
                                       withJson:requestBodyAsJson
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_postAsync_with_NSData_body_and_headers_call_success_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    NSError *serializeError = nil;
    NSData *jsonAsData = [http_request serializeJson:requestBodyAsJson error:&serializeError];
    XCTAssertNil(serializeError, "json serialization should not have errors");
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPostHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       postAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withBody:jsonAsData
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_postAsync_with_NSData_body_and_headers_call_error_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    NSError *serializeError = nil;
    NSData *jsonAsData = [http_request serializeJson:requestBodyAsJson error:&serializeError];
    XCTAssertNil(serializeError, "json serialization should not have errors");
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPostHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       postAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withBody:jsonAsData
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_postAsync_with_NSString_body_and_headers_call_success_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBody = @"This is some test!";
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPostHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       postAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withString:expectedRequestBody
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_postAsync_with_NSString_body_and_headers_call_error_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBody = @"This is some test!";
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPostHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       postAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withString:expectedRequestBody
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_postAsync_with_NSDictionary_body_and_headers_call_success_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPostHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       postAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withJson:requestBodyAsJson
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_postAsync_with_NSDictionary_body_and_headers_call_error_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPostHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       postAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withJson:requestBodyAsJson
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_patchAsync_with_NSData_body_call_success_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    NSError *serializeError = nil;
    NSData *jsonAsData = [http_request serializeJson:requestBodyAsJson error:&serializeError];
    XCTAssertNil(serializeError, "json serialization should not have errors");
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host && [kPatchHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       patchAsync:_testUrl
                                       withBody:jsonAsData
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_patchAsync_with_NSData_body_call_error_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    NSError *serializeError = nil;
    NSData *jsonAsData = [http_request serializeJson:requestBodyAsJson error:&serializeError];
    XCTAssertNil(serializeError, "json serialization should not have errors");
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host && [kPatchHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       patchAsync:_testUrl
                                       withBody:jsonAsData
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_patchAsync_with_NSString_body_call_success_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBody = @"This is some test!";
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPatchHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       patchAsync:_testUrl
                                       withString:expectedRequestBody
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_patchAsync_with_NSString_body_call_error_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBody = @"This is some test!";
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPatchHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       patchAsync:_testUrl
                                       withString:expectedRequestBody
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_patchAsync_with_NSDictionary_body_call_success_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPatchHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       patchAsync:_testUrl
                                       withJson:requestBodyAsJson
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_patchAsync_with_NSDictionary_body_call_error_block
{
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPatchHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       patchAsync:_testUrl
                                       withJson:requestBodyAsJson
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_patchAsync_with_NSData_body_and_headers_call_success_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    NSError *serializeError = nil;
    NSData *jsonAsData = [http_request serializeJson:requestBodyAsJson error:&serializeError];
    XCTAssertNil(serializeError, "json serialization should not have errors");
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPatchHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       patchAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withBody:jsonAsData
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_patchAsync_with_NSData_body_and_headers_call_error_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    NSError *serializeError = nil;
    NSData *jsonAsData = [http_request serializeJson:requestBodyAsJson error:&serializeError];
    XCTAssertNil(serializeError, "json serialization should not have errors");
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPatchHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       patchAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withBody:jsonAsData
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_patchAsync_with_NSString_body_and_headers_call_success_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBody = @"This is some test!";
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPatchHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       patchAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withString:expectedRequestBody
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_patchAsync_with_NSString_body_and_headers_call_error_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBody = @"This is some test!";
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPatchHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       patchAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withString:expectedRequestBody
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_patchAsync_with_NSDictionary_body_and_headers_call_success_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPatchHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       patchAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withJson:requestBodyAsJson
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_patchAsync_with_NSDictionary_body_and_headers_call_error_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedResponseBodyKey = @"key";
    NSString *expectedResponseBodyValue = @"value";
    NSString *expectedRequestBodyKey = @"query";
    NSString *expectedRequestBodyValue = @"a=1&b=2";
    NSDictionary *requestBodyAsJson = @{expectedRequestBodyKey:expectedRequestBodyValue};
    
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kPatchHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedResponseBodyKey, expectedResponseBodyValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       patchAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       withJson:requestBodyAsJson
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedResponseBodyKey];
                                                XCTAssertTrue([expectedResponseBodyValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedResponseBodyValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_deleteAsync_call_success_block
{
    NSString *expectedKey = @"key";
    NSString *expectedValue = @"value";
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host && [kDeleteHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedKey, expectedValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       deleteAsync:_testUrl
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedKey];
                                                XCTAssertTrue([expectedValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_deleteAsync_with_parameters_call_success_block
{
    NSString *expectedHeaderKey = @"Hello";
    NSString *expectedHeaderValue = @"World";
    NSString *expectedKey = @"key";
    NSString *expectedValue = @"value";
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host
             && [kDeleteHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame
             && [expectedHeaderValue compare:[[request allHTTPHeaderFields] valueForKey:expectedHeaderKey]] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedKey, expectedValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:200
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       deleteAsync:_testUrl
                                       withHeaders:@{expectedHeaderKey:expectedHeaderValue}
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(response, @"response should not be nil");
                                                XCTAssertNotNil(body, @"body should not be nil");
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                XCTAssertEqual(200, httpResponse.statusCode, @"status code did not equal 200");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedKey];
                                                XCTAssertTrue([expectedValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedValue,
                                                              actualValue);
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"error block should not have been called");
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

- (void)test_that_http_request_deleteAsync_call_error_block
{
    NSString *expectedKey = @"Error";
    NSString *expectedValue = @"This is an error!";
    [OHHTTPStubs
     stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
         BOOL processRequest = NO;
         if (request && request.URL && request.URL.host && [kDeleteHttpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame)
         {
             NSString *url = [[request.URL absoluteString] lowercaseString];
             processRequest = [url hasPrefix:kTestUrl];
         }
         
         return processRequest;
     }
     withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request)
     {
         NSString *responseString = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", expectedKey, expectedValue];
         NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
         return [OHHTTPStubsResponse
                 responseWithData:responseData
                 statusCode:500
                 headers:@{@"Content-Type":@"application/json"}];
     }];
    
    [self
     runTestWithBlock:^
     {
         http_request *httpRequest = [http_request new];
         NSURLSessionDataTask *task = [httpRequest
                                       deleteAsync:_testUrl
                                       onSuccess:^(NSURLResponse *response, id body)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTFail(@"success block should not have been called");
                                            }];
                                       }
                                       onError:^(NSError *error)
                                       {
                                           [self blockTestCompletedWithBlock:^
                                            {
                                                XCTAssertNotNil(error, @"error should not be nil");
                                                NSHTTPURLResponse *httpResponse = error.userInfo[@"Response"];
                                                id body = error.userInfo[@"Body"];
                                                XCTAssertEqual(500, httpResponse.statusCode, @"status code did not equal 500");
                                                XCTAssertTrue([body isKindOfClass:[NSDictionary class]], @"body should be NSDictionary");
                                                NSString *actualValue = [body objectForKey:expectedKey];
                                                XCTAssertTrue([expectedValue compare:actualValue] == NSOrderedSame,
                                                              @"value mismatch: expected['%@'], actual['%@']",
                                                              expectedValue,
                                                              actualValue);
                                            }];
                                       }];
         XCTAssertNotNil(task, @"returned task should not be nil");
     }];
}

@end
