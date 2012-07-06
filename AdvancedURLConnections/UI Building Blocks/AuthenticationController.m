/*
    File:       AuthenticationController.m

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

#import "AuthenticationController.h"

@interface AuthenticationController () <UITextFieldDelegate>

@property (nonatomic, retain, readwrite) NSURLCredential *               credential;        // readwrite for internal clients
@property (nonatomic, assign, readwrite) BOOL                            showingAuthMethod;

@end

@implementation AuthenticationController

- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge
{
    assert(challenge != nil);
    
    self = [super initWithNibName:@"AuthenticationController" bundle:[NSBundle bundleForClass:[self class]]];
    if (self != nil) {
        self->_challenge = [challenge retain];
    }
    return self;
}

@synthesize challenge         = _challenge;
@synthesize persistence       = _persistence;
@synthesize credential        = _credential;
@synthesize delegate          = _delegate;
@synthesize showingAuthMethod = _showingAuthMethod;

#pragma mark * Text field delegate callbacks

- (BOOL)textFieldShouldReturn:(UITextField *)textField
    // A delegate method called by the user or password text fields when the user 
    // taps the Return key.  We respond accordingly.
{
    assert( (textField == self.userField) || (textField == self.passwordField) );
    
    if (textField == self.userField) {
        // If the focus is on the user field, switch it to the password field.
        [self.passwordField becomeFirstResponder];
    } else if (textField == self.passwordField) {
        // If the focus is on the password field, treat the return as equivalent 
        // to tapping Log In.
        [self logInAction:self];
    } else {
        assert(NO);
    }
    return NO;
}

#pragma mark * Action code

- (IBAction)logInAction:(id)sender
    // Called when the user taps the Log In button.
{
    #pragma unused(sender)
    NSString *                  user;
    NSString *                  password;
    
    // Get the user name and password, treating with nil as the empty string.
    
    user = self.userField.text;
    if (user == nil) {
        user = @"";
    }
    
    password = self.passwordField.text;
    if (password == nil) {
        password = @"";
    }
    
    // Create the credential.
    
    assert(self.credential == nil);
    self.credential = [NSURLCredential credentialWithUser:user password:password persistence:self.persistence];
    assert(self.credential != nil);
    
    // Tell the delegate.
    
    if (self.delegate != nil) {
        [self.delegate authenticationView:self didEnterCredential:self.credential];
    }
}

- (IBAction)cancelAction:(id)sender
    // Called when the user taps the Cancel button.  Just calls the delegate to 
    // let them know.
{
    #pragma unused(sender)
    if (self.delegate != nil) {
        [self.delegate authenticationView:self didEnterCredential:nil];
    }
}

- (void)setupPasswordDispositionLabel
{
    NSURLProtectionSpace *  protectionSpace;
    NSString *              authMethod;
    
    protectionSpace = [self.challenge protectionSpace];
    assert(protectionSpace != nil);

    authMethod = [protectionSpace authenticationMethod];
    assert(authMethod != nil);
    
    if (self.showingAuthMethod) {
        self.passwordDispositionLabel.text = authMethod;
    } else {
        if ( [protectionSpace receivesCredentialSecurely] ) {
            self.passwordDispositionLabel.text = @"PASSWORD WILL BE SENT SECURELY.";
        } else {
            self.passwordDispositionLabel.text = @"PASSWORD WILL BE SENT IN THE CLEAR.";
        }
    }
}

- (void)passwordDispositionLongPress:(UIGestureRecognizer*)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.showingAuthMethod = ! self.showingAuthMethod;
        [self setupPasswordDispositionLabel];
    }
}

#pragma mark * View controller boilerplate

@synthesize userField                = _userField;
@synthesize passwordField            = _passwordField;
@synthesize realmLabel               = _realmLabel;
@synthesize passwordDispositionLabel = _passwordDispositionLabel;

- (void)viewDidLoad
{
    NSURLProtectionSpace *  protectionSpace;
    NSURLCredential *       proposedCredential;
    NSString *              proposedUser;
    NSString *              proposedPassword;
    NSString *              realm;
    NSString *              host;
    UILongPressGestureRecognizer *  longPressRecognizer;
    
    [super viewDidLoad];
    
    assert(self.userField != nil);
    assert(self.userField.delegate == self);
    assert(self.passwordField != nil);
    assert(self.passwordField.delegate == self);
    assert(self.realmLabel != nil);
    assert(self.passwordDispositionLabel != nil);
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

    protectionSpace = [self.challenge protectionSpace];
    assert(protectionSpace != nil);
        
    // Tell the user how secure their password is.

    [self setupPasswordDispositionLabel];
    
    // A long press on the password disposition label will cause it to display 
    // the actual authentication method.
    
    self.passwordDispositionLabel.userInteractionEnabled = YES;
    longPressRecognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(passwordDispositionLongPress:)] autorelease];
    assert(longPressRecognizer != nil);
    longPressRecognizer.minimumPressDuration = 1.0;
    [self.passwordDispositionLabel addGestureRecognizer:longPressRecognizer];
    
    // Tell the user who they're authenticating with.
    
    realm = [protectionSpace realm];
    host  = [protectionSpace host];
    if ( [protectionSpace isProxy] ) {
        if (realm != nil) {
            self.realmLabel.text = [NSString stringWithFormat:@"AUTHENTICATE FOR PROXY REALM '%@'.", realm];
        } else {
            assert(host != nil);
            self.realmLabel.text = [NSString stringWithFormat:@"AUTHENTICATE FOR PROXY '%@'.", host];
        }
    } else {
        if (realm != nil) {
            self.realmLabel.text = [NSString stringWithFormat:@"AUTHENTICATE FOR REALM '%@'.", realm];
        } else {
            assert(host != nil);
            self.realmLabel.text = [NSString stringWithFormat:@"AUTHENTICATE FOR HOST '%@'.", host];
        }
    }
    
    // Setup the user name and password fields from the proposed credential (if any).
    
    proposedUser     = nil;
    proposedPassword = nil;
    
    // Enable the following to test focus setup code.
    
    if (NO) {
        proposedUser     = @"test";
        proposedPassword = @"test";
    }
    
    proposedCredential = [self.challenge proposedCredential];
    if (proposedCredential != nil) {
        proposedUser     = [proposedCredential user];
        proposedPassword = [proposedCredential password];
    }
    
    if ( (proposedUser != nil) && ([proposedUser length] != 0) ) {
        self.userField.text = proposedUser;
    }
    if ( (proposedPassword != nil) && ([proposedPassword length] != 0) ) {
        self.passwordField.text = proposedPassword;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    assert(self.delegate != nil);           // c'mon folks!
    
    [super viewWillAppear:animated];
    
    // If there's already a user, put the focus on the password field.
    
    if ( [self.userField.text length] == 0 ) {
        [self.userField becomeFirstResponder];
    } else {
        [self.passwordField becomeFirstResponder];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if ( (self.delegate) != nil && [self.delegate respondsToSelector:@selector(authenticationViewDidDisappear:)] ) {
        [self.delegate authenticationViewDidDisappear:self];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.userField = nil;
    self.passwordField = nil;
    self.realmLabel = nil;
    self.passwordDispositionLabel = nil;
}

- (void)dealloc
{
    [self->_credential release];
    [self->_challenge release];

    [self->_userField release];
    [self->_passwordField release];
    [self->_realmLabel release];
    [self->_passwordDispositionLabel release];

    [super dealloc];
}

@end
