#import "Kiwi.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface MKNetworkOperation () <NSURLConnectionDataDelegate>
@end

SPEC_BEGIN(MKNetworkOperationSpec)

describe(@"Operation", ^{
    context(@"initialized", ^{
        __block MKNetworkOperation *op = nil;
        beforeEach(^{
            op = [[MKNetworkOperation alloc] initWithURLString:@"http://example.com/api" params:nil httpMethod:@"GET"];
        });
        it(@"should has custom headers", ^{
            [op addHeaders:@{@"Custom-Header" : @"Value of custon header"}];
            [[[op.readonlyRequest allHTTPHeaderFields][@"Custom-Header"] should] equal:@"Value of custon header"];
        });
        it(@"should has appropriate Authorization header for bacic http auth", ^{
            // example values in this test were taken from http://www.ietf.org/rfc/rfc2617.txt
            [op setUsername:@"Aladdin" password:@"open sesame" basicAuth:YES];
            [[[op.readonlyRequest allHTTPHeaderFields][@"Authorization"] should] equal:@"Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=="];
        });

        it(@"should has appropriate Authorization header for provided AuthType ", ^{
            [op setAuthorizationHeaderValue:@"abracadabra" forAuthType:@"Token"];
            [[[op.readonlyRequest allHTTPHeaderFields][@"Authorization"] should] equal:@"Token abracadabra"];
        });
        context(@"with completion and error blocks", ^{
            __block BOOL completionBlockCalled = NO;
            __block BOOL errorBlockCalled = NO;

            beforeEach(^{
                completionBlockCalled = NO;
                errorBlockCalled = NO;
                [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
                    completionBlockCalled = YES;
                } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
                    errorBlockCalled = YES;
                }];
            });
            it(@"should call completion block on success", ^{
                [op operationSucceeded];
                [[theValue(completionBlockCalled) should] beTrue];
                [[theValue(errorBlockCalled) should] beFalse];
            });
            it(@"should call error block on failure", ^{
                [op operationFailedWithError:[NSError nullMock]];
                [[theValue(completionBlockCalled) should] beFalse];
                [[theValue(errorBlockCalled) should] beTrue];
            });
            context(@"with one more completion block and one more error block", ^{
                __block BOOL secondCompletionBlockCalled = NO;
                __block BOOL secondErrorBlockCalled = NO;

                beforeEach(^{
                    secondCompletionBlockCalled = NO;
                    secondErrorBlockCalled = NO;
                    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
                        secondCompletionBlockCalled = YES;
                    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
                        secondErrorBlockCalled = YES;
                    }];
                });

                it(@"should call both completion blocks", ^{
                    [op operationSucceeded];
                    [[theValue(completionBlockCalled) should] beTrue];
                    [[theValue(secondCompletionBlockCalled) should] beTrue];
                });
                it(@"should call both error blocks", ^{
                    [op operationFailedWithError:[NSError nullMock]];
                    [[theValue(errorBlockCalled) should] beTrue];
                    [[theValue(secondErrorBlockCalled) should] beTrue];
                });
            });
        });
        it(@"should call completion block with appropriate operation", ^{
            __block MKNetworkOperation *passedOperation = nil;
            [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
                passedOperation = completedOperation;
            } errorHandler:nil];
            [op operationSucceeded];
            [[passedOperation should] beIdenticalTo:op];
        });

        it(@"should call error block with appropriate parameters", ^{
            NSError *error = [NSError nullMock];
            __block MKNetworkOperation *passedOperation = nil;
            __block NSError *passedError = nil;
            [op addCompletionHandler:nil errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
                passedOperation = completedOperation;
                passedError = error;
            }];
            [op operationFailedWithError:error];
            [[passedOperation should] beIdenticalTo:op];
            [[passedError should] beIdenticalTo:error];
        });
    });

    context(@"when finished with status code", ^{
        __block MKNetworkOperation *op = nil;
        beforeEach(^{
            op =[[MKNetworkOperation alloc] initWithURLString:@"http://example.com/api" params:nil httpMethod:@"GET"];
            [op stub:@selector(notifyCache)];
        });
        NSArray *successCodes = @[@200, @201, @202, @203, @204, @205, @206];
        for (NSNumber *statusCode in successCodes) {
            it([NSString stringWithFormat:@"%@ - should call operationSucceeded", statusCode], ^{
                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                                          statusCode:[statusCode intValue]
                                                                         HTTPVersion:nil
                                                                        headerFields:nil];
                [op stub:@selector(response) andReturn:response];
                [[op should] receive:@selector(operationSucceeded)];
                [op connectionDidFinishLoading:[NSURLConnection nullMock]];
            });
        }

        NSArray *failedCodes = @[@400, @401, @402, @403, @404, @405, @406, @407,
                                 @408, @409, @410, @411, @412, @413, @414, @415,
                                 @416, @417, @500, @501, @502, @503, @504, @505];
        for (NSNumber *statusCode in failedCodes) {
            it([NSString stringWithFormat:@"%@ - should call operationFailedWithError", statusCode], ^{
                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                                          statusCode:[statusCode intValue]
                                                                         HTTPVersion:nil
                                                                        headerFields:nil];
                [op stub:@selector(response) andReturn:response];
                [[op should] receive:@selector(operationFailedWithError:)];
                [op connectionDidFinishLoading:[NSURLConnection nullMock]];
            });
        }
    });
    context(@"with the same operation", ^{
        __block MKNetworkOperation *op1 = nil;
        __block MKNetworkOperation *op2 = nil;
        beforeEach(^{
            op1 =[[MKNetworkOperation alloc] initWithURLString:@"http://example.com/api" params:nil httpMethod:@"GET"];
            op2 =[[MKNetworkOperation alloc] initWithURLString:@"http://example.com/api" params:nil httpMethod:@"GET"];
        });
        it(@"should equal", ^{
            [[op1 should] equal:op2];
        });
        it(@"shouldn't be inserted twice into NSSet", ^{
            NSMutableSet *collection = [NSMutableSet set];
            [collection addObject:op1];
            [collection addObject:op2];

            [[theValue([collection count]) should] equal:theValue(1)];
            [[theValue([collection containsObject:op1]) should] beTrue];
            [[theValue([collection containsObject:op2]) should] beTrue];
        });
    });
});

SPEC_END
