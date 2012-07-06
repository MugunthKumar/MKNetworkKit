/*
    File:       ClientIdentityController.h

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

#import <UIKit/UIKit.h>

// You typically run this view controller by:
//
// 1. creating it with an authentication challenge
// 2. setting yourself as the delegate
// 3. presenting it modally
//
// When the user taps an identity (in the table) or Cancel, your 
// -identityView:didChooseIdentity: delegate callback will be called.  If identity 
// is NULL, it was a Cancel. 
//
// Finally, dismiss the view controller.  -identityViewDidDisappear: will be 
// called when it's all gone.
//
// By default this module gets its list of identities from the keychain.  
// You can optionally implement the -identityViewIdentitiesToDisplay: delegate 
// method to provide a custom list.

// IMPORTANT: This is not a subclass of UITableViewController because the table 
// view does not occupy the whole screen.  This means that we must emulate certain 
// aspects of UITableViewController in our own code (which is not too onerous; 
// UITableViewController is pretty lightweight).

@protocol ClientIdentityControllerDelegate;

@interface ClientIdentityController : UIViewController
{
    UITableView *                           _identityTable;
    
    NSURLAuthenticationChallenge *          _challenge;
    id<ClientIdentityControllerDelegate>    _delegate;
    SecIdentityRef                          _chosenIdentity;
    NSArray *                               _identities;
}

- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge;

@property (nonatomic, retain, readwrite) IBOutlet UITableView *                 identityTable;

- (IBAction)cancelAction:(id)sender;

@property (nonatomic, assign, readonly)  NSURLAuthenticationChallenge *         challenge;
    // This is the challenge passed to -initWithChallenge:.

@property (nonatomic, assign, readwrite) id<ClientIdentityControllerDelegate>   delegate;

@property (nonatomic, assign, readonly)  SecIdentityRef                         chosenIdentity;
    // The identity chosen by the user.  This will be NULL if the taps Cancel, or 
    // if prior to the -identityView:didChooseIdentity: delegate callback.
    //
    // IMPORTANT: chosenIdentity is not retained.  Rather, it's always an element of 
    // identities, which is responsible for keeping it around.  identities never changes 
    // for the lifetime of the object, which is good.  However, this design choice means 
    // that, if you want to hold on to chosenIdentity after releasing the 
    // ClientIdentityController object, you must retain it yourself.

@end

@protocol ClientIdentityControllerDelegate <NSObject>

@required

- (void)identityView:(ClientIdentityController *)controller didChooseIdentity:(SecIdentityRef)identity;
    // Called by ClientIdentityController when the user either taps Cancel or 
    // an identity.  identity will be NULL in the cancel case.

@optional

- (void)identityViewDidDisappear:(ClientIdentityController *)controller;
    // Called by ClientIdentityController when the view disappears.

- (NSArray *)identityViewIdentitiesToDisplay:(ClientIdentityController *)controller;
    // Called by ClientIdentityController when it wants to know the list of 
    // identities to display.  If you don't implement this method, or your 
    // implementation returns nil, the controller internally generates a list 
    // of all identities from the keychain.

@end
