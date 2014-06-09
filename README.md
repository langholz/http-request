# http-request
An iOS Objective-C light-weight library that simplifies asynchronous HTTP operations.

## Install
* Clone repo: <code>git clone https://github.com/langholz/http-request.git</code>
* Open workspace, select the `httprequestlib` target and build (which generates a static library).
* Follow [Apple's documentation](https://developer.apple.com/library/ios/technotes/iOSStaticLibraries/Articles/configuration.html) on how to use static libraries in iOS

## Usage
With `http-request` you are able to perform simple HTTP operations in a light-weight manner.

### Create and initialize instance
```
http_request *httpRequest = [http_request new];
```

### GET request
```
 NSURLSessionDataTask *task = [httpRequest
                               getAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### GET request with headers
```
 NSURLSessionDataTask *task = [httpRequest
                               getAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### PUT request with NSData as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               putAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withBody:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### PUT request with NSDictionary as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               putAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withJson:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### PUT request with NSString as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               putAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withString:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### PUT request with headers and NSData as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               putAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
                               withBody:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### PUT request with headers and NSDictionary as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               putAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
                               withJson:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### PUT request with headers and NSString as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               putAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
                               withString:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### POST request with NSData as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               postAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withBody:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### POST request with NSDictionary as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               postAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withJson:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### POST request with NSString as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               postAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withString:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### POST request with headers and NSData as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               postAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
                               withBody:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### POST request with headers and NSDictionary as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               postAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
                               withJson:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### POST request with headers and NSString as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               posAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
                               withString:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### PATCH request with NSData as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               patchAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withBody:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### PATCH request with NSDictionary as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               patchAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withJson:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### PATCH request with NSString as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               patchAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withString:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### PATCH request with headers and NSData as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               patchAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
                               withBody:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### PATCH request with headers and NSDictionary as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               patchAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
                               withJson:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### PATCH request with headers and NSString as the request body
```
 NSURLSessionDataTask *task = [httpRequest
                               patchAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
                               withString:body
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### DELETE request
```
 NSURLSessionDataTask *task = [httpRequest
                               deleteAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### DELETE request with headers
```
 NSURLSessionDataTask *task = [httpRequest
                               deleteAsync:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
                               withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                    // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### ISSUE verb request with automated parsing and status code validation
```
 [http_request
 constructRequest:@"GET"
 withUrl:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
 withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
 withBody:body];

 NSURLSessionDataTask *task = [httpRequest
                               issueAsync:request
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                   // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

### ISSUE verb request with optional parsing and optional status code validation
```
 [http_request
 constructRequest:@"GET"
 withUrl:[[NSURL alloc] initWithString:@"http://www.langholz.net"]
 withHeaders:@{@"MyHeaderName":@"MyHeaderValue"}
 withBody:body];

 NSURLSessionDataTask *task = [httpRequest
                               issueAsync:request
                               withBodyParser:nil
                               withResponseValidation:nil
                               onSuccess:^(NSURLResponse *response, id body)
                               {
                                   // Success
                               }
                               onError:^(NSError *error)
                               {
                                   // Error
                               }];
```

## Tests
* Relies on the [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs) CocoaPod and XCTest.
* Make sure you have the CocoaPod [dependencies](http://www.raywenderlich.com/64546/introduction-to-cocoapods-2).
* Install by changing to the directory and running <code>pod install</code>.
* Run tests in Xcode.

## Documentation
* [HTML documentation](https://langholz.github.io/http-request/docs/html/index.html)
* The project includes a `Documentation` target which generates, through [appledoc](http://gentlebytes.com/appledoc/), the `docs` directory containing the corresponding documentation.
