/*
    File:       DebugOptions.h

    Contains:   Holds our debugging preferences.

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

#import <Foundation/Foundation.h>

@interface DebugOptions : NSObject
{
    NSUInteger                  _serverValidation;
    NSURLCredentialPersistence  _credentialPersistence;
    BOOL                        _earlyTimeout;
    BOOL                        _alwaysPresentIdentityChoice;
    BOOL                        _naiveIdentityList;
}

+ (DebugOptions *)sharedDebugOptions;
    // Returns a singleton object for use by clients.

// Values for the serverValidation property.

enum {
    kDebugOptionsServerValidationDefault = 0,
    kDebugOptionsServerValidationAskPerUntrustedSite,
    kDebugOptionsServerValidationTrustImportedCertificates,
    kDebugOptionsServerValidationDisabled,
    kDebugOptionsServerValidationCount
};

@property (nonatomic, assign, readwrite) NSUInteger                 serverValidation;
    // Specifies how the user wants to do server identity validation.
    // Values listed above.
    
@property (nonatomic, assign, readwrite) NSURLCredentialPersistence credentialPersistence;
    // Specifies how the user wants to store credentials.  See "NSURLCredential.h" 
    // for the values.
    
@property (nonatomic, assign, readwrite) BOOL                       earlyTimeout;
    // True if the Get controller should trigger an early timeout to test the 
    // challenge cancellation code.
    
@property (nonatomic, assign, readwrite) BOOL                       alwaysPresentIdentityChoice;
    // True if the client identity challenge handler should put up the client 
    // identity view controller even if there are no valid identities.
    
@property (nonatomic, assign, readwrite) BOOL                       naiveIdentityList;
    // True if the client identity challenge handler opts out of identity 
    // list generation, leaving the client identity controller to generate a 
    // naive identity list.

// serverValidation, credentialPersistence and all Boolean properties are observable.

- (void)resetToDefaults;
    // Resets these preferences back to their defaults.

@end
