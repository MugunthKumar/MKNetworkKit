/*
    File:       DebugOptions.m

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

#import "DebugOptions.h"

@implementation DebugOptions

@synthesize serverValidation = _serverValidation;

- (void)setServerValidation:(NSUInteger)newValue
{
    assert(newValue <= kDebugOptionsServerValidationCount);
    if (newValue != self->_serverValidation) {
        self->_serverValidation = newValue;
        [[NSUserDefaults standardUserDefaults] setInteger:self->_serverValidation forKey:@"ServerValidation"];
    }
}

@synthesize credentialPersistence = _credentialPersistence;

- (void)setCredentialPersistence:(NSURLCredentialPersistence)newValue
{
    // assert(newValue >= NSURLCredentialPersistenceNone);      -- not necessary because NSURLCredentialPersistenceNone is unsigned
    assert(newValue <= NSURLCredentialPersistencePermanent);
    if (newValue != self->_credentialPersistence) {
        self->_credentialPersistence = newValue;
        [[NSUserDefaults standardUserDefaults] setInteger:self->_credentialPersistence forKey:@"CredentialPersistence"];
    }
}

@synthesize earlyTimeout = _earlyTimeout;

- (void)setEarlyTimeout:(BOOL)newValue
{
    if (newValue != self->_earlyTimeout) {
        self->_earlyTimeout = newValue;
        [[NSUserDefaults standardUserDefaults] setBool:self->_earlyTimeout forKey:@"EarlyTimeout"];
    }
}

@synthesize alwaysPresentIdentityChoice = _alwaysPresentIdentityChoice;

- (void)setAlwaysPresentIdentityChoice:(BOOL)newValue
{
    if (newValue != self->_alwaysPresentIdentityChoice) {
        self->_alwaysPresentIdentityChoice = newValue;
        [[NSUserDefaults standardUserDefaults] setBool:self->_alwaysPresentIdentityChoice forKey:@"AlwaysPresentIdentityChoice"];
    }
}

@synthesize naiveIdentityList = _naiveIdentityList;

- (void)setNaiveIdentityList:(BOOL)newValue
{
    if (newValue != self->_naiveIdentityList) {
        self->_naiveIdentityList = newValue;
        [[NSUserDefaults standardUserDefaults] setBool:self->_naiveIdentityList forKey:@"NaiveIdentityList"];
    }
}

- (void)resetToDefaults
{
    self.serverValidation      = kDebugOptionsServerValidationDefault;
    self.credentialPersistence = NSURLCredentialPersistenceNone;
    self.earlyTimeout          = NO;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        self->_serverValidation      = [[NSUserDefaults standardUserDefaults] integerForKey:@"ServerValidation"];
        if (self.serverValidation >= kDebugOptionsServerValidationCount) {
            self.serverValidation = kDebugOptionsServerValidationDefault;
        }

        self->_credentialPersistence = [[NSUserDefaults standardUserDefaults] integerForKey:@"CredentialPersistence"];
        if (self.credentialPersistence > NSURLCredentialPersistencePermanent) {
            self.credentialPersistence = NSURLCredentialPersistenceNone;
        }

        self->_earlyTimeout                = [[NSUserDefaults standardUserDefaults] boolForKey:@"EarlyTimeout"];
        self->_alwaysPresentIdentityChoice = [[NSUserDefaults standardUserDefaults] boolForKey:@"AlwaysPresentIdentityChoice"];
        self->_naiveIdentityList           = [[NSUserDefaults standardUserDefaults] boolForKey:@"NaiveIdentityList"];
    }
    return self;
}

+ (DebugOptions *)sharedDebugOptions
{
    static DebugOptions * sDebugOptions;
    
    if (sDebugOptions == nil) {
        sDebugOptions = [[DebugOptions alloc] init];
        assert(sDebugOptions != nil);
    }
    return sDebugOptions;
}

@end
