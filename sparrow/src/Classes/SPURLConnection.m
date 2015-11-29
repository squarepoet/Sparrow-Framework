//
//  SPURLConnection.m
//  Sparrow
//
//  Created by Daniel Sperl on 17.10.13.
//  Copyright (c) 2013 Gamua. All rights reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//

#import "SPMacros.h"
#import "SPURLConnection.h"

#if !TARGET_OS_TV

@implementation SPURLConnection
{
    NSURLConnection *_connection;
    NSInteger _responseStatus;
    NSMutableData *_responseData;
    SPURLConnectionCompleteBlock _onComplete;
}

#pragma mark Initialization

- (instancetype)initWithRequest:(NSURLRequest *)request
{
    if ((self = [super init]))
    {
        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self
                                              startImmediately:NO];
    }
    return self;
}

- (instancetype)init
{
    [self release];
    return nil;
}

- (void)dealloc
{
    [_connection release];
    [_responseData release];
    [_onComplete release];
    [super dealloc];
}

#pragma mark Methods

- (void)startWithBlock:(SPURLConnectionCompleteBlock)completeBlock
{
    if (_onComplete)
        [NSException raise:SPExceptionInvalidOperation format:@"connection was already started"];
    
    _onComplete = [completeBlock copy];
    [_connection start];
}

- (void)cancel
{
    [_connection cancel];
    
    SP_RELEASE_AND_NIL(_onComplete);
}

#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    _responseData = [[NSMutableData alloc] init];
    _responseStatus = httpResponse.statusCode;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _onComplete(_responseData, _responseStatus, nil);
    
    SP_RELEASE_AND_NIL(_onComplete);
    SP_RELEASE_AND_NIL(_responseData);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _onComplete(nil, _responseStatus, error);
    
    SP_RELEASE_AND_NIL(_onComplete);
    SP_RELEASE_AND_NIL(_responseData);
}

@end

#else

@implementation SPURLConnection
{
    NSURLRequest *_request;
    NSURLSessionDataTask *_sessionDataTask;
    SPURLConnectionCompleteBlock _onComplete;
}


- (instancetype)initWithRequest:(NSURLRequest *)request
{
    if (self = [super init])
    {
        _request = [request retain];
    }
    return self;
}

- (void)dealloc
{
    [_request release];
    [super dealloc];
}

- (void)startWithBlock:(SPURLConnectionCompleteBlock)completeBlock
{
    SP_RELEASE_AND_COPY(_onComplete, completeBlock);
    
    _sessionDataTask =
    [[NSURLSession sharedSession] dataTaskWithRequest:_request
                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        if ([response isKindOfClass:[NSHTTPURLResponse class]])
            _onComplete(data, [(NSHTTPURLResponse *)response statusCode], error);
        else
            _onComplete(data, 0, error);
        
        SP_RELEASE_AND_NIL(_onComplete);
    }];
    
    [_sessionDataTask retain];
}

- (void)cancel
{
    [_sessionDataTask cancel];
    
    SP_RELEASE_AND_NIL(_sessionDataTask);
    SP_RELEASE_AND_NIL(_onComplete);
}

@end

#endif
