/*
    File:       ClientIdentityController.m

    Contains:   Runs an HTTPS client identity choice view.

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

#import "ClientIdentityController.h"

@interface ClientIdentityController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, copy,   readonly) NSArray *       identities;

@end

@implementation ClientIdentityController

+ (NSArray *)_identities
    // Returns an array of SecIdentityRef that represents the available client-side 
    // identities in the keychain.
    //
    // We go /back/ to the keychain to get the list of identities rather than 
    // using the Credentials module.  This decouples this class from the program 
    // as a whole, making it easier for folks to reuse it.  OTOH, if the client 
    // wants to use an alternative identity source, it can implement the 
    // -identityViewIdentitiesToDisplay: delegate callback.
{
    OSStatus        err;
    NSArray *       result;
    CFArrayRef      identities;

    identities = NULL;
    
    err = SecItemCopyMatching(
        (CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
            (id) kSecClassIdentity,     kSecClass, 
            kSecMatchLimitAll,          kSecMatchLimit, 
            kCFBooleanTrue,             kSecReturnRef, 
            nil
        ],
        (CFTypeRef *) &identities
    );
    if (err == noErr) {
        result = [NSArray arrayWithArray:(id) identities];
    } else {
        result = [NSArray array];
    }
    
    if (identities != NULL) {
        CFRelease(identities);
    }
    
    return result;
}

- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge
{
    assert(challenge != nil);
    
    self = [super initWithNibName:@"ClientIdentityController" bundle:[NSBundle bundleForClass:[self class]]];
    if (self != nil) {
        self->_challenge = [challenge retain];
    }
    return self;
}

- (NSArray *)identities
{
    if (self->_identities == nil) {
        NSArray *   identities;

        identities = nil;
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(identityViewIdentitiesToDisplay:)] ) {
            identities = [self.delegate identityViewIdentitiesToDisplay:self];
        }
        if (identities == nil) {
            identities = [[self class] _identities];
        }
        assert(identities != nil);  // because, if things fail, +_identities will return an empty array 

        self->_identities = [identities copy];
    }
    return self->_identities;
}

@synthesize delegate       = _delegate;
@synthesize challenge      = _challenge;
@synthesize chosenIdentity = _chosenIdentity;

#pragma mark * Action code

- (IBAction)cancelAction:(id)sender
{
    #pragma unused(sender)
    
    if (self.delegate != nil) {
        [self.delegate identityView:self didChooseIdentity:NULL];
    }
}

#pragma mark * Table view callbacks

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tv)
    #pragma unused(section)
    NSInteger   result;
    
    assert(tv == self.identityTable);
    assert(section == 0);
    
    result = self.identities.count;
    if (result == 0) {
        result = 1;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)
    OSStatus            err;
    UITableViewCell *   cell;
    CFStringRef         certName;
    
    assert(tv == self.identityTable);
    assert(indexPath != nil);
    assert(indexPath.section == 0);
    
    certName = NULL;

    if (self.identities.count != 0) {
        SecIdentityRef      identity;
        SecCertificateRef   cert;

        assert(indexPath.row < self.identities.count);

        identity = (SecIdentityRef) [self.identities objectAtIndex:indexPath.row];
        assert( (identity != NULL) && (CFGetTypeID(identity) == SecIdentityGetTypeID()) );

        cert = NULL;
        err = SecIdentityCopyCertificate(identity, &cert);
        assert(err == noErr);
        assert(cert != NULL);
        
        certName = SecCertificateCopySubjectSummary(cert);
        assert(certName != NULL);

        CFRelease(cert);
    }
    
    cell = [self.identityTable dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"] autorelease];
        assert(cell != nil);
    }
    if (certName == NULL) {
        cell.textLabel.font = [UIFont italicSystemFontOfSize:[UIFont labelFontSize]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = @"none";
    } else {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.textLabel.text = (id) certName;
    }
    
    if (certName != NULL) {
        CFRelease(certName);
    }
    
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    NSIndexPath *   result;
    
    assert(tv == self.identityTable);
    assert(indexPath != nil);
    assert(indexPath.section == 0);
    
    if (self.identities.count == 0) {
        result = nil;
    } else {
        assert(indexPath.row < self.identities.count);
        result = indexPath;
    }
    return result;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)
    SecIdentityRef      identity;

    assert(tv == self.identityTable);
    assert(indexPath != nil);
    assert(indexPath.section == 0);
    assert(indexPath.row < self.identities.count);

    identity = (SecIdentityRef) [self.identities objectAtIndex:indexPath.row];
    assert( (identity != NULL) && (CFGetTypeID(identity) == SecIdentityGetTypeID()) );

    self->_chosenIdentity = identity;
    if (self.delegate != nil) {
        [self.delegate identityView:self didChooseIdentity:identity];
    }
    [self.identityTable deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark * View controller boilerplate

@synthesize identityTable = _identityTable;

- (void)viewDidLoad
{
    [super viewDidLoad];
    assert(self.identityTable != nil);
    assert(self.identityTable.delegate == self);
    assert(self.identityTable.dataSource == self);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    assert(self.delegate != nil);           // c'mon folks
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.identityTable flashScrollIndicators];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(identityViewDidDisappear:)] ) {
        [self.delegate identityViewDidDisappear:self];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.identityTable = nil;
}

- (void)dealloc
{
    [self->_challenge release];
    [self->_identities release];

    [self->_identityTable release];

    [super dealloc];
}

@end
