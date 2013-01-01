#import "Kiwi.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

SPEC_BEGIN(MKNetworkEngineSpec)

static NSString *const kMKTestHostName = @"example.com";
static NSString *const kMKTestApiPath = @"api/v1";
static NSString *const kMKTestPath = @"foo";

static NSString *const kMKPathSuccessful = @"kMKPathSuccessful";
static NSString *const kMKPathError400 = @"kMKPathError400";

describe(@"Network Engine", ^{
    context(@"with hostname", ^{
        __block MKNetworkEngine *engine = nil;
        beforeEach(^{
            engine = [[MKNetworkEngine alloc] initWithHostName:kMKTestHostName];
        });

        it(@"should return operation with appropriate hostname", ^{
            MKNetworkOperation *op = [engine operationWithPath:kMKTestPath];
            [[op.readonlyRequest.URL.host should] equal:kMKTestHostName];
        });

        it(@"should return operation with appropriate port", ^{
            engine.portNumber = 8080;
            MKNetworkOperation *op = [engine operationWithPath:kMKTestPath];
            [[[op.readonlyRequest.URL port] should] equal:@8080];
        });
        it(@"should return operation with GET method by default", ^{
            MKNetworkOperation *op = [engine operationWithPath:kMKTestPath];
            [[[op.readonlyRequest HTTPMethod] should] equal:@"GET"];
        });

        it(@"should return operation with POST", ^{
            MKNetworkOperation *op = [engine operationWithPath:kMKTestPath params:nil httpMethod:@"POST"];
            [[[op.readonlyRequest HTTPMethod] should] equal:@"POST"];
        });

        it(@"should return operation with https scheme", ^{
            MKNetworkOperation *op = [engine operationWithPath:kMKTestPath params:nil httpMethod:@"GET" ssl:YES];
            [[[op.readonlyRequest.URL scheme] should] equal:@"https"];
        });

        it(@"should return operation with appropriate query", ^{
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
            MKNetworkOperation *op = [engine operationWithPath:kMKTestPath params:params];
            [[[op.readonlyRequest.URL query] should] equal:@"foo=bar"];
        });
    });

    it(@"should return operation with appropriate custom header", ^{
        MKNetworkEngine *engine = [[MKNetworkEngine alloc] initWithHostName:kMKTestHostName
                                                         customHeaderFields:@{ @"Some-Header" : @"Bar" }];
        MKNetworkOperation *op = [engine operationWithPath:kMKTestPath];
        [[op.readonlyRequest.allHTTPHeaderFields[@"Some-Header"] should] equal:@"Bar"];
    });

    it(@"should have apiPath", ^{
        MKNetworkEngine *engine = [[MKNetworkEngine alloc] initWithHostName:kMKTestHostName
                                                                    apiPath:kMKTestApiPath
                                                         customHeaderFields:nil];
        [[engine.apiPath should] equal:kMKTestApiPath];
    });

    it(@"should return operation with appropriate apiPath", ^{
        MKNetworkEngine *engine = [[MKNetworkEngine alloc] initWithHostName:kMKTestHostName
                                                                    apiPath:kMKTestApiPath
                                                         customHeaderFields:nil];
        MKNetworkOperation *op = [engine operationWithPath:kMKTestPath];
        [[[op.readonlyRequest.URL path] should] equal:[NSString stringWithFormat:@"/%@/%@", kMKTestApiPath, kMKTestPath]];
    });

    context(@"operation is finished", ^{
        __block MKNetworkEngine *engine = nil;
        __block MKNetworkOperation *operation = nil;

        beforeEach(^{
            [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse *(NSURLRequest *request, BOOL onlyCheck) {
                if (onlyCheck) {
                    return OHHTTPStubsResponseUseStub;
                }
                NSString *path = [request.URL.path substringFromIndex:1]; // to remove first slash
                if ([path isEqualToString:kMKPathSuccessful]) {
                    NSData *data = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
                    return [OHHTTPStubsResponse responseWithData:data statusCode:200 responseTime:0.5 headers:nil];
                } else { // means kMKPathError400
                    return [OHHTTPStubsResponse responseWithData:nil statusCode:400 responseTime:0.5 headers:nil];
                }
            }];

            engine = [[MKNetworkEngine alloc] initWithHostName:kMKTestHostName];
        });

        context(@"with success", ^{
            __block BOOL completionBlockCalled = NO;
            __block BOOL errorBlockCalled = NO;
            beforeEach(^{
                completionBlockCalled = NO;
                errorBlockCalled = NO;
                operation = [engine operationWithPath:kMKPathSuccessful];
                [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
                    completionBlockCalled = YES;
                } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
                    errorBlockCalled = YES;
                }];
                [engine enqueueOperation:operation];
            });
            it(@"calls completion block on successfull operation", ^{
                [[expectFutureValue(theValue(completionBlockCalled)) shouldEventually] beTrue];
            });
            it(@"doesn't call errorBlock if operation was successfull", ^{
                [[expectFutureValue(theValue(errorBlockCalled)) shouldEventually] beFalse];
            });
        });
        context(@"with failure", ^{
            __block BOOL completionBlockCalled = NO;
            __block BOOL errorBlockCalled = NO;
            beforeEach(^{
                completionBlockCalled = NO;
                errorBlockCalled = NO;
                operation = [engine operationWithPath:kMKPathError400];
                [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
                    completionBlockCalled = YES;
                } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
                    errorBlockCalled = YES;
                }];
                [engine enqueueOperation:operation];
            });
            it(@"calls error block on successfull operation", ^{
                [[expectFutureValue(theValue(errorBlockCalled)) shouldEventually] beTrue];
            });
            it(@"doesn't call errorBlock if operation was successfull", ^{
                [[expectFutureValue(theValue(completionBlockCalled)) shouldEventually] beFalse];
            });
        });
    });
});

SPEC_END
