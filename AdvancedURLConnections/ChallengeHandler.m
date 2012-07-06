/*
    File:       ChallengeHandler.m

    Contains:   Base class for handling various authentication challenges.

    Written by: DTS

    Copyright:  Copyright (c) 2011 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "ChallengeHandler.h"

@interface ChallengeHandler ()
@property (nonatomic, assign, readwrite, getter=isRunning)  BOOL        running;
@end

@implementation ChallengeHandler

static NSMutableDictionary * sAuthenticationMethodToHandlerClassArray;

+ (void)registerHandlers
{
    assert(NO);         // must be overridden by subclass
}

+ (void)registerAllHandlers
{
    // Register all of our support challenge handlers.  There are various ways 
    // you can automate this (objc_getClassList anyone?), but I decided to just 
    // hardwire the classes right now.
    
    static BOOL sHaveRegistered;
    if ( ! sHaveRegistered ) {
        for (NSString * className in [NSArray arrayWithObjects:@"AuthenticationChallengeHandler", @"ServerTrustChallengeHandler", @"ClientIdentityChallengeHandler", nil]) {
            Class   cls;

            cls = NSClassFromString(className);
            assert(cls != nil);
            [cls registerHandlers];
        }
        sHaveRegistered = YES;
    }
}

+ (BOOL)supportsProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    BOOL                result;
    NSString *          authenticationMethod;
    NSMutableArray *    handlerClasses;

    assert(protectionSpace != nil);

    [self registerAllHandlers];

    authenticationMethod = [protectionSpace authenticationMethod];
    assert(authenticationMethod != nil);

    result = NO;
    if (sAuthenticationMethodToHandlerClassArray != nil) {
        handlerClasses = (NSMutableArray *) [sAuthenticationMethodToHandlerClassArray objectForKey:authenticationMethod];
        if (handlerClasses != nil) {
            assert([handlerClasses isKindOfClass:[NSMutableArray class]]);
            result = YES;
        }
    }
    return result;
}

+ (ChallengeHandler *)handlerForChallenge:(NSURLAuthenticationChallenge *)challenge parentViewController:(UIViewController *)parentViewController
{
    ChallengeHandler *  result;
    NSString *          authenticationMethod;
    NSMutableArray *    handlerClasses;

    assert([NSThread isMainThread]);
    assert(challenge != nil);
    assert(parentViewController != nil);
    
    [self registerAllHandlers];
    
    authenticationMethod = [[challenge protectionSpace] authenticationMethod];
    assert(authenticationMethod != nil);
    
    result = nil;
    if (sAuthenticationMethodToHandlerClassArray != nil) {
        handlerClasses = (NSMutableArray *) [sAuthenticationMethodToHandlerClassArray objectForKey:authenticationMethod];
        if (handlerClasses != nil) {
            assert([handlerClasses isKindOfClass:[NSMutableArray class]]);
            
            for (Class candidateClass in handlerClasses) {
                result = [[[candidateClass alloc] initWithChallenge:challenge parentViewController:parentViewController] autorelease];
                if (result != nil) {
                    break;
                }
            }
        }
    }
    return result;
}

+ (void)registerHandlerClass:(Class)handlerClass forAuthenticationMethod:(NSString *)authenticationMethod
{
    NSMutableArray *    handlerClasses;
    
    assert([NSThread isMainThread]);
    assert(handlerClass != nil);
    assert(authenticationMethod != nil);
    
    if (sAuthenticationMethodToHandlerClassArray == nil) {
        sAuthenticationMethodToHandlerClassArray = [[NSMutableDictionary alloc] init];
        assert(sAuthenticationMethodToHandlerClassArray != nil);
    }
    
    handlerClasses = (NSMutableArray *) [sAuthenticationMethodToHandlerClassArray objectForKey:authenticationMethod];
    if (handlerClasses == nil) {
        handlerClasses = [NSMutableArray array];
        assert(handlerClasses != nil);
        
        [sAuthenticationMethodToHandlerClassArray setObject:handlerClasses forKey:authenticationMethod];
    }
    assert([handlerClasses isKindOfClass:[NSMutableArray class]]);
    
    // Don't register the same class twice.  This is necessary because 
    // NSURLAuthenticationMethodDefault and NSURLAuthenticationMethodHTTPBasic both 
    // have the same value, so you end up with AuthenticationChallengeHandler registered 
    // twice for that value.  That doesn't cause problems, but it's unnecessarily 
    // inefficient.
    //
    // It's also makes life easier for our clients as the user switches between 
    // various states, all of which require the same challenge handler.
    
    if ( ! [handlerClasses containsObject:handlerClass] ) {
        [handlerClasses addObject:handlerClass];
    }
}

+ (void)deregisterHandlerClass:(Class)handlerClass forAuthenticationMethod:(NSString *)authenticationMethod
{
    NSMutableArray *    handlerClasses;

    assert(handlerClass != nil);
    assert(authenticationMethod != nil);

    // As a matter of policy we allow clients to deregister stuff they haven't registered.
    // This makes it easier for clients to set up their initial state.
    
    if (sAuthenticationMethodToHandlerClassArray != nil) {
        handlerClasses = (NSMutableArray *) [sAuthenticationMethodToHandlerClassArray objectForKey:authenticationMethod];
        if (handlerClasses != nil) {
            assert([handlerClasses isKindOfClass:[NSMutableArray class]]);
            
            [handlerClasses removeObject:handlerClass];
            
            if (handlerClasses.count == 0) {
                [sAuthenticationMethodToHandlerClassArray removeObjectForKey:authenticationMethod];
            }
        }
    }
}

- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge parentViewController:(UIViewController *)parentViewController
{
    assert([NSThread isMainThread]);

    assert(challenge != nil);
    assert(parentViewController != nil);
    self = [super init];
    if (self != nil) {
        self->_challenge            = [challenge retain];
        self->_parentViewController = [parentViewController retain];
    }
    return self;
}

- (void)dealloc
{
    assert( ! self->_running );          // should not still be displaying UI
    assert([NSThread isMainThread]);
    [self->_challenge release];
    [self->_parentViewController release];
    [self->_credential release];
    [super dealloc];
}

@synthesize challenge            = _challenge;
@synthesize parentViewController = _parentViewController;
@synthesize credential           = _credential;
@synthesize delegate             = _delegate;
@synthesize running              = _running;

- (void)start
{
    assert([NSThread isMainThread]);
    assert( ! self.running );
    self.running = YES;
    [self didStart];
}

- (void)didStart
{
    // this is just an override point
}

- (void)willFinish
{
    // this is just an override point
}

- (void)didFinish
{
    // this is just an override point
}

+ (NSURLCredential *)noCredential
{
    static NSURLCredential * sNoCredential;
    assert([NSThread isMainThread]);
    if (sNoCredential == nil) {
        // The actual values we supply here are irrelevant.  We always use pointer comparison to detect this singleton.
        sNoCredential = [[NSURLCredential alloc] initWithUser:@"" password:@"" persistence:NSURLCredentialPersistenceNone];
        assert(sNoCredential != nil);
    }
    return sNoCredential;
}

- (void)stopWithCredential:(NSURLCredential *)credential
{
    assert([NSThread isMainThread]);
    
    // Allow duplicate cancels to make life easier for our clients.
    
    if (self.running) {
        [self willFinish];
        assert(self->_credential == nil);
        self->_credential = [credential retain];
        self.running = NO;
        [self didFinish];
    }
}

- (void)stop
{
    [self stopWithCredential:nil];
}

- (void)resolve
{
    assert([NSThread isMainThread]);
    assert( ! self.running );
    if (self.credential == nil) {
        [[self.challenge sender] cancelAuthenticationChallenge:self.challenge];
    } else if (self.credential == [ChallengeHandler noCredential]) {
        [[self.challenge sender] continueWithoutCredentialForAuthenticationChallenge:self.challenge];
    } else {
        [[self.challenge sender] useCredential:self.credential forAuthenticationChallenge:self.challenge];
    }
}

@end
