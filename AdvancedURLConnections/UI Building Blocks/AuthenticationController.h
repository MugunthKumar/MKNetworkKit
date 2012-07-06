/*
    File:       AuthenticationController.h

    Contains:   Runs an HTTP authentication challenge view.

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

#import <UIKit/UIKit.h>

// You typically run this view controller by:
//
// 1. creating it with an authentication challenge
// 2. setting yourself as the delegate
// 3. setting persistence to meet your requirements
// 4. presenting it modally
//
// When the user taps Log In or Cancel, your -authenticationView:didEnterCredential: 
// delegate callback will be called.  If credential is nil, it was a Cancel. 
//
// Finally, dismiss the view controller.  -authenticationViewDidDisappear: will be 
// called when it's all gone.

@protocol AuthenticationControllerDelegate;

@interface AuthenticationController : UIViewController
{
    UITextField *                           _userField;
    UITextField *                           _passwordField;
    UILabel *                               _realmLabel;
    UILabel *                               _passwordDispositionLabel;
    
    NSURLAuthenticationChallenge *          _challenge;
    NSURLCredentialPersistence              _persistence;
    NSURLCredential *                       _credential;
    id<AuthenticationControllerDelegate>    _delegate;
    BOOL                                    _showingAuthMethod;
}

- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge;

@property (nonatomic, retain, readwrite) IBOutlet UITextField *     userField;
@property (nonatomic, retain, readwrite) IBOutlet UITextField *     passwordField;
@property (nonatomic, retain, readwrite) IBOutlet UILabel *         realmLabel;
@property (nonatomic, retain, readwrite) IBOutlet UILabel *         passwordDispositionLabel;

- (IBAction)logInAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@property (nonatomic, retain, readonly)  NSURLAuthenticationChallenge *         challenge;
    // This is the challenge passed to -initWithChallenge:.

@property (nonatomic, assign, readwrite) NSURLCredentialPersistence             persistence;
    // This allows you to control persistence of credential created by this class. 
    // You typically set this before activating the view controller, although it 
    // will be effective up to the point that credential is created.

@property (nonatomic, assign, readwrite) id<AuthenticationControllerDelegate>   delegate;

@property (nonatomic, retain, readonly)  NSURLCredential *                      credential;
    // The credential created by the user.  This will be nil if the taps Cancel, or 
    // if prior to the -authenticationView:didEnterCredential: delegate callback.

@end

@protocol AuthenticationControllerDelegate <NSObject>

@required

- (void)authenticationView:(AuthenticationController *)controller didEnterCredential:(NSURLCredential *)credential;
    // Called by AuthenticationController when the user either taps Cancel or 
    // Log In.  credential will be nil in the cancel case.

@optional

- (void)authenticationViewDidDisappear:(AuthenticationController *)controller;
    // Called by AuthenticationController when the view disappears.

@end
