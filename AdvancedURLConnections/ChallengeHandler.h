/*
    File:       ChallengeHandler.h

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

// This is an abstract base class that represents a generic mechanism for handling 
// NSURLAuthenticationChallenges.  It does very little work; the bulk of the work 
// is done by the various concrete subclasses (such as AuthenticationChallengeHandler). 
// The only real work done here is to maintain a register of challenge handler 
// classes that stand ready to handle various types of challenges.

// IMPORTANT
// This is /not/ a UIViewController subclass because certain challenges are 
// resolved without a presenting a full view controller (for example, those 
// that can be resolved with a UIAlertView).

#import <UIKit/UIKit.h>

@protocol ChallengeHandlerDelegate;

@interface ChallengeHandler : NSObject
{
    NSURLAuthenticationChallenge *  _challenge;
    UIViewController *              _parentViewController;
    NSURLCredential *               _credential;
    id<ChallengeHandlerDelegate>    _delegate;
    BOOL                            _running;
}

+ (BOOL)supportsProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
    // Returns true if we have a challenge handler that will handle challenges 
    // in the specified protection space.

+ (ChallengeHandler *)handlerForChallenge:(NSURLAuthenticationChallenge *)challenge parentViewController:(UIViewController *)parentViewController;
    // Returns a challenge handler that's prepared to handle the specified challenge 
    // (and that presents any modal view controllers on top of parentViewController). 
    // Alternatively, returns nil if no one is prepared to handle this challenge.

+ (NSURLCredential *)noCredential;
    // A special singleton value used to represent no credential.  When a challenge 
    // is resolved with this value, we call -continueWithoutCredentialForAuthenticationChallenge: 
    // rather than -useCredential:forAuthenticationChallenge:.

@property (nonatomic, retain, readonly)  NSURLAuthenticationChallenge * challenge;
@property (nonatomic, retain, readonly)  UIViewController *             parentViewController;
    // These are the values supplied during construction.

@property (nonatomic, retain, readonly)  NSURLCredential *              credential;
    // This represents the credential being used to resolve the challenge.  If the 
    // challenge UI is still running, this will be nil.  Once the challenge UI 
    // is done (that is, the challenge handler has called the -challengeHandlerDidFinish: 
    // delegate method, or you've called -stop yourself), this will be nil, or 
    // +noCredential, or an actual credential. 
    
@property (nonatomic, assign, readwrite) id<ChallengeHandlerDelegate>   delegate;

@property (nonatomic, assign, readonly, getter=isRunning)  BOOL         running;
    // This is YES if the challenge UI is currently being displayed.

- (void)start;
    // Starts the challenge UI running.  This transitions isRunning from YES 
    // to NO (although it may transition straight back again, see the next point). 
    // 
    // This may call the -challengeHandlerDidFinish: delegate method immediately.
    // 
    // Do not call this twice on the same challenge.

- (void)stopWithCredential:(NSURLCredential *)credential;
- (void)stop;
    // Stops the challenge handler running and sets the credential to the value 
    // specified.  -stop is equivalent to -stopWithCredential: with a nil credential. 
    // This can be called either by the challenge UI (when the user completes the 
    // UI, just before calling the -challengeHandlerDidFinish: delegate method) or 
    // by the client (when external forces cause the challenge to no longer be 
    // relevant).  It shuts down the UI and transitions isRunning from YES to NO. 
    //
    // It's not legal to call this on a challenge that hasn't been started.
    // It's legal to call this on a challenge that's already been stopped.

- (void)resolve;
    // Called by the client after the challenge has stopped to actually apply the 
    // credential to the NSURLAuthenticationChallenge.

// The following methods are typically used by folks implementating concrete subclasses 
// of ChallengeHandler.

+ (void)registerHandlers;
    // Called by the handler registry within ChallengeHandler to request that the 
    // concrete subclass register itself.

- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge parentViewController:(UIViewController *)parentViewController;
    // You can call this directly if you like, but mostly this is called by 
    // +handlerForChallenge:parentViewController: to initialise an instance of 
    // a concrete challenge handler class.
    //
    // A concrete implementation can return nil to opt out of this specific challenge 
    // (in which case +handlerForChallenge:parentViewController: will try to find 
    // another appropriate challenge handler class).

- (void)didStart;
    // In general a subclass will override this to create its UI.
    
- (void)willFinish;
    // In general a subclass will override this to shut down its UI.

- (void)didFinish;
    // This is typically not used by a subclasses.

+ (void)registerHandlerClass:(Class)handlerClass forAuthenticationMethod:(NSString *)authenticationMethod;
    // Subclasses call this to register themselves for consideration by 
    // +handlerForChallenge:parentViewController:.
    //
    // It is acceptable for register yourself twice for the same authentication method.  
    // The second registration is treated as a no-op.

+ (void)deregisterHandlerClass:(Class)handlerClass forAuthenticationMethod:(NSString *)authenticationMethod;
    // Subclasses call this to deregister themselves.  This is useful for 
    // the ServerTrustChallengeHandler, which deregisters itself if the 
    // user has specified that we use the default trust evaluation process.
    //
    // It is acceptable to deregister yourself even if you've not registered 
    // yourself.

@end

@protocol ChallengeHandlerDelegate <NSObject>

@required

- (void)challengeHandlerDidFinish:(ChallengeHandler *)handler;
    // Called by the challenge handler when the user completes the challenge 
    // UI.  The result of the challenge will be available via the credential
    // property.  Call -resolve to apply this to the NSURLAuthenticationChallenge.
    //
    // isRunning will be NO by the time this is called.

@end
