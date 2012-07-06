/*
    File:       Credentials.m

    Contains:   A model object for credentials.

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

#import "Credentials.h"

@interface Credentials ()
- (void)_refreshNotify:(BOOL)notify;
@end

@implementation Credentials

#pragma mark * Debugging

- (void)_printCertificate:(SecCertificateRef)certificate attributes:(NSDictionary *)attrs indent:(int)indent
    // Prints a certificate for debugging purposes.  The indent parameter is necessary to 
    // allow different indents depending on whether the key is part of an identity or not.
{
    CFStringRef         summary;
    NSString *          label;
    NSData *            hash;

    assert(certificate != NULL);
    assert(attrs != nil);

    summary = SecCertificateCopySubjectSummary(certificate);
    assert(summary != NULL);
    
    label = [attrs objectForKey:(id)kSecAttrLabel];
    if (label != nil) {
        fprintf(stderr, "%*slabel   = '%s'\n", indent, "", [label UTF8String]);
    }
    fprintf(stderr, "%*ssummary = '%s'\n", indent, "", [(NSString *)summary UTF8String]);
    hash = [attrs objectForKey:(id)kSecAttrPublicKeyHash];
    if (hash != nil) {
        fprintf(stderr, "%*shash    = %s\n", indent, "", [[hash description] UTF8String]);
    }
    
    CFRelease(summary);
}

- (void)_printKey:(SecKeyRef)key attributes:(NSDictionary *)attrs attrName:(CFTypeRef)attrName flagValues:(const char *)flagValues
    // Prints a flag within a key.
{
    #pragma unused(key)
    id  flag;
    
    assert(key != NULL);
    assert(attrs != nil);
    assert(attrName != NULL);
    assert(flagValues != NULL);
    assert(strlen(flagValues) == 2);
    
    flag = [attrs objectForKey:(id)attrName];
    if (flag == nil) {
        fprintf(stderr, "-");
    } else if ([flag boolValue]) {
        fprintf(stderr, "%c", flagValues[0]);
    } else {
        fprintf(stderr, "%c", flagValues[1]);
    }
}

- (void)_printKey:(SecKeyRef)key attributes:(NSDictionary *)attrs indent:(int)indent
    // Prints a key for debugging purposes.  The indent parameter is necessary to allow 
    // different indents depending on whether the key is part of an identity or not.
{
    #pragma unused(key)
    id          label;
    CFTypeRef   keyClass;

    assert(key != NULL);
    assert(attrs != nil);

    label = [attrs objectForKey:(id)kSecAttrLabel];
    if (label != nil) {
        fprintf(stderr, "%*slabel     = '%s'\n", indent, "", [label UTF8String]);
    }
    label = [attrs objectForKey:(id)kSecAttrApplicationLabel];
    if (label != nil) {
        fprintf(stderr, "%*sapp label = %s\n", indent, "", [[label description] UTF8String]);
    }
    label = [attrs objectForKey:(id)kSecAttrApplicationTag];
    if (label != nil) {
        fprintf(stderr, "%*sapp tag   = %s\n", indent, "", [[label description] UTF8String]);
    }
    fprintf(stderr, "%*sflags     = ", indent, "");
    [self _printKey:key attributes:attrs attrName:kSecAttrCanEncrypt flagValues:"Ee"];
    [self _printKey:key attributes:attrs attrName:kSecAttrCanDecrypt flagValues:"Dd"];
    [self _printKey:key attributes:attrs attrName:kSecAttrCanDerive  flagValues:"Rr"];
    [self _printKey:key attributes:attrs attrName:kSecAttrCanSign    flagValues:"Ss"];
    [self _printKey:key attributes:attrs attrName:kSecAttrCanVerify  flagValues:"Vv"];
    [self _printKey:key attributes:attrs attrName:kSecAttrCanWrap    flagValues:"Ww"];
    [self _printKey:key attributes:attrs attrName:kSecAttrCanUnwrap  flagValues:"Uu"];
    fprintf(stderr, "\n");

    keyClass = (CFTypeRef) [attrs objectForKey:(id)kSecAttrKeyClass];
    if (keyClass != nil) {
        const char *    keyClassStr;
        
        // keyClass is a CFNumber whereas kSecAttrKeyClassPublic (and so on)
        // are CFStrings.  Gosh, that makes things hard <rdar://problem/6914637>. 
        // So I compare their descriptions.  Yuck!
        
        if ( [[(id)keyClass description] isEqual:(id)kSecAttrKeyClassPublic] ) {
            keyClassStr = "kSecAttrKeyClassPublic";
        } else if ( [[(id)keyClass description] isEqual:(id)kSecAttrKeyClassPrivate] ) {
            keyClassStr = "kSecAttrKeyClassPrivate";
        } else if ( [[(id)keyClass description] isEqual:(id)kSecAttrKeyClassSymmetric] ) {
            keyClassStr = "kSecAttrKeyClassSymmetric";
        } else {
            keyClassStr = "?";
        }
        fprintf(stderr, "%*skey class = %s\n", indent, "", keyClassStr);
    }
}

- (void)_printIdentity:(SecIdentityRef)identity attributes:(NSDictionary *)attrs
    // Prints an identity for debugging purposes.
{
    OSStatus            err;
    SecCertificateRef   certificate;
    SecKeyRef           key;

    assert(identity != NULL);
    assert(attrs != nil);
    
    err = SecIdentityCopyCertificate(identity, &certificate);
    assert(err == noErr);
    
    err = SecIdentityCopyPrivateKey(identity, &key);
    assert(err == noErr);
    
    fprintf(stderr, "    certificate\n");
    [self _printCertificate:certificate attributes:attrs indent:6];
    fprintf(stderr, "    key\n");
    [self _printKey:key attributes:attrs indent:6];
    
    CFRelease(key);
    CFRelease(certificate);
}

- (void)_printCertificate:(SecCertificateRef)certificate attributes:(NSDictionary *)attrs
    // Prints a certificate for debugging purposes.  The real work is done 
    // by a helper routine that's shared with -_printIdentity:attributes:.
{
    assert(certificate != NULL);
    assert(attrs != nil);
    [self _printCertificate:certificate attributes:attrs indent:4];
}

- (void)_printKey:(SecKeyRef)key attributes:(NSDictionary *)attrs
    // Prints a certificate for debugging purposes.  The real work is done 
    // by a helper routine that's shared with -_printIdentity:attributes:.
{
    assert(key != NULL);
    assert(attrs != nil);
    [self _printKey:key attributes:attrs indent:4];
}

- (void)_printPassword:(id)ref attributes:(NSDictionary *)attrs
{
    #pragma unused(ref)
    NSString *  s;
    NSNumber *  n;
    NSData *    d;
    
    assert(ref == nil);         // there is no 'ref' object for Internet and generic passwords
    assert(attrs != nil);

/*
    common:
        kSecAttrDescription
        kSecAttrComment
        kSecAttrCreator
        kSecAttrType
        kSecAttrLabel
        kSecAttrIsInvisible
        kSecAttrIsNegative
        kSecAttrAccount
*/

    s = [attrs objectForKey:(id)kSecAttrDescription];
    if (s != nil) {
        fprintf(stderr, "    description = '%s'\n", [s UTF8String]);
    }
    s = [attrs objectForKey:(id)kSecAttrComment];
    if (s != nil) {
        fprintf(stderr, "    comment     = '%s'\n", [s UTF8String]);
    }
    s = [attrs objectForKey:(id)kSecAttrLabel];
    if (s != nil) {
        fprintf(stderr, "    label       = '%s'\n", [s UTF8String]);
    }
    s = [attrs objectForKey:(id)kSecAttrAccount];
    if (s != nil) {
        fprintf(stderr, "    account     = '%s'\n", [s UTF8String]);
    }

/*
    Internet:
        kSecAttrSecurityDomain
        kSecAttrServer
        kSecAttrProtocol
        kSecAttrAuthenticationType
        kSecAttrPort
        kSecAttrPath
*/
    s = [attrs objectForKey:(id)kSecAttrSecurityDomain];
    if (s != nil) {
        fprintf(stderr, "    domain      = '%s'\n", [s UTF8String]);
    }
    s = [attrs objectForKey:(id)kSecAttrServer];
    if (s != nil) {
        fprintf(stderr, "    server      = '%s'\n", [s UTF8String]);
    }
    s = [attrs objectForKey:(id)kSecAttrProtocol];
    if (s != nil) {
        static NSDictionary * sProtocolToNameMap;
        NSString *            protocolName;
        
        if (sProtocolToNameMap == nil) {
            sProtocolToNameMap = [[NSDictionary alloc] initWithObjectsAndKeys:
                @"FTP",         kSecAttrProtocolFTP, 
                @"FTP Account", kSecAttrProtocolFTPAccount, 
                @"HTTP",        kSecAttrProtocolHTTP, 
                @"IRC",         kSecAttrProtocolIRC, 
                @"NNTP",        kSecAttrProtocolNNTP, 
                @"POP3",        kSecAttrProtocolPOP3, 
                @"SMTP",        kSecAttrProtocolSMTP, 
                @"SOCKS",       kSecAttrProtocolSOCKS, 
                @"IMAP",        kSecAttrProtocolIMAP, 
                @"LDAP",        kSecAttrProtocolLDAP, 
                @"AppleTalk",   kSecAttrProtocolAppleTalk, 
                @"AFP",         kSecAttrProtocolAFP, 
                @"Telnet",      kSecAttrProtocolTelnet, 
                @"SSH",         kSecAttrProtocolSSH, 
                @"FTPS",        kSecAttrProtocolFTPS, 
                @"HTTPS",       kSecAttrProtocolHTTPS, 
                @"HTTP Proxy",  kSecAttrProtocolHTTPProxy, 
                @"HTTPS Proxy", kSecAttrProtocolHTTPSProxy, 
                @"FTP Proxy",   kSecAttrProtocolFTPProxy, 
                @"SMB",         kSecAttrProtocolSMB, 
                @"RTSP",        kSecAttrProtocolRTSP, 
                @"RTSP Proxy",  kSecAttrProtocolRTSPProxy, 
                @"DAAP",        kSecAttrProtocolDAAP, 
                @"EPPC",        kSecAttrProtocolEPPC, 
                @"IPP",         kSecAttrProtocolIPP, 
                @"NNTPS",       kSecAttrProtocolNNTPS, 
                @"LDAPS",       kSecAttrProtocolLDAPS, 
                @"TelnetS",     kSecAttrProtocolTelnetS, 
                @"IMAPS",       kSecAttrProtocolIMAPS, 
                @"IRCS",        kSecAttrProtocolIRCS, 
                @"POP3S",       kSecAttrProtocolPOP3S, 
                nil
            ];
            assert(sProtocolToNameMap != nil);
        }
        
        protocolName = [sProtocolToNameMap objectForKey:s];
        if (protocolName == nil) {
            protocolName = [NSString stringWithFormat:@"'%@'", s];
            assert(protocolName != nil);
        }
        fprintf(stderr, "    protocol    = '%s'\n", [protocolName UTF8String]);
    }
    n = [attrs objectForKey:(id)kSecAttrPort];
    if (n != nil) {
        fprintf(stderr, "    port        = %d\n", [n intValue]);
    }
    s = [attrs objectForKey:(id)kSecAttrPath];
    if (s != nil) {
        fprintf(stderr, "    path        = '%s'\n", [s UTF8String]);
    }

/*
    generic:
        kSecAttrService
        kSecAttrGeneric
*/
    s = [attrs objectForKey:(id)kSecAttrService];
    if (s != nil) {
        fprintf(stderr, "    service     = '%s'\n", [s UTF8String]);
    }
    d = [attrs objectForKey:(id)kSecAttrGeneric];
    if (d != nil) {
        fprintf(stderr, "    generic     = '%s'\n", [[d description] UTF8String]);
    }
}

- (void)_dumpCredentialsOfSecClass:(CFTypeRef)secClass printSelector:(SEL)printSelector
    // Iterates through all of the credentials of a particular class 
    // (identity, key, certificate, Internet, generic) and calls the selector on each.
{
    OSStatus    err;
    CFArrayRef  result;
    CFIndex     resultCount;
    CFIndex     resultIndex;

    assert(secClass != NULL);
    assert(printSelector != nil);
    
    result = NULL;
    err = SecItemCopyMatching(
        (CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
            (id)secClass,           kSecClass, 
            kSecMatchLimitAll,      kSecMatchLimit, 
            kCFBooleanTrue,         kSecReturnRef, 
            kCFBooleanTrue,         kSecReturnAttributes, 
            nil
        ], 
        (CFTypeRef *) &result
    );
    assert( (err == noErr) == (result != NULL) );
    if (result != NULL) {
        assert( CFGetTypeID(result) == CFArrayGetTypeID() );
        
        resultCount = CFArrayGetCount(result);
        for (resultIndex = 0; resultIndex < resultCount; resultIndex++) {
            NSDictionary *  thisResult;
            
            fprintf(stderr, "  %zd\n", (ssize_t) resultIndex);
            thisResult = (NSDictionary *) CFArrayGetValueAtIndex(result, resultIndex);
            [self performSelector:printSelector withObject:[thisResult objectForKey:(NSString *)kSecValueRef] withObject:thisResult];
        }
        
        CFRelease(result);
    }
}

- (void)_dumpCredentials
{
    fprintf(stderr, "identities:\n");
    [self _dumpCredentialsOfSecClass:kSecClassIdentity printSelector:@selector(_printIdentity:attributes:)];

    fprintf(stderr, "certificates:\n");
    [self _dumpCredentialsOfSecClass:kSecClassCertificate printSelector:@selector(_printCertificate:attributes:)];

    fprintf(stderr, "keys:\n");
    [self _dumpCredentialsOfSecClass:kSecClassKey printSelector:@selector(_printKey:attributes:)];

    fprintf(stderr, "Internet:\n");
    [self _dumpCredentialsOfSecClass:kSecClassInternetPassword printSelector:@selector(_printPassword:attributes:)];

    fprintf(stderr, "generic:\n");
    [self _dumpCredentialsOfSecClass:kSecClassGenericPassword printSelector:@selector(_printPassword:attributes:)];
}

- (void)_resetCredentials
    // Deletes all credentials from the application's keychain.
{
    OSStatus    err;
    
    err = SecItemDelete((CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
            (id)kSecClassIdentity,   kSecClass, 
            nil
        ]
    );
    assert(err == noErr);
    
    err = SecItemDelete((CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
            (id)kSecClassCertificate, kSecClass, 
            nil
        ]
    );
    assert(err == noErr);

    err = SecItemDelete((CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
            (id)kSecClassKey,         kSecClass, 
            nil
        ]
    );
    assert(err == noErr);

    err = SecItemDelete((CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
            (id)kSecClassInternetPassword,  kSecClass, 
            nil
        ]
    );
    assert(err == noErr);

    err = SecItemDelete((CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
            (id)kSecClassGenericPassword,   kSecClass, 
            nil
        ]
    );
    assert(err == noErr);
}

#pragma mark * Core code

+ (Credentials *)sharedCredentials
{
    static Credentials * sSharedCredentials;
    
    if (sSharedCredentials == nil) {
        sSharedCredentials = [[Credentials alloc] init];
        assert(sSharedCredentials != nil);
    }
    return sSharedCredentials;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        self->_identities   = [[NSMutableArray alloc] init];
        assert(self->_identities != nil);
        self->_certificates = [[NSMutableArray alloc] init];
        assert(self->_certificates != nil);
        
        // Build initial values for the identities and certificates properties, 
        // without triggering KVO.
        
        [self _refreshNotify:NO];
    }
    return self;
}

- (NSArray *)_certificatesFromCertificates:(NSArray *)certificates excludingIdentities:(NSArray *)identities
    // Given an array of certificates and an array of identities, return all of the 
    // certificates that are /not/ associated with any identity.
{
    OSStatus                err;
    NSMutableArray *        standaloneCertificates;
    id                      obj;
    SecIdentityRef          identity;
    NSMutableDictionary *   certificateDataToIdentityMap;
    
    assert(certificates != nil);
    assert(identities != nil);

    // IMPORTANT: SecCertificateRef's are not uniqued (that is, you can get two 
    // different SecCertificateRef values that described the same fundamental 
    // certificate in the keychain), nor can they be compared with CFEqual.  So 
    // we match up certificates based on their data values.
    
    standaloneCertificates = [NSMutableArray array];
    assert(standaloneCertificates != NULL);
    
    // First build a map from certificate data values to corresponding identity object.
    
    certificateDataToIdentityMap = [NSMutableDictionary dictionary];
    assert(certificateDataToIdentityMap != NULL);
    
    for (obj in identities) {
        SecCertificateRef   identityCertificate;
        CFDataRef           identityCertificateData;
        
        identityCertificate = NULL;
        identityCertificateData = NULL;
        
        identity = (SecIdentityRef) obj;
        assert(CFGetTypeID(identity) == SecIdentityGetTypeID());
        
        err = SecIdentityCopyCertificate(identity, &identityCertificate);
        assert(err == noErr);
        
        identityCertificateData = SecCertificateCopyData(identityCertificate);
        assert(identityCertificateData != NULL);
        
        [certificateDataToIdentityMap setObject:(id)identity forKey:(NSData *)identityCertificateData];
        
        CFRelease(identityCertificateData);
        CFRelease(identityCertificate);
    }
    
    // Now go through the certificates looking for ones that aren't in that map. 
    // These are the standalone certificates.
    
    for (obj in certificates) {
        SecCertificateRef   certificate;
        CFDataRef           certificateData;

        certificate = (SecCertificateRef) obj;
        assert(CFGetTypeID(certificate) == SecCertificateGetTypeID());

        certificateData = SecCertificateCopyData(certificate);
        assert(certificateData != NULL);

        if ( [certificateDataToIdentityMap objectForKey:(NSData *)certificateData] == nil ) {
            [standaloneCertificates addObject:(id)certificate];
        }

        CFRelease(certificateData);
    }
    
    return standaloneCertificates;
}

static NSInteger OrderIdentities(id left, id right, void *context)
    // A sort function that compares two identities by the subject summary 
    // of their certificates.
{
    #pragma unused(context)
    NSInteger           result;
    OSStatus            err;
    SecIdentityRef      leftIdentity;
    SecIdentityRef      rightIdentity;
    SecCertificateRef   leftCertificate;
    SecCertificateRef   rightCertificate;
    CFStringRef         leftSubject;
    CFStringRef         rightSubject;
    
    leftIdentity  = (SecIdentityRef) left;
    rightIdentity = (SecIdentityRef) right;
    assert( (leftIdentity  != NULL) && (CFGetTypeID(leftIdentity ) == SecIdentityGetTypeID()));
    assert( (rightIdentity != NULL) && (CFGetTypeID(rightIdentity) == SecIdentityGetTypeID()));
    
    err = SecIdentityCopyCertificate(leftIdentity,  &leftCertificate);
    assert(err == noErr);
    err = SecIdentityCopyCertificate(rightIdentity, &rightCertificate);
    assert(err == noErr);
    
    leftSubject  = SecCertificateCopySubjectSummary(leftCertificate);
    rightSubject = SecCertificateCopySubjectSummary(rightCertificate);
    assert(leftSubject  != NULL);
    assert(rightSubject != NULL);
    
    result = [(NSString *)leftSubject localizedCaseInsensitiveCompare:(NSString *)rightSubject];
    
    CFRelease(leftSubject);
    CFRelease(rightSubject);
    CFRelease(leftCertificate);
    CFRelease(rightCertificate);
    
    return result;
}

static NSInteger OrderCertificates(id left, id right, void *context)
    // A sort function that compares two certificates by their subject summaries.
{
    #pragma unused(context)
    NSInteger           result;
    SecCertificateRef   leftCertificate;
    SecCertificateRef   rightCertificate;
    CFStringRef         leftSubject;
    CFStringRef         rightSubject;
    
    leftCertificate  = (SecCertificateRef) left;
    rightCertificate = (SecCertificateRef) right;
    assert( (leftCertificate  != NULL) && (CFGetTypeID(leftCertificate ) == SecCertificateGetTypeID()));
    assert( (rightCertificate != NULL) && (CFGetTypeID(rightCertificate) == SecCertificateGetTypeID()));
    
    leftSubject  = SecCertificateCopySubjectSummary(leftCertificate);
    rightSubject = SecCertificateCopySubjectSummary(rightCertificate);
    assert(leftSubject  != NULL);
    assert(rightSubject != NULL);
    
    result = [(NSString *)leftSubject localizedCaseInsensitiveCompare:(NSString *)rightSubject];
    
    CFRelease(leftSubject);
    CFRelease(rightSubject);
    
    return result;
}

- (void)_refreshNotify:(BOOL)notify
    // Refresh the identities and certificates properties from the current contents 
    // of the keychain, triggering a KVO notification if notify is YES.
    //
    // We make not attempt to rebuild the array nicely, that is, recording which 
    // values got inserted or removed.  This would be lots of tricky code, and it's 
    // not necessary given that our only client just reloads the entire table section 
    // when it gets the KVO notification.
{
    OSStatus        err;
    CFArrayRef      latestIdentities;
    CFArrayRef      latestCertificates;

    latestIdentities   = NULL;
    latestCertificates = NULL;
    
    // Get the current identities and certificates from the keychain.
    
    err = SecItemCopyMatching(
        (CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
            (id) kSecClassIdentity,     kSecClass, 
            kSecMatchLimitAll,          kSecMatchLimit, 
            kCFBooleanTrue,             kSecReturnRef, 
            nil
        ],
        (CFTypeRef *) &latestIdentities
    );
    if (err == errSecItemNotFound) {
        latestIdentities = CFArrayCreate(NULL, NULL, 0, &kCFTypeArrayCallBacks);
        assert(latestIdentities != NULL);
        err = noErr;
    }
    if (err == noErr) {
        err = SecItemCopyMatching(
            (CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                (id) kSecClassCertificate,  kSecClass, 
                kSecMatchLimitAll,          kSecMatchLimit, 
                kCFBooleanTrue,             kSecReturnRef, 
                nil
            ],
            (CFTypeRef *) &latestCertificates
        );
    }
    if (err == errSecItemNotFound) {
        latestCertificates = CFArrayCreate(NULL, NULL, 0, &kCFTypeArrayCallBacks);
        assert(latestCertificates != NULL);
        err = noErr;
    }
    
    // Work out which certificates are standalone (that is, not part of any 
    // identity) and then update our identities and certificates properties.
    
    if (err == noErr) {
        NSArray *   standaloneCertificates;
        
        assert(latestIdentities != NULL);
        assert(CFGetTypeID(latestIdentities)   == CFArrayGetTypeID());
        assert(latestCertificates != NULL);
        assert(CFGetTypeID(latestCertificates) == CFArrayGetTypeID());

        // The processing here is /staggeringly/ inefficient.  There's lots I could 
        // do to to fix this (first up, avoid calling SecIdentityCopyCertificate multiple 
        // times for the same certificate by building a map of identities to certificates, 
        // and then, for each certificate, normalise and fold the subject summary strings 
        // to speed up comparisons), but for the moment the number of identities and 
        // certificates is tiny so it's not a big deal.  The following asserts will trip 
        // if the numbers get out of hand.
        
        assert(CFArrayGetCount(latestIdentities)   < 100);
        assert(CFArrayGetCount(latestCertificates) < 100);

        standaloneCertificates = [self _certificatesFromCertificates:(NSArray *)latestCertificates excludingIdentities:(NSArray *)latestIdentities];
        assert(standaloneCertificates != nil);
        
        if (notify) {
            [self willChangeValueForKey:@"identities"];
        }
        [self->_identities setArray:(NSArray *)latestIdentities];
        [self->_identities sortUsingFunction:OrderIdentities context:NULL];
        if (notify) {
            [self didChangeValueForKey:@"identities"];
        }

        if (notify) {
            [self willChangeValueForKey:@"certificates"];
        }
        [self->_certificates setArray:standaloneCertificates];
        [self->_certificates sortUsingFunction:OrderCertificates context:NULL];
        if (notify) {
            [self didChangeValueForKey:@"certificates"];
        }
    }
    assert(err == noErr);
    
    if (latestCertificates != NULL) {
        CFRelease(latestCertificates);
    }
    if (latestIdentities != NULL) {
        CFRelease(latestIdentities);
    }
}

- (NSArray *)identities
{
    return [[self->_identities copy] autorelease];
}

- (NSArray *)certificates
{
    return [[self->_certificates copy] autorelease];
}

- (void)refresh
{
    [self _refreshNotify:YES];
}

- (void)resetCredentials
{
    [self _resetCredentials];
    [self _refreshNotify:YES];
}

- (void)dumpCredentials
{
    [self _dumpCredentials];
}

@end
