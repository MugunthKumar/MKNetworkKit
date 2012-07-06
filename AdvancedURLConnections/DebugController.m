/*
    File:       DebugController.m

    Contains:   Manages the Debug tab.

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

#import "DebugController.h"

#import "DebugOptions.h"

@interface DebugController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain, readonly) DebugOptions * debugOptions;

@end

@implementation DebugController

- (DebugOptions *)debugOptions
{
    if (self->_debugOptions == nil) {
        self->_debugOptions = [[DebugOptions sharedDebugOptions] retain];
        assert(self->_debugOptions != nil);
    }
    return self->_debugOptions;
}

// Section indices within the main table view.

enum {
    kSectionIndexServerValidation = 0,      // rows are kServerValidationXxx
    kSectionIndexCredentialsStorage,        // rows are NSURLCredentialPersistence
    kSectionIndexDebugOptions,
    kSectionCount
};

// Rows in the kSectionIndexDebugOptions section.

enum {
    kDebugOptionsEarlyTimeout = 0, 
    kDebugOptionsAlwaysPresentIdentityChoice,
    kDebugOptionsNaiveIdentityList,
    kDebugOptionsCount
};

// NSURLCredentialPersistence doesn't define a 'count' value, so we define one for ourselves.

enum {
    NSURLCredentialPersistenceCount = NSURLCredentialPersistencePermanent + 1
};

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
        case kSectionIndexServerValidation: {
            result = kDebugOptionsServerValidationCount;
        } break;
        case kSectionIndexCredentialsStorage: {
            result = NSURLCredentialPersistenceCount;
        } break;
        case kSectionIndexDebugOptions: {
            result = kDebugOptionsCount;
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
        case kSectionIndexServerValidation: {
            result = @"TLS Server Validation";
        } break;
        case kSectionIndexCredentialsStorage: {
            result = @"Credential Persistence";
        } break;
        case kSectionIndexDebugOptions: {
            result = @"Debug Options";
        } break;
        default: {
            assert(NO);
            result = nil;
        } break;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)
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
    
    cell.accessoryType = UITableViewCellAccessoryNone;

    // Do various things depending on the section and row.
    
    row = indexPath.row;
    switch (indexPath.section) {
        case kSectionIndexServerValidation: {
            assert(row < kDebugOptionsServerValidationCount);
            switch (row) {
                case kDebugOptionsServerValidationDefault: {
                    cell.textLabel.text = @"Default";
                } break;
                case kDebugOptionsServerValidationAskPerUntrustedSite: {
                    cell.textLabel.text = @"Ask For Each Untrusted Site";
                } break;
                case kDebugOptionsServerValidationTrustImportedCertificates: {
                    cell.textLabel.text = @"Trust Imported Certificates";
                } break;
                case kDebugOptionsServerValidationDisabled: {
                    cell.textLabel.text = @"Disabled";
                } break;
            }
            cell.accessoryType = (row == self.debugOptions.serverValidation) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } break;
        case kSectionIndexCredentialsStorage: {
            assert(row < NSURLCredentialPersistenceCount);
            switch (row) {
                case NSURLCredentialPersistenceNone: {
                    cell.textLabel.text = @"None";
                } break;
                case NSURLCredentialPersistenceForSession: {
                    cell.textLabel.text = @"For Session";
                } break;
                case NSURLCredentialPersistencePermanent: {
                    cell.textLabel.text = @"Permanent";
                } break;
            }
            cell.accessoryType = (row == self.debugOptions.credentialPersistence) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } break;
        case kSectionIndexDebugOptions: {
            assert(row < kDebugOptionsCount);
            switch (row) {
                case kDebugOptionsEarlyTimeout: {
                    cell.textLabel.text = @"Early Timeout";
                    cell.accessoryType = self.debugOptions.earlyTimeout ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                } break;
                case kDebugOptionsAlwaysPresentIdentityChoice: {
                    cell.textLabel.text = @"Always Present Identity Choice";
                    cell.accessoryType = self.debugOptions.alwaysPresentIdentityChoice ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                } break;
                case kDebugOptionsNaiveIdentityList: {
                    cell.textLabel.text = @"Naïve Identity List";
                    cell.accessoryType = self.debugOptions.naiveIdentityList ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                } break;
            }
        } break;
        default: {
            assert(NO);
        } break;
    }
    
    return cell;
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

    // We watch for selections that change the various debug options, reflect those 
    // changes down to the DebugOptions object, and then update the table view cell 
    // to reflect those changes.
    //
    // IMPORTANT: We don't actually listen for or respond to KVO notifications 
    // for these debug options.  Effectively we 'own' the options; no one else 
    // is going to change them out from underneath us.  Also, updating our UI 
    // as we've done it here makes it easy to get a nice clean update.

    section = indexPath.section;
    row     = indexPath.row;
    switch (section) {
        case kSectionIndexServerValidation: {
            assert(row < kDebugOptionsServerValidationCount);
            if (row != self.debugOptions.serverValidation) {
                cellToClear = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.debugOptions.serverValidation inSection:section]];
                cellToSet   = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row                                inSection:section]];
                self.debugOptions.serverValidation = row;
            }
        } break;
        case kSectionIndexCredentialsStorage: {
            assert(row < NSURLCredentialPersistenceCount);
            if (row != self.debugOptions.credentialPersistence) {
                cellToClear = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.debugOptions.credentialPersistence inSection:section]];
                cellToSet   = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row                                     inSection:section]];
                self.debugOptions.credentialPersistence = row;
            }
        } break;
        case kSectionIndexDebugOptions: {
            NSString *  propertyName;
            
            propertyName = nil;
            assert(row < kDebugOptionsCount);
            switch (row) {
                case kDebugOptionsEarlyTimeout: {
                    propertyName = @"earlyTimeout";
                } break;
                case kDebugOptionsAlwaysPresentIdentityChoice: {
                    propertyName = @"alwaysPresentIdentityChoice";
                } break;
                case kDebugOptionsNaiveIdentityList: {
                    propertyName = @"naiveIdentityList";
                } break;
            }
            assert(propertyName != nil);

            if ( [[self.debugOptions valueForKey:propertyName] boolValue] ) {
                [self.debugOptions setValue:[NSNumber numberWithBool:NO]  forKey:propertyName];
                cellToClear = [self.tableView cellForRowAtIndexPath:indexPath];
            } else {
                [self.debugOptions setValue:[NSNumber numberWithBool:YES] forKey:propertyName];
                cellToSet   = [self.tableView cellForRowAtIndexPath:indexPath];
            }
        } break;
        default: {
            assert(NO);
        } break;
    }

    if (cellToClear != nil) {
        cellToClear.accessoryType = UITableViewCellAccessoryNone;
    }
    if (cellToSet != nil) {
        cellToSet.accessoryType   = UITableViewCellAccessoryCheckmark;
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark * View controller boilerplate

- (void)dealloc
{
    [self->_debugOptions release];
    [super dealloc];
}

@end
