/*
    File:       ServerTrustChallengeHandler.m

    Contains:   Handles HTTPS server trust challenges.

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

#import "ServerTrustChallengeHandler.h"

#import "Credentials.h"

#import "DebugOptions.h"

@interface ServerTrustChallengeHandler ()

@property (nonatomic, retain, readwrite) UIAlertView *  alertView;

@end

@implementation ServerTrustChallengeHandler

+ (void)registerHandlers
    // Called by the handler registry within ChallengeHandler to request that the 
    // concrete subclass register itself.
{
    // We observe the serverValidation debug option and, when it changes, either register 
    // or deregister ourselves based on the value of the option.  We pass in 
    // NSKeyValueObservingOptionInitial so that our observer is called immediately, and this 
    // then sets up our initial state.
    [[DebugOptions sharedDebugOptions] addObserver:self forKeyPath:@"serverValidation" options:NSKeyValueObservingOptionInitial context:NULL];
}

+ (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
    // A KVO callback called when the serverValidation debug option changes.  If the user 
    // has requested default validation, we pull ourselves out of the registry, otherwise we 
    // make sure we're in there.
{
    if ( (object == [DebugOptions sharedDebugOptions]) && [keyPath isEqual:@"serverValidation"] ) {
        
        // The following code relies on two properties of challenge handling registration:
        //
        // o It's OK to deregister a handler that's not registered.
        // o It's OK to register a handler that's already registered.
        //
        // Without these two properties this code would have to keep track of whether it's 
        // registered or not, which would be less fun.
        
        if ([DebugOptions sharedDebugOptions].serverValidation == kDebugOptionsServerValidationDefault) {
            [ChallengeHandler deregisterHandlerClass:[self class] forAuthenticationMethod:NSURLAuthenticationMethodServerTrust];
        } else {
            [ChallengeHandler registerHandlerClass:[self class] forAuthenticationMethod:NSURLAuthenticationMethodServerTrust];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    assert(self.alertView == nil);
    [super dealloc];
}

#pragma mark * Core code

@synthesize alertView = _alertView;

static SecCertificateRef SecTrustGetLeafCertificate(SecTrustRef trust)
    // Returns the leaf certificate from a SecTrust object (that is always the 
    // certificate at index 0).
{
    SecCertificateRef   result;
    
    assert(trust != NULL);
    
    if (SecTrustGetCertificateCount(trust) > 0) {
        result = SecTrustGetCertificateAtIndex(trust, 0);
        assert(result != NULL);
    } else {
        result = NULL;
    }
    return result;
}

static NSMutableDictionary * sSiteToCertificateMap;     // keys are host names as NSString 
                                                        // values are SecCertificateRef

+ (void)resetTrustedCertificates
{
    // We don't just release the entire array because the _serverTrustResolvedWithSuccess 
    // code assumes that, if execution gets that far, sSiteToCertificateMap is not nil.
    if (sSiteToCertificateMap != nil) {
        [sSiteToCertificateMap removeAllObjects];
    }
}

- (void)_serverTrustResolvedWithSuccess:(BOOL)success rememberSuccess:(BOOL)rememberSuccess
    // Some common code that's called in a variety of places to finally resolve the 
    // challenge.  Also, if rememberSuccess is set, we add an entry for this challenge 
    // into sSiteToCertificateMap so that future challenges can be automatically resolved.
{
    NSURLCredential *   credential;
    
    // ! success && rememberSuccess is a weird combination, but we allow is so 
    // that our clients don't have to jump through too many hoops.
    
    // On succes, create a credential with which to resolve the challenge.

    credential = nil;
    if (success) {
        NSURLProtectionSpace *  protectionSpace;
        SecTrustRef             trust;
        NSString *              host;
        SecCertificateRef       serverCert;

        protectionSpace = [self.challenge protectionSpace];
        assert(protectionSpace != nil);
        
        trust = [protectionSpace serverTrust];
        assert(trust != NULL);
        
        credential = [NSURLCredential credentialForTrust:trust];
        assert(credential != nil);
        
        // If we've been asked to remember the response, do so now.
        
        if (rememberSuccess) {
            assert(sSiteToCertificateMap != nil);
            
            host = [[self.challenge protectionSpace] host];
            assert(host != nil);
            if ( [sSiteToCertificateMap objectForKey:host] == nil ) {

                serverCert = SecTrustGetLeafCertificate(trust);
                if (serverCert != NULL) {
                    [sSiteToCertificateMap setObject:(id)serverCert forKey:host];
                }
            }
        }
    }

    // Pass the final credential to the base class's stop code (which in turn 
    // tells us to tear down our UI) and then tell our delegate.

    [self stopWithCredential:credential];
    [self.delegate challengeHandlerDidFinish:self];
}

- (void)_evaluateAskPerUntrustedSiteTrust
    // Implements the kDebugOptionsServerValidationAskPerUntrustedSite server trust 
    // validation option.
{
    OSStatus                err;
    NSURLProtectionSpace *  protectionSpace;
    SecTrustRef             trust;
    BOOL                    trusted;
    SecTrustResultType      trustResult;
    SecCertificateRef       previousCert;

    protectionSpace = [self.challenge protectionSpace];
    assert(protectionSpace != nil);
    
    trust = [protectionSpace serverTrust];
    assert(trust != NULL);
    
    // Evaluate the trust the standard way.
    
    err = SecTrustEvaluate(trust, &trustResult);
    trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified));
    
    // If the standard policy says that it's trusted, allow it right now. 
    // Otherwise do our custom magic.
    
    if (trusted) {
        [self _serverTrustResolvedWithSuccess:YES rememberSuccess:NO];
    } else {
        if (sSiteToCertificateMap == nil) {
            sSiteToCertificateMap = [[NSMutableDictionary alloc] init];
            assert(sSiteToCertificateMap != nil);
        }
    
        // Check to see if we've previously seen this server.
        
        previousCert = (SecCertificateRef) [sSiteToCertificateMap objectForKey:[protectionSpace host]];
        assert( (previousCert == NULL) || (CFGetTypeID(previousCert) == SecCertificateGetTypeID()) );
        
        if (previousCert == NULL) {
            // We've not seen this server before.  Ask the user.
            
            assert(self.alertView == nil);
            self.alertView = [[[UIAlertView alloc] initWithTitle:@"ACCEPT WEBSITE CERTIFICATE" 
                message:@"THE CERTIFICATE FOR THIS WEBSITE IS INVALID. TAP ACCEPT TO CONNECT TO THIS WEBSITE ANYWAY." 
                delegate:self 
                cancelButtonTitle:@"Accept" 
                otherButtonTitles:@"Cancel", 
                nil
            ] autorelease];
            assert(self.alertView != nil);

            [self.alertView show];
            
            // continues in -alertView:clickedButtonAtIndex:
        } else {
            BOOL                success;
            SecCertificateRef   serverCert;
            
            // We've seen this server before.  Check to see whether the 
            // certificate from the connection matches the certificate 
            // we saw last time.  If so, allow the connection.  If not, 
            // deny the connection.
            
            success = NO;
            serverCert = SecTrustGetLeafCertificate(trust);
            if (serverCert != NULL) {
                CFDataRef       previousCertData;
                CFDataRef       serverCertData;
                
                previousCertData = SecCertificateCopyData(previousCert);
                serverCertData   = SecCertificateCopyData(serverCert  );

                assert(previousCertData != NULL);
                assert(serverCertData   != NULL);
                
                success = CFEqual(previousCertData, serverCertData);
                
                CFRelease(previousCertData);
                CFRelease(serverCertData);
            }
            
            if (success) {
                [self _serverTrustResolvedWithSuccess:YES rememberSuccess:NO];
            } else {
                [self _serverTrustResolvedWithSuccess:NO  rememberSuccess:NO];
            }
        }
    }
}

- (void)_evaluateImportedCertificatesTrust
    // Implements the kDebugOptionsServerValidationTrustImportedCertificates server 
    // trust validation option.
{
    OSStatus                err;
    NSURLProtectionSpace *  protectionSpace;
    SecTrustRef             trust;
    SecTrustResultType      trustResult;
    BOOL                    trusted;
    
    protectionSpace = [self.challenge protectionSpace];
    assert(protectionSpace != nil);
    
    trust = [protectionSpace serverTrust];
    assert(trust != NULL);

    // Evaluate the trust the standard way.
    
    err = SecTrustEvaluate(trust, &trustResult);
    trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified));
    
    // If that fails, apply our certificates as anchors and see if that helps.
    // 
    // It's perfectly acceptable to apply all of our certificates to the SecTrust 
    // object, and let the SecTrust object sort out the mess.  Of course, this assumes 
    // that the user trusts all certificates equally in all situations, which is implicit 
    // in our user interface; you could provide a more sophisticated user interface 
    // to allow the user to trust certain certificates for certain sites and so on).
    
    if ( ! trusted ) {
        err = SecTrustSetAnchorCertificates(trust, (CFArrayRef) [Credentials sharedCredentials].certificates);
        if (err == noErr) {
            err = SecTrustEvaluate(trust, &trustResult);
        }
        trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified));
    }
    
    if (trusted) {
        [self _serverTrustResolvedWithSuccess:YES rememberSuccess:NO];
    } else {
        [self _serverTrustResolvedWithSuccess:NO  rememberSuccess:NO];
    }
}

- (void)_handleServerTrustChallenge
    // Handles a server trust challenge according to the serverValidation debug option. 
    // This is called out of -didStart, and thus can present UI.  However, it may 
    // or not present UI depending on the specific server trust and debug options.
{
    switch ( [DebugOptions sharedDebugOptions].serverValidation ) {
        default:
            // fall through
        case kDebugOptionsServerValidationDefault: {
            // We should never have got here because we deregister ourselves when 
            // the user selects the default case.
            assert(NO);
            [self _serverTrustResolvedWithSuccess:NO rememberSuccess:NO];
        } break;
        case kDebugOptionsServerValidationAskPerUntrustedSite: {
            [self _evaluateAskPerUntrustedSiteTrust];
        } break;
        case kDebugOptionsServerValidationTrustImportedCertificates: {
            [self _evaluateImportedCertificatesTrust];
        } break;
        case kDebugOptionsServerValidationDisabled: {
            // Just say yes.
            [self _serverTrustResolvedWithSuccess:YES rememberSuccess:NO];
        } break;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
    // An alert view delegate callback that's called when the alert is dismissed.  
    // We use the tapped button index to decide how to resolve the challenge.
{
    #pragma unused(alertView)
    assert(alertView == self.alertView);
    [self _serverTrustResolvedWithSuccess:(buttonIndex == 0) rememberSuccess:YES];
}

#pragma mark * Override points

- (void)didStart
    // Called by our base class to tell us to create our UI.
{
    [super didStart];
    [self _handleServerTrustChallenge];
}

- (void)willFinish
    // Called by our base class to tell us to tear down our UI.
{
    [super willFinish];
    
    // If an alert is still up, tear it down immediately.
    
    if (self.alertView != nil) {
        self.alertView.delegate = nil;
        [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:NO];
        self.alertView = nil;
    }
}

@end
