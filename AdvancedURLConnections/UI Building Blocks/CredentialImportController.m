/*
    File:       CredentialImportController.m

    Contains:   View to import a credential.

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

#import "CredentialImportController.h"

@interface CredentialImportController () <UITextFieldDelegate>

@property (nonatomic, assign, readonly) BOOL isPKCS12;

@end

@implementation CredentialImportController

+ (NSSet *)supportedMIMETypes
{
    static NSSet *  sSupportedCredentialTypes;

    if (sSupportedCredentialTypes == nil) {
        sSupportedCredentialTypes = [[NSSet alloc] initWithObjects:@"application/x-pkcs12", @"application/x-x509-ca-cert", @"application/pkix-cert", nil];
        assert(sSupportedCredentialTypes != nil);
    }
    return sSupportedCredentialTypes;
}

- (id)initWithCredentialData:(NSData *)data type:(NSString *)type
{
    assert(data != nil);
    assert(type != nil);
    assert([[[self class] supportedMIMETypes] containsObject:type]);
    
    self = [super initWithNibName:@"CredentialImportController" bundle:[NSBundle bundleForClass:[self class]]];
    if (self != nil) {
        self->_data = [data copy];
        self->_type = [[type lowercaseString] copy];
    }
    return self;
}

@synthesize data     = _data;
@synthesize type     = _type;
@synthesize origin   = _origin;
@synthesize delegate = _delegate;

- (BOOL)isPKCS12
{
    return [self.type isEqual:@"application/x-pkcs12"];
}

#pragma mark * Text field delegate callbacks

// The passwordIncorrectLabel tells the user that their password was incorrect 
// (obviously this is only used for PKCS#12).  We show the label when the user 
// tries to import the PKCS#12 and that fails with an error.  We hide the label 
// when the user changes (or clears) the text in the password field.

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    #pragma unused(textField)
    assert(textField == self.passwordField);
    self.passwordIncorrectLabel.hidden = YES;
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    #pragma unused(textField)
    #pragma unused(range)
    #pragma unused(string)
    assert(textField == self.passwordField);
    self.passwordIncorrectLabel.hidden = YES;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    #pragma unused(textField)
    assert(textField == self.passwordField);
    
    // We don't check for the password being non-empty because it seems that a 
    // PKCS#12 with an empty password is legal.
    
    [self importAction:self];
    return NO;
}

#pragma mark * Action code

- (CredentialImportStatus)_importPKCS12
    // Attempts to import the identities in a PKCS#12 data blob.
{
    OSStatus                err;
    CredentialImportStatus  status;
    CFArrayRef              importedItems;

    status = kCredentialImportStatusFailed;

    importedItems = NULL;
    
    err = SecPKCS12Import( 
        (CFDataRef) self.data, 
        (CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
            self.passwordField.text,        kSecImportExportPassphrase, 
            nil
        ],
        &importedItems
    );
    if (err == noErr) {
        // +++ If there are multiple identities in the PKCS#12, and adding a non-first 
        // one fails, we end up with partial results.  Right now that's not an issue 
        // in practice, but I might want to revisit this.
        
        for (NSDictionary * itemDict in (id) importedItems) {
            SecIdentityRef  identity;
            
            assert([itemDict isKindOfClass:[NSDictionary class]]);

            identity = (SecIdentityRef) [itemDict objectForKey:(NSString *) kSecImportItemIdentity];
            assert(identity != NULL);
            assert( CFGetTypeID(identity) == SecIdentityGetTypeID() );
            
            err = SecItemAdd(
                (CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                    (id) identity,              kSecValueRef,
                    nil
                ], 
                NULL
            );
            if (err == errSecDuplicateItem) {
                err = noErr;
            }
            if (err != noErr) {
                break;
            }
        }
        if (err == noErr) {
            status = kCredentialImportStatusSucceeded;
        }
    } else if (err == errSecAuthFailed) {
        self.passwordIncorrectLabel.hidden = NO;
        status = kCredentialImportStatusCancelled;
    }
    
    if (importedItems != NULL) {
        CFRelease(importedItems);
    }
    return status;
}

- (CredentialImportStatus)_importCertificate
    // Attempts to import the data as a certificate.
{
    OSStatus                err;
    CredentialImportStatus  status;
    SecCertificateRef       cert;

    status = kCredentialImportStatusFailed;

    cert = SecCertificateCreateWithData(NULL, (CFDataRef) self.data);
    if (cert != NULL) {
        err = SecItemAdd(
            (CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                (id) kSecClassCertificate,  kSecClass, 
                (id) cert,                  kSecValueRef,
                nil
            ], 
            NULL
        );
        if ( (err == errSecSuccess) || (err == errSecDuplicateItem) ) {
            status = kCredentialImportStatusSucceeded;
        }
    }
    return status;
}

- (IBAction)importAction:(id)sender
    // Called when the user taps on the Import button.
{
    #pragma unused(sender)
    CredentialImportStatus  status;
        
    if (self.isPKCS12) {
        status = [self _importPKCS12];
    } else {
        status = [self _importCertificate];
    }
    
    // We use kCredentialImportStatusCancelled as a special token (in this context 
    // only) to indicate that the user should retry their password.
    
    if ( (self.delegate != nil) && (status != kCredentialImportStatusCancelled) ) {
        [self.delegate credentialImport:self didImportWithStatus:status];
    }
}

- (IBAction)cancelAction:(id)sender
    // Called when the user taps on the Cancel button.
{
    #pragma unused(sender)
    if (self.delegate != nil) {
        [self.delegate credentialImport:self didImportWithStatus:kCredentialImportStatusCancelled];
    }
}

#pragma mark * View controller boilerplate

@synthesize descriptionLabel       = _descriptionLabel;
@synthesize typeLabel              = _typeLabel;
@synthesize originLabel            = _originLabel;
@synthesize passwordField          = _passwordField;
@synthesize passwordIncorrectLabel = _passwordIncorrectLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    assert(self.descriptionLabel != nil);
    assert(self.typeLabel != nil);
    assert(self.originLabel != nil);
    assert(self.passwordField != nil);
    assert(self.passwordField.delegate == self);
    assert(self.passwordIncorrectLabel != nil);

    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    // Set up the UI to reflect what the user is trying to import.  This includes, 
    // for example, setting the the various text fields and hiding the password 
    // field if we're importing a certificate.
    
    if (self.isPKCS12) {
        self.descriptionLabel.text = [NSString stringWithFormat:@"not available prior to import"];
        self.typeLabel.text = @"identity";

        // Debug builds get a default password of "test".
        
        #if ! defined(NDEBUG)
            self.passwordField.text = @"test";
        #endif
    } else {
        SecCertificateRef   cert;
        CFStringRef         summary;
        
        summary = NULL;
        cert = SecCertificateCreateWithData(NULL, (CFDataRef) self.data);
        if (cert != NULL) {
            summary = SecCertificateCopySubjectSummary(cert);
        }
        if (summary == NULL) {
            summary = CFSTR("unknown");
        }
        
        if (self.origin != nil) {
            self.descriptionLabel.text = (NSString *) summary;
        } else {
            self.descriptionLabel.text = @"n/a";
        }
        
        if (summary != NULL) {
            CFRelease(summary);
        }
        if (cert != NULL) {
            CFRelease(cert);
        }

        self.typeLabel.text = @"certificate";
        self.passwordField.hidden = YES;
    }

    if (self.origin != nil) {
        self.originLabel.text = [self.origin absoluteString];
    } else {
        self.originLabel.text = @"n/a";
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    assert(self.delegate != nil);           // c'mon folks!

    [super viewWillAppear:animated];
    
    if (self.isPKCS12) {
        [self.passwordField becomeFirstResponder];
    }
    self.passwordIncorrectLabel.hidden = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.descriptionLabel = nil;
    self.typeLabel = nil;
    self.originLabel = nil;
    self.passwordField = nil;
    self.passwordIncorrectLabel = nil;
}

- (void)dealloc
{
    [self->_data release];
    [self->_type release];
    [self->_origin release];

    [self->_descriptionLabel release];
    [self->_typeLabel release];
    [self->_originLabel release];
    [self->_passwordField release];
    [self->_passwordIncorrectLabel release];

    [super dealloc];
}

@end
