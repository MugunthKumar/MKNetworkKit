#import "Kiwi.h"

SPEC_BEGIN(MKNetworkEngineSpec)

describe(@"Network Engine", ^{
    it(@"should be initialized", ^{
        MKNetworkEngine *engine = [[MKNetworkEngine alloc] init];
        [[engine should] beNonNil];
    });
});

SPEC_END
