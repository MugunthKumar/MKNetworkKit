/*
    File:       AdvancedGetController.m

    Contains:   Manages the Get tab.

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

// IMPORTANT: This code is very similar to the code from the SimpleURLConnections 
// sample except that it a) handle authentication challenges, and b) supports 
// a pick list (to make testing easier).  If you want a more gentle introduction 
// to NSURLConnection, you should start with the SimpleURLConnections first.

#import "AdvancedGetController.h"

#import "ChallengeHandler.h"
#import "PickListController.h"
#import "DebugOptions.h"
#import "AppDelegate.h"

#pragma mark * GetController

@interface AdvancedGetController () <UITextFieldDelegate, PickListControllerDelegate, ChallengeHandlerDelegate>

// Properties that don't need to be seen by the outside world.

@property (nonatomic, retain, readwrite) PickListController *   pickList;

@property (nonatomic, assign, readonly)  BOOL                   isReceiving;
@property (nonatomic, retain, readwrite) NSURLConnection *      connection;
@property (nonatomic, retain, readwrite) ChallengeHandler *     currentChallenge;
@property (nonatomic, retain, readwrite) NSTimer *              earlyTimeoutTimer;
@property (nonatomic, copy,   readwrite) NSString *             filePath;
@property (nonatomic, retain, readwrite) NSOutputStream *       fileStream;

@end

@implementation AdvancedGetController

#pragma mark * Status management

// These methods are used by the core transfer code to update the UI.

- (void)_updateStatus:(NSString *)statusString
{
    assert(statusString != nil);
    self.statusLabel.text = statusString;
    NSLog(@"status: %@", statusString);
}

- (void)_receiveDidStart
{
    // Clear the current image so that we get a nice visual cue if the receive fails.
    self.imageView.image = nil;
    [self _updateStatus:@"Receiving"];
    self.getOrCancelButton.title = @"Cancel";
    [self.activityIndicator startAnimating];
    [[AppDelegate sharedAppDelegate] didStartNetworking];
}

- (void)_receiveDidStopWithStatus:(NSString *)statusString
{
    if (statusString == nil) {
        assert(self.filePath != nil);
        
        self.imageView.image = [UIImage imageWithContentsOfFile:self.filePath];
        statusString = @"Get succeeded";
    }
    [self _updateStatus:statusString];
    self.getOrCancelButton.title = @"Get";
    [self.activityIndicator stopAnimating];
    [[AppDelegate sharedAppDelegate] didStopNetworking];
}

#pragma mark * Core transfer code

// This is the code that actually does the networking.

@synthesize connection        = _connection;
@synthesize currentChallenge  = _currentChallenge;
@synthesize earlyTimeoutTimer = _earlyTimeoutTimer;
@synthesize filePath          = _filePath;
@synthesize fileStream        = _fileStream;

- (BOOL)isReceiving
{
    return (self.connection != nil);
}

- (void)_startReceive
    // Starts a connection to download the current URL.
{
    BOOL                success;
    NSURL *             url;
    NSURLRequest *      request;
    
    assert(self.connection == nil);         // don't tap receive twice in a row!
    assert(self.currentChallenge == nil);   // ditto
    assert(self.earlyTimeoutTimer == nil);  // ditto
    assert(self.filePath == nil);           // ditto
    assert(self.fileStream == nil);         // ditto

    // First get and check the URL.
    
    url = [[AppDelegate sharedAppDelegate] smartURLForString:self.urlText.text];
    success = (url != nil);

    // If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
        [self _updateStatus:@"Invalid URL"];
    } else {

        // Open a stream for the file we're going to receive into.

        self.filePath = [[AppDelegate sharedAppDelegate] pathForTemporaryFileWithPrefix:@"Get"];
        assert(self.filePath != nil);
        
        self.fileStream = [NSOutputStream outputStreamToFileAtPath:self.filePath append:NO];
        assert(self.fileStream != nil);
        
        [self.fileStream open];

        // Open a connection for the URL.

        request = [NSURLRequest requestWithURL:url];
        assert(request != nil);
        
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
        assert(self.connection != nil);

        // If we've been told to use an early timeout for debugging purposes, 
        // set that up now.
        
        if ([DebugOptions sharedDebugOptions].earlyTimeout) {
            self.earlyTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(_earlyTimeout:) userInfo:nil repeats:NO];
            assert(self.earlyTimeoutTimer != nil);
        }

        // Tell the UI we're receiving.
        
        [self _receiveDidStart];
    }
}

- (void)_stopReceiveWithStatus:(NSString *)statusString
    // Shuts down the connection and displays the result (statusString == nil) 
    // or the error status (otherwise).
{
    if (self.earlyTimeoutTimer != nil) {
        [self.earlyTimeoutTimer invalidate];
        self.earlyTimeoutTimer = nil;
    }
    if (self.currentChallenge != nil) {
        [self.currentChallenge stop];
        self.currentChallenge = nil;
    }
    if (self.connection != nil) {
        [self.connection cancel];
        self.connection = nil;
    }
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
    [self _receiveDidStopWithStatus:statusString];
    self.filePath = nil;
}

- (void)_earlyTimeout:(NSTimer *)timer
    // Called by a timer (if the earlyTimout debugging option is enabled) to 
    // test the code that cancels authentication challenges.  This flushed out a 
    // scary number of bugs (-:
{
    #pragma unused(timer)
    assert(timer != nil);
    assert(timer == self.earlyTimeoutTimer);
    [self _stopReceiveWithStatus:@"Early Timeout"];
}

- (BOOL)connection:(NSURLConnection *)conn canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
    // A delegate method called by the NSURLConnection when something happens with the 
    // connection security-wise.  We defer all of the logic for how to handle this to 
    // the ChallengeHandler module (and it's very custom subclasses).
{
    #pragma unused(conn)
    BOOL    result;

    assert(conn == self.connection);
    assert(protectionSpace != nil);
        
    result = [ChallengeHandler supportsProtectionSpace:protectionSpace];
    NSLog(@"canAuthenticateAgainstProtectionSpace %@ -> %d", [protectionSpace authenticationMethod], result);
    return result;
}

- (void)connection:(NSURLConnection *)conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
    // A delegate method called by the NSURLConnection when you accept a specific 
    // authentication challenge by returning YES from -connection:canAuthenticateAgainstProtectionSpace:. 
    // Again, most of the logic has been shuffled off to the ChallengeHandler module; the only 
    // policy decision we make here is that, if the challenge handle doesn't get it right in 5 tries, 
    // we bail out.
{
    #pragma unused(conn)
    assert(conn == self.connection);
    assert(challenge != nil);

    NSLog(@"didReceiveAuthenticationChallenge %@ %zd", [[challenge protectionSpace] authenticationMethod], (ssize_t) [challenge previousFailureCount]);
    
    assert(self.currentChallenge == nil);
    if ([challenge previousFailureCount] < 5) {
        self.currentChallenge = [ChallengeHandler handlerForChallenge:challenge parentViewController:self];
        if (self.currentChallenge == nil) {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        } else {
            self.currentChallenge.delegate = self;
            [self.currentChallenge start];
        }
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

// Somewhat confusingly the -connection:didCancelAuthenticationChallenge: isn't meaningful in the 
// context of an NSURLConnection, so we just don't implement that method.

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
    // A delegate method called by the NSURLConnection when the request/response 
    // exchange is complete.  We look at the response to check that the HTTP 
    // status code is 2xx and that the Content-Type is acceptable.  If these checks 
    // fail, we give up on the transfer.
{
    #pragma unused(conn)
    static NSSet *      sSupportedImageTypes;
    NSHTTPURLResponse * httpResponse;

    assert(conn == self.connection);

    NSLog(@"didReceiveResponse");
    
    if (sSupportedImageTypes == nil) {
        sSupportedImageTypes = [[NSSet alloc] initWithObjects:@"image/jpeg", @"image/png", @"image/gif", nil];
        assert(sSupportedImageTypes != nil);
    }
    
    httpResponse = (NSHTTPURLResponse *) response;
    assert( [httpResponse isKindOfClass:[NSHTTPURLResponse class]] );
    
    if ((httpResponse.statusCode / 100) != 2) {
        [self _stopReceiveWithStatus:[NSString stringWithFormat:@"HTTP error %zd", (ssize_t) httpResponse.statusCode]];
    } else {
        NSString *  fileMIMEType;
        
        fileMIMEType = [[httpResponse MIMEType] lowercaseString];
        if (fileMIMEType == nil) {
            [self _stopReceiveWithStatus:@"No Content-Type!"];
        } else if ( ! [sSupportedImageTypes containsObject:fileMIMEType] ) {
            [self _stopReceiveWithStatus:[NSString stringWithFormat:@"Unsupported Content-Type (%@)", fileMIMEType]];
        } else {
            [self _updateStatus:@"Response OK."];
        }
    }    
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
    // A delegate method called by the NSURLConnection as data arrives.  We just 
    // write the data to the file.
{
    #pragma unused(conn)
    NSInteger       dataLength;
    const uint8_t * dataBytes;
    NSInteger       bytesWritten;
    NSInteger       bytesWrittenSoFar;

    assert(conn == self.connection);
    
    dataLength = [data length];
    dataBytes  = [data bytes];

    bytesWrittenSoFar = 0;
    do {
        bytesWritten = [self.fileStream write:&dataBytes[bytesWrittenSoFar] maxLength:dataLength - bytesWrittenSoFar];
        assert(bytesWritten != 0);
        if (bytesWritten == -1) {
            [self _stopReceiveWithStatus:@"File write error"];
            break;
        } else {
            bytesWrittenSoFar += bytesWritten;
        }
    } while (bytesWrittenSoFar != dataLength);
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
    // A delegate method called by the NSURLConnection if the connection fails. 
    // We shut down the connection and display the failure.  Production quality code 
    // would either display or log the actual error.
{
    #pragma unused(conn)
    #pragma unused(error)
    assert(conn == self.connection);

    NSLog(@"didFailWithError %@", error);
    
    [self _stopReceiveWithStatus:@"Connection failed"];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
    // A delegate method called by the NSURLConnection when the connection has been 
    // done successfully.  We shut down the connection with a nil status, which 
    // causes the image to be displayed.
{
    #pragma unused(conn)
    assert(conn == self.connection);

    NSLog(@"connectionDidFinishLoading");
    
    [self _stopReceiveWithStatus:nil];
}

#pragma mark * Authentication challenge UI

- (void)challengeHandlerDidFinish:(ChallengeHandler *)handler
    // Called by the authentication challenge handler once the challenge is 
    // resolved.  We twiddle our internal state and then call the -resolve method 
    // to apply the challenge results to the NSURLAuthenticationChallenge.
{
    #pragma unused(handler)
    ChallengeHandler *  challenge;
    
    assert(handler == self.currentChallenge);

    // We want to nil out currentChallenge because we've really done with this 
    // challenge now and, for example, if the next operation kicks up a new 
    // challenge, we want to make sure that currentChallenge is ready to receive 
    // it.
    // 
    // We want the challenge to hang around after we've nilled out currentChallenge, 
    // so retain/autorelease it.
    
    challenge = [[self.currentChallenge retain] autorelease];
    self.currentChallenge = nil;

    // If the credential isn't present, this will trigger a -connection:didFailWithError: 
    // callback.
    
    NSLog(@"resolve %@ -> %@", [[challenge.challenge protectionSpace] authenticationMethod], challenge.credential);
    [challenge resolve];
}

#pragma mark * UI Actions

@synthesize pickList = _pickList;

- (void)textFieldDidBeginEditing:(UITextField *)textField
    // A delegate method called by the URL text field when the user start editing 
    // the field.  We respond by bringing up our pick list.
{
    #pragma unused(textField)
    
    assert(textField == self.urlText);

    assert(self.pickList == nil);
    self.pickList = [[[PickListController alloc] initWithPickListNamed:@"AdvancedGetControllerPickList" bundle:nil] autorelease];
    assert(self.pickList != nil);
    
    self.pickList.delegate = self;

    [self.pickList attachBelowView:self.toolbar];
}

- (void)pickList:(PickListController *)controller didPick:(NSString *)picked
    // A delegate method called by our pick list controller when the user picks 
    // an entry.  We stash the entry into our URL text field (it will get saved 
    // by -textFieldDidEndEditing:, below), dismiss the keyboard (which tears 
    // down the pick list, again in -textFieldDidEndEditing:), and then 
    // start the transfer.
{
    #pragma unused(controller)

    assert(controller == self.pickList);
    assert(picked != nil);

    self.urlText.text = picked;
    [self.urlText resignFirstResponder];
    if (self.isReceiving) {
        [self _stopReceiveWithStatus:@"Cancelled"];
    }
    [self _startReceive];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
    // A delegate method called by the URL text field when the user taps the Return 
    // key.  We just dismiss the keyboard (which has the side effect of tearing 
    // down the pick list per the code in -textFieldDidEndEditing:).
{
    #pragma unused(textField)
    assert(textField == self.urlText);

    [self.urlText resignFirstResponder];
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
    // A delegate method called by the URL text field when the editing is complete. 
    // We dismiss the pick list and save the current value of the field in our settings.
{
    #pragma unused(textField)
    NSString *  newValue;
    NSString *  oldValue;

    assert(textField == self.urlText);

    assert(self.pickList != nil);
    [self.pickList detach];
    self.pickList = nil;

    newValue = self.urlText.text;
    oldValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"GetURLText"];

    // Save the URL text if it's changed.
    
    assert(newValue != nil);        // what is UITextField thinking!?!
    assert(oldValue != nil);        // because we registered a default
    
    if ( ! [newValue isEqual:oldValue] ) {
        [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:@"GetURLText"];
    }
}

- (IBAction)getOrCancelAction:(id)sender
    // Called when the user taps the Get button in the toolbar (which is a Cancel 
    // button if we're transferring).
{
    #pragma unused(sender)
    [self.urlText resignFirstResponder];
    if (self.isReceiving) {
        [self _stopReceiveWithStatus:@"Cancelled"];
    } else {
        [self _startReceive];
    }
}

#pragma mark * View controller boilerplate

@synthesize urlText           = _urlText;
@synthesize imageView         = _imageView;
@synthesize statusLabel       = _statusLabel;
@synthesize activityIndicator = _activityIndicator;
@synthesize getOrCancelButton = _getOrCancelButton;
@synthesize toolbar           = _toolbar;

- (void)viewDidLoad
{    
    [super viewDidLoad];

    assert(self.urlText != nil);
    assert(self.urlText.delegate == self);
    assert(self.imageView != nil);
    assert(self.statusLabel != nil);
    assert(self.activityIndicator != nil);
    assert(self.getOrCancelButton != nil);
    assert(self.toolbar != nil);
    
    self.getOrCancelButton.possibleTitles = [NSSet setWithObjects:@"Get", @"Cancel", nil];

    self.urlText.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"GetURLText"];
    
    self.activityIndicator.hidden = YES;
    [self _updateStatus:@""];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.urlText = nil;
    self.imageView = nil;
    self.statusLabel = nil;
    self.activityIndicator = nil;
    self.getOrCancelButton = nil;
    self.toolbar = nil;
}

- (void)dealloc
{
    [self _stopReceiveWithStatus:@"Stopped"];

    [self->_urlText release];
    [self->_imageView release];
    [self->_statusLabel release];
    [self->_activityIndicator release];
    [self->_getOrCancelButton release];
    [self->_toolbar release];

    [super dealloc];
}

@end
