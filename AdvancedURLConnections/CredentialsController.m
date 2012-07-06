/*
    File:       CredentialsController.m

    Contains:   Manages the Credentials tab.

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

#import "CredentialsController.h"

#import "Credentials.h"

#import "CredentialImportController.h"

#import "PickListController.h"

#import "ServerTrustChallengeHandler.h"

@interface CredentialsController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, PickListControllerDelegate, CredentialImportControllerDelegate>

@property (nonatomic, copy,   readwrite) NSArray *              identities;
@property (nonatomic, copy,   readwrite) NSArray *              certificates;
@property (nonatomic, retain, readwrite) PickListController *   pickList;

@property (nonatomic, assign, readonly)  BOOL                   isReceiving;
@property (nonatomic, retain, readwrite) NSURLConnection *      connection;
@property (nonatomic, copy,   readwrite) NSString *             filePath;
@property (nonatomic, copy,   readwrite) NSHTTPURLResponse *    response;
@property (nonatomic, retain, readwrite) NSOutputStream *       fileStream;

@end

@implementation CredentialsController

// Section indices within the main table view.

enum {
    kSectionIndexIdentities = 0,
    kSectionIndexCertificates,
    kSectionIndexRefreshCredentials,
    kSectionIndexDumpCredentials,
    kSectionIndexResetCredentials,
    kSectionCount
};

#pragma mark * Credentials manglement

- (void)_resetURLCredentialsStore
    // Called as part of the reset operation done when the user taps 
    // Reset Credentials.  Resets any non-keychain credentials (that is, those 
    // in the NSURLCredentialStorage).
{
    NSURLCredentialStorage *    store;
    
    store = [NSURLCredentialStorage sharedCredentialStorage];
    assert(store != nil);
    
    for (NSURLProtectionSpace * protectionSpace in [store allCredentials]) {
        NSDictionary *  userToCredentialMap;
        
        userToCredentialMap = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protectionSpace];
        assert(userToCredentialMap != nil);
        for (NSString * user in userToCredentialMap) {
            NSURLCredential *   credential;
            
            credential = [userToCredentialMap objectForKey:user];
            assert(credential != nil);
            
            [store removeCredential:credential forProtectionSpace:protectionSpace];
        }
    }
}

- (void)_resetCredentials
    // Called when the user taps Reset Credentials.  Resets the keychain credentials 
    // and the non-keychain credentials.
{
    // Nix the keychain credentials.
    
    [[Credentials sharedCredentials] resetCredentials];
    
    // Nix the non-keychain credentials.
    
    [self _resetURLCredentialsStore];
    
    // Nix the per-site allowed certificates.
    
    [ServerTrustChallengeHandler resetTrustedCertificates];
}

- (void)_dumpCredentials
    // Called when the user taps Dump Credentials.  Prints the keychain credentials 
    // followed by the non-keychain credentials.
{
    [[Credentials sharedCredentials] dumpCredentials];
    
    fprintf(stderr, "URL credential storage:\n");
    for (NSURLProtectionSpace * protectionSpace in [[NSURLCredentialStorage sharedCredentialStorage] allCredentials]) {
        NSDictionary *  userToCredentialMap;
        
        fprintf(stderr, "  %s\n", [[NSString stringWithFormat:@"%@ @ %@", [protectionSpace realm], [protectionSpace host]] UTF8String]);
        userToCredentialMap = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protectionSpace];
        assert(userToCredentialMap != nil);
        for (NSString * user in userToCredentialMap) {
            NSURLCredential *   credential;
            
            credential = [userToCredentialMap objectForKey:user];
            assert(credential != nil);
            fprintf(stderr, "    %s\n", [[NSString stringWithFormat:@"%@", [credential user]] UTF8String]);
        }
    }
}

- (void)_refreshCredentials
    // Called when the user taps Refresh Credentials.  Tells our Credentials 
    // module to refresh its view of the keychain (which may trigger a KVO 
    // notification which reloads sections of our table).  This should never be 
    // necessary (the only person modifying our keychain is us, and we already 
    // trigger a refresh after any changes), but it was handy during debugging.
{
    [[Credentials sharedCredentials] refresh];
}

#pragma mark * Table view callbacks

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    #pragma unused(tv)
    assert(tv != nil);
    return kSectionCount;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tv)
    #pragma unused(section)
    NSInteger   result;

    assert(tv != nil);
    assert(section < kSectionCount);
    
    switch (section) {
        case kSectionIndexIdentities: {
            result = self.identities.count;
            if (result == 0) {
                result = 1;
            }
        } break;
        case kSectionIndexCertificates: {
            result = self.certificates.count;
            if (result == 0) {
                result = 1;
            }
        } break;
        case kSectionIndexRefreshCredentials:
        case kSectionIndexDumpCredentials:
        case kSectionIndexResetCredentials: {
            result = 1;
        } break;
        default: {
            assert(NO);
            result = 0;
        } break;
    }
    return result;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
    #pragma unused(tv)
    NSString *  result;
    
    assert(tv == self.tableView);
    assert(section < kSectionCount);

    switch (section) {
        case kSectionIndexIdentities: {
            result = @"Identities";
        } break;
        case kSectionIndexCertificates: {
            result = @"Certificates";
        } break;
        default:
            assert(NO);
            // fall through
        case kSectionIndexRefreshCredentials:
        case kSectionIndexDumpCredentials:
        case kSectionIndexResetCredentials: {
            result = nil;
        } break;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)
    OSStatus            err;
    UITableViewCell *   cell;
    NSUInteger          row;
    
    assert(tv == self.tableView);
    assert(indexPath != nil);
    assert(indexPath.section < kSectionCount);

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
    }
    assert(cell != nil);
    
    // Reset the cell to its default style.
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    cell.accessoryType  = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    // Do various things depending on the section and row.
    
    row = indexPath.row;
    switch (indexPath.section) {
        case kSectionIndexIdentities: {
            // In the Identities section, display a single cell labelled "none" 
            // if there are no identities.  Othewise display a list of identities 
            // named by the subject summary from the certificate associated with 
            // the identity.
        
            if (self.identities.count == 0) {
                assert(row == 0);
                cell.textLabel.text = @"none";
                cell.textLabel.font = [UIFont italicSystemFontOfSize:[UIFont labelFontSize]];
            } else {
                SecIdentityRef      identity;
                SecCertificateRef   identityCertificate;
                CFStringRef         identitySubject;
                
                identity = (SecIdentityRef) [self.identities objectAtIndex:row];
                assert(CFGetTypeID(identity) == SecIdentityGetTypeID());
                
                err = SecIdentityCopyCertificate(identity, &identityCertificate);
                assert(err == noErr);
                assert(identityCertificate != NULL);

                identitySubject = SecCertificateCopySubjectSummary(identityCertificate);
                assert(identitySubject != NULL);
                
                cell.textLabel.text = (NSString *) identitySubject;
                
                CFRelease(identitySubject);
                CFRelease(identityCertificate);
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } break;
        case kSectionIndexCertificates: {
            // In the Certificates section, display a single cell labelled "none" 
            // if there are no identities.  Othewise display a list of certificates 
            // named by their subject summary.

            if (self.certificates.count == 0) {
                assert(row == 0);
                cell.textLabel.text = @"none";
                cell.textLabel.font = [UIFont italicSystemFontOfSize:[UIFont labelFontSize]];
            } else {
                SecCertificateRef   certificate;
                CFStringRef         subject;
                
                certificate = (SecCertificateRef) [self.certificates objectAtIndex:row];
                assert(CFGetTypeID(certificate) == SecCertificateGetTypeID());
                
                subject = SecCertificateCopySubjectSummary(certificate);
                assert(subject != NULL);
                
                cell.textLabel.text = (NSString *) subject;
                
                CFRelease(subject);
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } break;
        case kSectionIndexRefreshCredentials: {
            assert(row == 0);
            cell.textLabel.text = @"Refresh Credentials";
        } break;
        case kSectionIndexDumpCredentials: {
            assert(row == 0);
            cell.textLabel.text = @"Dump Credentials";
        } break;
        case kSectionIndexResetCredentials: {
            assert(row == 0);
            cell.textLabel.text = @"Reset Credentials";
        } break;
        default: {
            assert(NO);
        } break;
    }
    
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    NSIndexPath *   result;
    
    assert(tv == self.tableView);
    assert(indexPath != nil);
    assert(indexPath.section < kSectionCount);

    // Prevent the user from selecting rows in the Identities and Certificates 
    // sections.
    
    result = nil;
    switch (indexPath.section) {
        case kSectionIndexIdentities:
        case kSectionIndexCertificates: {
            assert(result == nil);
        } break;
        case kSectionIndexRefreshCredentials: 
        case kSectionIndexDumpCredentials: 
        case kSectionIndexResetCredentials: {
            assert(indexPath.row == 0);
            result = indexPath;
        } break;
        default: {
            assert(NO);
        } break;
    }
    return result;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    NSUInteger          section;
    NSUInteger          row;
    UITableViewCell *   cellToClear;
    UITableViewCell *   cellToSet;
    
    assert(tv == self.tableView);
    assert(indexPath != nil);
    assert(indexPath.section < kSectionCount);

    cellToClear = nil;
    cellToSet   = nil;

    // Handle taps on Refresh Credentials, Dump Credentials, and Reset Credentials.
    
    section = indexPath.section;
    row     = indexPath.row;
    switch (section) {
        case kSectionIndexIdentities:
        case kSectionIndexCertificates: {
            assert(row == 0);
            assert(NO);
        } break;
        case kSectionIndexRefreshCredentials: {
            assert(row == 0);
            [self _refreshCredentials];
        } break;
        case kSectionIndexDumpCredentials: {
            assert(row == 0);
            [self _dumpCredentials];
        } break;
        case kSectionIndexResetCredentials: {
            assert(row == 0);
            [self _resetCredentials];
        } break;
        default: {
            assert(NO);
        } break;
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@synthesize identities   = _identities;
@synthesize certificates = _certificates;

- (void)_reloadIdentities
    // Reload our list of identities from the Credentials class.
{
    self.identities = [Credentials sharedCredentials].identities;
    assert(self.identities != nil);
    if (self.isViewLoaded) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionIndexIdentities]  withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)_reloadCertificates
    // Reload our list of certificates from the Credentials class.
{
    self.certificates = [Credentials sharedCredentials].certificates;
    assert(self.certificates != nil);
    if (self.isViewLoaded) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionIndexCertificates] withRowAnimation:UITableViewRowAnimationNone];
    }
}

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
    [self _updateStatus:@"Receiving"];
    self.getOrCancelButton.title = @"Cancel";
    [UIView beginAnimations:@"Mask" context:NULL];
    self.maskView.alpha = 0.75f;
    [UIView commitAnimations];
    [self.activityIndicator startAnimating];
    [[AppDelegate sharedAppDelegate] didStartNetworking];
}

- (void)_receiveDidStopWithStatus:(NSString *)statusString
{
    if (statusString == nil) {
        NSString *                      fileMIMEType;
        CredentialImportController *    vc;
        NSData *                        fileData;

        // If the download succeeded, try to import the credential.
        
        assert(self.filePath != nil);
        assert(self.response != nil);
        
        fileMIMEType = [[self.response MIMEType] lowercaseString];
        assert(fileMIMEType != nil);
        assert( [[CredentialImportController supportedMIMETypes] containsObject:fileMIMEType] );
        
        fileData = [NSData dataWithContentsOfFile:self.filePath];
        assert(fileData != nil);
        
        vc = [[[CredentialImportController alloc] initWithCredentialData:fileData type:fileMIMEType] autorelease];
        assert(vc != nil);
        
        vc.delegate = self;
        vc.origin   = self.response.URL;
        
        [self presentModalViewController:vc animated:YES];
        
        // continues in -credentialImport:didImportWithStatus:

        statusString = @"Importing credential";
    } else {
        UIAlertView *   alert;

        // If the download failed, tell the user via an alert view.  This is a 
        // less than ideal UI, but the technique used in the Get tab is not 
        // appropriate here (there's nowhere to put the final status in the 
        // table view).
        
        alert = [[[UIAlertView alloc] initWithTitle:@"Get Failed" message:statusString delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
        assert(alert != nil);
        
        [alert show];
    }
    [self _updateStatus:statusString];
    self.getOrCancelButton.title = @"Get";
    [UIView beginAnimations:@"Unmask" context:NULL];
    self.maskView.alpha = 0.0f;
    [UIView commitAnimations];
    [self.activityIndicator stopAnimating];
    [[AppDelegate sharedAppDelegate] didStopNetworking];
}

- (void)credentialImport:(CredentialImportController *)credentialImport didImportWithStatus:(CredentialImportStatus)status
    // A credential import controller delegate callback, called when the user has 
    // completed the import.  The status value tells us whether it was imported 
    // successfully, or not, or cancelled.  In the failure case we display an 
    // alert telling the user.
{
    #pragma unused(credentialImport)
    assert(credentialImport != NULL);
    
    [self dismissModalViewControllerAnimated:YES];
    
    switch (status) {
        case kCredentialImportStatusCancelled: {
            [self _updateStatus:@"Import cancelled"];
        } break;
        case kCredentialImportStatusFailed: {
            UIAlertView *   alert;
            
            [self _updateStatus:@"Import failed"];
            
            alert = [[[UIAlertView alloc] initWithTitle:@"Import Failed" message:nil delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
            assert(alert != nil);
            
            [alert show];
        } break;
        case kCredentialImportStatusSucceeded: {
            [self _updateStatus:@"Import succeeded"];
            [[Credentials sharedCredentials] refresh];
        } break;
    }
}

#pragma mark * Core transfer code

// This is the code that actually does the networking.

@synthesize connection        = _connection;
@synthesize filePath          = _filePath;
@synthesize response          = _response;
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
    assert(self.fileStream == nil);         // ditto
    assert(self.filePath == nil);           // ditto
    assert(self.response == nil);           // ditto

    // First get and check the URL.
    
    url = [[AppDelegate sharedAppDelegate] smartURLForString:self.urlText.text];
    success = (url != nil);

    // If the URL is bogus, let the user know.  Otherwise kick off the connection. 
    
    if ( ! success) {
        // +++ The invalid URL text never shows up in the UI.  This is one of the 
        // problems that fall out the UI design problems in this module.  I need a 
        // better solution, but I've yet to find one.
        [self _updateStatus:self.statusLabel.text = @"Invalid URL"];
    } else {

        // Open a stream for the file we're going to receive into.

        self.filePath = [[AppDelegate sharedAppDelegate] pathForTemporaryFileWithPrefix:@"GetCredential"];
        assert(self.filePath != nil);
        
        self.fileStream = [NSOutputStream outputStreamToFileAtPath:self.filePath append:NO];
        assert(self.fileStream != nil);
        
        [self.fileStream open];

        // Open a connection for the URL.

        request = [NSURLRequest requestWithURL:url];
        assert(request != nil);
        
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
        assert(self.connection != nil);

        // Tell the UI we're receiving.
        
        [self _receiveDidStart];
    }
}

- (void)_stopReceiveWithStatus:(NSString *)statusString
    // Shuts down the connection and displays the result (statusString == nil) 
    // or the error status (otherwise).
{
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
    self.response = nil;
}

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
    // A delegate method called by the NSURLConnection when the request/response 
    // exchange is complete.  We look at the response to check that the HTTP 
    // status code is 2xx and that the Content-Type is acceptable.  If these checks 
    // fail, we give up on the transfer.
{
    #pragma unused(conn)

    assert(conn == self.connection);

    NSLog(@"didReceiveResponse");
        
    self.response = (NSHTTPURLResponse *) response;
    assert( [self.response isKindOfClass:[NSHTTPURLResponse class]] );
    
    if ((self.response.statusCode / 100) != 2) {
        [self _stopReceiveWithStatus:[NSString stringWithFormat:@"HTTP error %zd", (ssize_t) self.response.statusCode]];
    } else {
        NSString *  fileMIMEType;
        
        fileMIMEType = [[self.response MIMEType] lowercaseString];
        if (fileMIMEType == nil) {
            [self _stopReceiveWithStatus:@"No Content-Type!"];
        } else if ( ! [[CredentialImportController supportedMIMETypes] containsObject:fileMIMEType] ) {
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

#pragma mark * Action code

@synthesize pickList = _pickList;

- (void)textFieldDidBeginEditing:(UITextField *)textField
    // A delegate method called by the URL text field when the user start editing 
    // the field.  We respond by bringing up our pick list.
{
    #pragma unused(textField)
    
    assert(textField == self.urlText);

    assert(self.pickList == nil);
    self.pickList = [[[PickListController alloc] initWithPickListNamed:@"CredentialsControllerPickList" bundle:nil] autorelease];
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
    oldValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"CredentialsURLText"];

    // Save the URL text if it's changed.
    
    assert(newValue != nil);        // what is UITextField thinking!?!
    assert(oldValue != nil);        // because we registered a default
    
    if ( ! [newValue isEqual:oldValue] ) {
        [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:@"CredentialsURLText"];
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
@synthesize getOrCancelButton = _getOrCancelButton;
@synthesize toolbar           = _toolbar;
@synthesize maskView          = _maskView;
@synthesize statusLabel       = _statusLabel;
@synthesize activityIndicator = _activityIndicator;
@synthesize tableView         = _tableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    assert(self.urlText != nil);
    assert(self.urlText.delegate == self);
    assert(self.getOrCancelButton != nil);
    assert(self.toolbar != nil);
    assert(self.maskView != nil);
    assert(self.statusLabel != nil);
    assert(self.activityIndicator != nil);
    assert(self.tableView != nil);
    assert(self.tableView.delegate == self);

    self.getOrCancelButton.possibleTitles = [NSSet setWithObjects:@"Get", @"Cancel", nil];

    self.urlText.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"CredentialsURLText"];

    self.activityIndicator.hidden = YES;
    [self _updateStatus:@""];
    self.maskView.alpha = 0.0f;
    
    // Observe the identities and certificates properties of the Credentials so that 
    // we get notified when things change.  Note the user of NSKeyValueObservingOptionInitial, 
    // which causes us to to be called immediately; it's this that populates our table 
    // view sections initially.
    
    [[Credentials sharedCredentials] addObserver:self forKeyPath:@"identities"   options:NSKeyValueObservingOptionInitial context:&self->_identities];
    [[Credentials sharedCredentials] addObserver:self forKeyPath:@"certificates" options:NSKeyValueObservingOptionInitial context:&self->_certificates];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.urlText = nil;
    self.getOrCancelButton = nil;
    self.toolbar = nil;
    self.maskView = nil;
    self.statusLabel = nil;
    self.activityIndicator = nil;
    self.tableView = nil;

    // Undo our KVO notification.

    [[Credentials sharedCredentials] removeObserver:self forKeyPath:@"identities"];
    [[Credentials sharedCredentials] removeObserver:self forKeyPath:@"certificates"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
    // A KVO callback called when the identities or certificates change in the Credentials 
    // module.  We turn around and reload the corresponding section of the table.
{
    if (context == &self->_identities) {
        assert(object == [Credentials sharedCredentials]);
        assert([keyPath isEqual:@"identities"]);
        [self _reloadIdentities];
    } else if (context == &self->_certificates) {
        assert(object == [Credentials sharedCredentials]);
        assert([keyPath isEqual:@"certificates"]);
        [self _reloadCertificates];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)viewDidAppear:(BOOL)animated
    // Because we're not a UITableViewController subclass, we have to do some 
    // UITableViewController things, like flash the scroll bars on -viewDidAppear:.
{
    [super viewDidAppear:animated];
    [self.tableView flashScrollIndicators];
}

- (void)dealloc
{
    [self _stopReceiveWithStatus:@"Stopped"];

    [self->_identities   release];
    [self->_certificates release];
    assert(self->_pickList == nil);

    [self->_urlText release];
    [self->_getOrCancelButton release];
    [self->_toolbar release];
    [self->_maskView release];
    [self->_statusLabel release];
    [self->_activityIndicator release];
    [self->_tableView release];

    [super dealloc];
}

@end
