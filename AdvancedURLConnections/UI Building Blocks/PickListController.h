/*
    File:       PickListController.h

    Contains:   Runs a pick list table view.

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

@protocol PickListControllerDelegate;

@interface PickListController : NSObject
{
    NSArray *                       _pickList;
    BOOL                            _debug;
    id<PickListControllerDelegate>  _delegate;
    UIView *                        _topView;
    UITableView *                   _tableView;
}

@property (nonatomic, copy,   readonly)  NSArray *                      pickList;

@property (nonatomic, assign, readwrite) BOOL                           debug;
@property (nonatomic, assign, readwrite) id<PickListControllerDelegate> delegate;

- (id)initWithPickList:(NSArray *)pickList;                                         // array of NSString
- (id)initWithContentsOfFile:(NSString *)pickListFilePath;                          // path to plist file whose root object is an array of strings
- (id)initWithPickListNamed:(NSString *)pickListName bundle:(NSBundle *)bundle;     // name of plist file in bundle
    // bundle may be nil, in which case we find the file in the bundle containing this class

- (void)attachBelowView:(UIView *)topView;
    // Activates the pick list view as a peer of topView, but geometrically below it. 
    //
    // The pick list retains topView.  You must call detach to break this connection.
    //
    // IMPORTANT: If you call this with the keyboard visible, the pick list won't 
    // be laid out correctly.  It's expected that you call this with the keyboard 
    // hidden, or in the process of being shown, typically in the -textFieldDidBeginEditing: 
    // delegate callback of the text field whose value the user is picking.
    
- (void)detach;
    // Deactivates the pick list view.  It's safe to call this even if the pick list 
    // has not been attached.

@end

@protocol PickListControllerDelegate <NSObject>

@optional

- (void)pickList:(PickListController *)controller didPick:(NSString *)picked;
    // Called when the user pick something from the list.  The pick list is not 
    // deactivated automatically; the client must call -detach.

@end
