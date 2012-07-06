/*
    File:       AuthenticationChallengeHandler.m

    Contains:   Handles HTTP authentication challenges.

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

#import "AuthenticationChallengeHandler.h"

#import "AuthenticationController.h"

#import "DebugOptions.h"

@interface AuthenticationChallengeHandler () <AuthenticationControllerDelegate>

@property (nonatomic, retain, readwrite) AuthenticationController * viewController;

@end

@implementation AuthenticationChallengeHandler

+ (void)registerHandlers
    // Called by the handler registry within ChallengeHandler to request that the 
    // concrete subclass register itself.
{
    [ChallengeHandler registerHandlerClass:[self class] forAuthenticationMethod:NSURLAuthenticationMethodDefault];
    [ChallengeHandler registerHandlerClass:[self class] forAuthenticationMethod:NSURLAuthenticationMethodHTTPBasic];
    [ChallengeHandler registerHandlerClass:[self class] forAuthenticationMethod:NSURLAuthenticationMethodHTTPDigest];
    [ChallengeHandler registerHandlerClass:[self class] forAuthenticationMethod:NSURLAuthenticationMethodNTLM];
}

- (void)dealloc
{
    assert(self.viewController == nil);
    [super dealloc];
}

#pragma mark * View management

@synthesize viewController = _viewController;

- (void)_bringUpView
    // Displays the authentication user interface.  
{
    self.viewController = [[[AuthenticationController alloc] initWithChallenge:self.challenge] autorelease];
    assert(self.viewController != nil);
    
    self.viewController.persistence = [DebugOptions sharedDebugOptions].credentialPersistence;
    
    self.viewController.delegate = self;
    
    [self.parentViewController presentModalViewController:self.viewController animated:YES];

    // continues in -authenticationView:didEnterCredential:
}

- (void)_tearDownView
    // Hides the authentication user interface.
{
    // If the view is still up, tear it down /quickly/.  We need this in case 
    // we get externally cancelled.  In that case -authenticationView:didEnterCredential: 
    // is never called, so we never dismiss the modal view controller that we presented.  
    // However, we can't do it every time because then the modal view controller will get 
    // dismissed twice.  And we can't not dismiss the view controller in 
    // -authenticationView:didEnterCredential:, because of the requirement to work around 
    // <rdar://problem/6291461> (described below).
    //
    // Also, we don't want to hear about any delegate callbacks from now or, so just 
    // nil out the delegate.  Without this we get crashes as the AuthenticationController's 
    // -viewWillDisappear: method, which runs asynchronously with respect to the 
    // dismiss call below, tries to tell us about this fact.

    assert(self.viewController != nil);
    self.viewController.delegate = nil;

    if (self.viewController.parentViewController != nil) {
        [self.parentViewController dismissModalViewControllerAnimated:NO];
    }
    self.viewController = nil;
}

- (void)_gotCredential:(NSURLCredential *)credential
    // Called by one of the two AuthenticationController delegate callbacks when the user 
    // taps Cancel or Log In.  We tell the base class to stop (which in turn 
    // tells us to tear down our UI) and then we tell our delegate.
{
    // credential may be nil
    [self stopWithCredential:credential];
    [self.delegate challengeHandlerDidFinish:self];
}

// This Boolean controls the workaround to <rdar://problem/6291461>, a bug in 
// iPhone OS 3.x that causes a crash if you present a second modal view controller 
// while the first one is in the process of being dismissed.  Without this workaround, 
// if the user enters the wrong password (and hence generates an immediate repeat 
// of the authentication challenge), we bring up a second AuthenticationViewController 
// while the first one is still being dismissed and we crash.

static BOOL kWorkAround_6291461 = YES;

- (void)authenticationView:(AuthenticationController *)controller didEnterCredential:(NSURLCredential *)credential
    // An authentication controller delegate callback that's called when the user 
    // taps Cancel or Log In.  We respond by dismissing our view controller.  
    // Once that's done, in the -authenticationViewDidDisappear: delegate callback 
    // below, we can actually proceed with telling our delegate about the event.
{
    #pragma unused(controller)
    assert(controller == self.viewController);
    // credential may be nil
    
    assert(controller.challenge == self.challenge);
    
    // Dismiss the modal view controller.  Actually, /start/ to dismiss it.  
    // When it's done, we'll get the -authenticationViewDidDisappear: callback 
    // to continue processing.
    
    [self.parentViewController dismissModalViewControllerAnimated:YES];

    if (kWorkAround_6291461) {
        // We do this work in -authenticationViewDidDisappear:, but it has know 
        // whether this method was called so that it can tell whether to notify 
        // our delegate.  Otherwise, if our client cancels the challenge 
        // (by calling -stop), we end up calling it back (via the delegate callback)
        // indicating that we cancelled, which is pretty silly: it knows we cancelled, 
        // it asked us to.
        self->_didEnterCredential = YES;
    } else {
        [self _gotCredential:credential];
    }
}

- (void)authenticationViewDidDisappear:(AuthenticationController *)controller
    // An authentication controller delegate callback that's called when the 
    // view controller finally disappears.  We use this to continue the processing 
    // we deferred in -authenticationView:didEnterCredential:.
{
    assert(controller == self.viewController);
    
    if (kWorkAround_6291461) {
        if (self->_didEnterCredential) {
            [self _gotCredential:controller.credential];
            self->_didEnterCredential = NO;
        }
    }
}

#pragma mark * Override points

- (void)didStart
    // Called by our base class to tell us to create our UI.
{
    [super didStart];
    [self _bringUpView];
}

- (void)willFinish
    // Called by our base class to tell us to tear down our UI.
{
    [super willFinish];
    [self _tearDownView];
}

@end
