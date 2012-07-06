/*
    File:       CredentialImportController.h

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

#import <UIKit/UIKit.h>

// You typically run this view controller by:
//
// 1. creating it with credential data of a supported type
// 2. setting yourself as the delegate
// 3. optionally set the URL
// 4. presenting it modally
//
// If the user taps Cancel, your -identityView:didChooseIdentity: delegate method 
// will be called with kCredentialImportStatusCancelled.
//
// If the user successfully imports the credential, that method will be called with 
// kCredentialImportStatusSucceeded.
//
// Finally, if the import fails for some reason, your delegate callback will be 
// with kCredentialImportStatusFailed.  You are responsible for displaying this 
// error to the user.
//
// When you're done, dismiss the view controller.

typedef enum {
    kCredentialImportStatusCancelled, 
    kCredentialImportStatusFailed, 
    kCredentialImportStatusSucceeded
} CredentialImportStatus;

@protocol CredentialImportControllerDelegate;

@interface CredentialImportController : UIViewController
{
    UILabel *           _descriptionLabel;
    UILabel *           _typeLabel;
    UILabel *           _originLabel;
    UITextField *       _passwordField;
    UILabel *           _passwordIncorrectLabel;

    NSData *            _data;
    NSString *          _type;
    NSURL *             _origin;
    id<CredentialImportControllerDelegate> _delegate;
}

@property (nonatomic, retain, readwrite) IBOutlet UILabel *         descriptionLabel;
@property (nonatomic, retain, readwrite) IBOutlet UILabel *         typeLabel;
@property (nonatomic, retain, readwrite) IBOutlet UILabel *         originLabel;
@property (nonatomic, retain, readwrite) IBOutlet UITextField *     passwordField;
@property (nonatomic, retain, readwrite) IBOutlet UILabel *         passwordIncorrectLabel;

- (IBAction)importAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

+ (NSSet *)supportedMIMETypes;
    // Returns the MIME types whose data we expect to be able to import.

- (id)initWithCredentialData:(NSData *)data type:(NSString *)type;
    // The type must be one of the types returned by +supportedMIMETypes. 
    // See the implementation for the current list of supported types.

@property (nonatomic, copy,   readonly)  NSData *     data;
@property (nonatomic, copy,   readonly)  NSString *   type;
    // These properties are immutable copies of the values you passed to the init method.

@property (nonatomic, copy,   readwrite) NSURL *      origin;
    // If you set this to the URL from which you downloaded the credential, the 
    // UI will display it for you.
    
@property (nonatomic, assign, readwrite) id<CredentialImportControllerDelegate> delegate;

@end

@protocol CredentialImportControllerDelegate <NSObject>

@required

- (void)credentialImport:(CredentialImportController *)credentialImport didImportWithStatus:(CredentialImportStatus)status;
    // Called by CredentialImportController when the import has been resolved, 
    // either by cancellation (status is kCredentialImportStatusCancelled), failure 
    // (kCredentialImportStatusFailed), or success (kCredentialImportStatusSucceeded).

@end

