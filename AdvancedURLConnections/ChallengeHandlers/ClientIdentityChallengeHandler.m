/*
    File:       ClientIdentityChallengeHandler.m

    Contains:   Handles HTTPS client identity challenges.

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

#import "ClientIdentityChallengeHandler.h"

#import "ClientIdentityController.h"

#import "Credentials.h"

#import "DebugOptions.h"

@interface ClientIdentityChallengeHandler () <ClientIdentityControllerDelegate>

@property (nonatomic, retain, readwrite) ClientIdentityController * viewController;
@property (nonatomic, retain, readwrite) UIAlertView *              alertView;

@end

@implementation ClientIdentityChallengeHandler

+ (void)registerHandlers
    // Called by the handler registry within ChallengeHandler to request that the 
    // concrete subclass register itself.
{
    [ChallengeHandler registerHandlerClass:[self class] forAuthenticationMethod:NSURLAuthenticationMethodClientCertificate];
}

- (void)dealloc
{
    assert(self.alertView == nil);
    assert(self.viewController == nil);
    [super dealloc];
}

#pragma mark * View management

@synthesize viewController = _viewController;
@synthesize alertView      = _alertView;

- (void)_clientIdentityResolvedWithIdentity:(SecIdentityRef)identity
    // Some common code that's called in a variety of places to finally 
    // resolve the challenge.
{
    // identity may be NULL
    NSURLCredential *           credential;

    // If we got an identity, create a credential for that identity.
    
    credential = nil;
    if (identity != NULL) {
        NSURLCredentialPersistence  persistence;

        persistence = [DebugOptions sharedDebugOptions].credentialPersistence;
        // assert(persistence >= NSURLCredentialPersistenceNone);   -- not necessary because NSURLCredentialPersistence is unsigned
        assert(persistence <= NSURLCredentialPersistencePermanent);
        
        credential = [NSURLCredential credentialWithIdentity:identity certificates:nil persistence:persistence];
        assert(credential != nil);
    }
    
    // Pass the final credential to the base class's stop code (which in turn 
    // tells us to tear down our UI) and then tell our delegate.
    
    [self stopWithCredential:credential];
    [self.delegate challengeHandlerDidFinish:self];
}

- (void)_bringUpView
    // Displays the authentication user interface.  
{
    NSArray *   identities;
    NSUInteger  identityCount;

    identities = [Credentials sharedCredentials].identities;
    assert(identities != nil);
    
    identityCount = identities.count;
    if ( [DebugOptions sharedDebugOptions].alwaysPresentIdentityChoice ) {
        identityCount = 2;
    }
    
    switch (identityCount) {
        case 0: {
            // If there are no available identities, we just fail.
            
            assert(self.alertView == nil);
            self.alertView = [[[UIAlertView alloc] initWithTitle:@"THIS WEBSITE REQUIRES AN IDENTITY" 
                message:@"THE REQUIRED IDENTITY IS NOT INSTALLED."
                delegate:self 
                cancelButtonTitle:@"DISMISS" 
                otherButtonTitles:nil
            ] autorelease];
            assert(self.alertView != nil);

            [self.alertView show];

            // continues in -alertView:clickedButtonAtIndex:
        } break;
        case 1: {
            SecIdentityRef              identity;

            // If there's only one available identity, that's gotta be the right one.
            
            identity = (SecIdentityRef) [identities objectAtIndex:0];
            assert( (identity != NULL) && (CFGetTypeID(identity) == SecIdentityGetTypeID()) );

            [self _clientIdentityResolvedWithIdentity:identity];
        } break;
        default: {
            // If there are multiple available identities, ask the user to choose.

            assert(self.viewController == nil);
            self.viewController = [[[ClientIdentityController alloc] initWithChallenge:self.challenge] autorelease];
            assert(self.viewController != nil);
            
            self.viewController.delegate = self;
            
            [self.parentViewController presentModalViewController:self.viewController animated:YES];
            
            // continues in -identityView:didChooseIdentity:
        } break;
    }
}

- (void)_tearDownView
    // Hides the authentication user interface.
{
    // See comments in -[AuthenticationChallengeHandler _tearDownView].

    // The view controller might be up, or the alert view, or neither.  The only 
    // combination that's illegal is having them /both/ up!
    assert( (self.viewController == nil) || (self.alertView == nil) );

    // Tear down the view controller if it's up.
    
    if (self.viewController != nil) {
        self.viewController.delegate = nil;

        if (self.viewController.parentViewController != nil) {
            [self.parentViewController dismissModalViewControllerAnimated:NO];
        }
        self.viewController = nil;
    }
    
    // Tear down our alert view if it's up.
    
    if (self.alertView != nil) {
        self.alertView.delegate = nil;  // Just in case we get hit by the same sort of problem 
                                        // that we saw in the view controller case, as described 
                                        // in -[AuthenticationChallengeHandler _tearDownView].
        [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:NO];
        self.alertView = nil;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
    // An alert view delegate callback that's called when the alert is dismissed.  
    // As we only use the alert view to display errors, we also respond to this 
    // by failing (calling -_clientIdentityResolvedWithIdentity: with nil).
{
    #pragma unused(alertView)
    #pragma unused(buttonIndex)
    assert(alertView == self.alertView);
    assert(buttonIndex == 0);
    [self _clientIdentityResolvedWithIdentity:NULL];
}

- (void)_gotIdentity:(SecIdentityRef)identity
    // Called by one of the two ClientIdentityController delegate callbacks when the user 
    // taps Cancel or selects an identity.  We do the actual work in some common code, 
    // -_clientIdentityResolvedWithIdentity:.
{
    // identity may be NULL
    [self _clientIdentityResolvedWithIdentity:identity];
}

// See the equivalent code in "AuthenticationChallengeHandler.m" for information about 
// <rdar://problem/6291461> and this workaround.

static BOOL kWorkAround_6291461 = YES;

- (void)identityView:(ClientIdentityController *)controller didChooseIdentity:(SecIdentityRef)identity
    // A client authentication controller delegate callback that's called when the user 
    // taps Cancel or selects an identity.  We respond by dismissing our view controller.  
    // Once that's done, in the -identityViewDidDisappear: delegate callback 
    // below, we can actually proceed with telling our delegate about the event.
{
    #pragma unused(controller)
    assert(controller == self.viewController);
    // identity may be NULL
    
    assert(controller.challenge == self.challenge);

    // Dismiss the modal view controller.  Actually, /start/ to dismiss it.  
    // When it's done, we'll get the -identityViewDidDisappear: callback 
    // to continue processing.
    
    [self.parentViewController dismissModalViewControllerAnimated:YES];

    if (kWorkAround_6291461) {
        // We do this work in -identityViewDidDisappear:, but it has know 
        // whether this method was called so that it can tell whether to notify 
        // our delegate.  Otherwise, if our client cancels the challenge 
        // (by calling -stop), we end up calling it back (via the delegate callback)
        // indicating that we cancelled, which is pretty silly: it knows we cancelled, 
        // it asked us to.
        self->_didEnterIdentity = YES;
    } else {
        [self _gotIdentity:identity];
    }
}

- (void)identityViewDidDisappear:(ClientIdentityController *)controller
    // A client identiy controller delegate callback that's called when the 
    // view controller finally disappears.  We use this to continue the processing 
    // we deferred in -identityView:didChooseIdentity:.
{
    assert(controller == self.viewController);
    
    if (kWorkAround_6291461) {
        if (self->_didEnterIdentity) {
            [self _gotIdentity:controller.chosenIdentity];
            self->_didEnterIdentity = NO;
        }
    }
}

- (NSArray *)identityViewIdentitiesToDisplay:(ClientIdentityController *)controller
{
    #pragma unused(controller)
    NSArray *   result;

    assert(controller == self.viewController);
    
    if ([DebugOptions sharedDebugOptions].naiveIdentityList) {
        result = nil;
    } else {
        result = [Credentials sharedCredentials].identities;
    }
    return result;
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
