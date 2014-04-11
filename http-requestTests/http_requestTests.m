//
//  http_requestTests.m
//  http-requestTests
//
//  Created by Elmar Langholz on 4/10/14.
//  Copyright (c) 2014 Elmar Langholz. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../http-request/http_request.h"

@interface http_requestTests : XCTestCase

@end

@implementation http_requestTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test_that_http_request_can_be_constructed
{
    http_request *httpRequest = [http_request shared];
    XCTAssertNotNil(httpRequest, @"httpRequest should not be nil");
}

@end
