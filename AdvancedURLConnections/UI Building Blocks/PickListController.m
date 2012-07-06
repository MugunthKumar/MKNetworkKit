/*
    File:       PickListController.m

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

#import "PickListController.h"

@interface PickListController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, retain, readwrite) UIView *       topView;
@property (nonatomic, retain, readwrite) UITableView *  tableView;
@end

@implementation PickListController

@synthesize pickList = _pickList;

@synthesize debug    = _debug;
@synthesize delegate = _delegate;

@synthesize topView   = _topView;
@synthesize tableView = _tableView;

- (id)initWithPickList:(NSArray *)pickList
    // See comment in header.
{
    assert(pickList != nil);
    assert([pickList count] != 0);
    self = [super init];
    if (self != nil) {
        self->_pickList = [pickList copy];
        assert(self->_pickList != nil);
    }
    return self;
}

- (id)initWithContentsOfFile:(NSString *)pickListFilePath
    // See comment in header.
{
    NSArray *       pickListArray;
    
    assert(pickListFilePath != nil);
    
    pickListArray = [NSArray arrayWithContentsOfFile:pickListFilePath];
    assert([pickListArray isKindOfClass:[NSArray class]]);
    
    return [self initWithPickList:pickListArray];
}

- (id)initWithPickListNamed:(NSString *)pickListName bundle:(NSBundle *)bundle
    // See comment in header.
{
    NSString *      pickListPath;
    
    assert(pickListName != nil);
    // bundleName may be nil
    
    if (bundle == nil) {
        bundle = [NSBundle bundleForClass:[self class]];
        assert(bundle != nil);
    }
    
    pickListPath = [bundle pathForResource:pickListName ofType:@"plist"];
    assert(pickListPath != nil);

    return [self initWithContentsOfFile:pickListPath];
}

- (void)dealloc
{
    [self->_pickList release];
    assert(self->_topView == nil);
    assert(self->_tableView == nil);
    [super dealloc];
}

#pragma mark * Attach and detach

- (CGRect)tableViewFrame
    // Calculates the frame for the pick list based on the coordinates of the top 
    // view and the size of the containing view (that is, the top view's superview, 
    // which will also be the pick list's superview).
{
    CGRect      topViewFrame;
    CGRect      containerViewBounds;
    CGRect      frame;

    topViewFrame = self.topView.frame;
    containerViewBounds = self.topView.superview.bounds;
    
    frame.origin.x    = containerViewBounds.origin.x;
    frame.origin.y    = topViewFrame.origin.y + topViewFrame.size.height;
    frame.size.height = containerViewBounds.size.height - (topViewFrame.origin.y + topViewFrame.size.height);
    frame.size.width  = containerViewBounds.size.width;

    return frame;
}

- (void)attachBelowView:(UIView *)topView
    // See comment in header.
{
    assert(topView != nil);
    
    assert(self.topView == nil);        // don't try and attach twice!
    self.topView = topView;
    
    assert(self.tableView == nil);

    // Create and configure the table view and add it to the view hierarchy.

    self.tableView = [[[UITableView alloc] initWithFrame:[self tableViewFrame] style:UITableViewStylePlain] autorelease];

    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (self.debug) {
        self.tableView.backgroundColor = [UIColor yellowColor];
    }

    self.tableView.dataSource = self;
    self.tableView.delegate   = self;
    
    // We place the view /under/ the top view.  This is necessary so that the top view masks 
    // any new table view cells as they are being inserted at the top of the table (in the case 
    // where we do an animated grow of the table in response to a keyboard hide).  If you change 
    // the YES to a NO, the new cells show on top of the top view, resulting in a very ugly effect.
    
    if (YES) {
        [self.topView.superview insertSubview:self.tableView belowSubview:self.topView];
    } else {
        [self.topView.superview addSubview:self.tableView];
    }
    
    [self.tableView flashScrollIndicators];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow: ) name:UIKeyboardDidShowNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)detach
    // See comment in header.
{
    if (self.tableView != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification  object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

        self.topView = nil;

        self.tableView.delegate = nil;
        self.tableView.dataSource = nil;
        [self.tableView removeFromSuperview];
        self.tableView = nil;
    }
}

#pragma mark * Keyboard handling

- (BOOL)beginAnimationFromKeyboardNotification:(NSNotification *)note
    // Start an animated block based on the keyboard animation information 
    // in the notification.  Returns NO if the animation information is 
    // missing (such as after a rotate).
{
    BOOL                    animated;
    NSDictionary *          userInfo;
    NSNumber *              durationObj;
    NSNumber *              curveObj;
    NSTimeInterval          duration;
    UIViewAnimationCurve    curve;

    userInfo = [note userInfo];
    assert(userInfo != nil);
    
    animated = NO;
    
    durationObj = (NSNumber *) [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    curveObj    = (NSNumber *) [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey   ];
    
    if ( (durationObj != nil) && (curveObj != nil) ) {
        assert([durationObj isKindOfClass:[NSNumber class]]);
        assert([curveObj isKindOfClass:[NSNumber class]]);

        duration = (NSTimeInterval)       [durationObj doubleValue];
        curve    = (UIViewAnimationCurve) [curveObj    unsignedIntegerValue];

        [UIView beginAnimations:[note name] context:nil];
        [UIView setAnimationCurve:curve];
        [UIView setAnimationDuration:duration];
        
        animated = YES;
    }

    return animated;
}

- (void)keyboardDidShow:(NSNotification *)note
    // A notification callback, called when the keyboard is shown.  We recalculate 
    // the size of the pick list table view to fit between the bottom of the top 
    // view and the top of the keyboard.
{
    NSDictionary *          userInfo;
    CGRect                  keyboardFrameEnd;                           // screen coordinates
    CGRect                  keyboardFrameEndInContainerViewCoordinates; // in the coordinate space of the view that contains 
    CGRect                  newTableViewFrame;                          // the table view (and the top view for that matter)
    BOOL                    animated;

    userInfo = [note userInfo];
    assert(userInfo != nil);

    assert([[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] isKindOfClass:[NSValue  class]]);
    keyboardFrameEnd = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    keyboardFrameEndInContainerViewCoordinates = [self.tableView.superview convertRect:keyboardFrameEnd fromView:nil];

    if (self.debug) {
        NSLog(@"-keyboardDidShow:");
        NSLog(@"   keyboard in screen coordinates %@", NSStringFromCGRect(keyboardFrameEnd));
        NSLog(@"keyboard in container coordinates %@", NSStringFromCGRect(keyboardFrameEndInContainerViewCoordinates));
        NSLog(@"                table view bounds %@", NSStringFromCGRect(self.tableView.bounds));
    }
    
    if ( CGRectIntersectsRect(self.tableView.frame, keyboardFrameEndInContainerViewCoordinates) ) {
        newTableViewFrame = self.tableView.frame;
        newTableViewFrame.size.height = keyboardFrameEndInContainerViewCoordinates.origin.y - newTableViewFrame.origin.y;

        if (self.debug) {
            NSLog(@"           table view frame start %@", NSStringFromCGRect(self.tableView.frame));
            NSLog(@"             table view frame end %@", NSStringFromCGRect(newTableViewFrame));
        }
        animated = [self beginAnimationFromKeyboardNotification:note];
        self.tableView.frame = newTableViewFrame;
        if (animated) {
            [UIView commitAnimations];
        }
        [self.tableView flashScrollIndicators];
    }
}

- (void)keyboardWillHide:(NSNotification *)note
    // A notification callback, called when the keyboard is hidden.  We revert the 
    // pick list table view to its default size.
{
    #pragma unused(note)
    CGRect  newTableViewFrame;
    BOOL    animated;

    newTableViewFrame = [self tableViewFrame];
    
    if (self.debug) {
        NSLog(@"-keyboardWillHide:");
        NSLog(@"           table view frame start %@", NSStringFromCGRect(self.tableView.frame));
        NSLog(@"             table view frame end %@", NSStringFromCGRect(newTableViewFrame));
    }
    animated = [self beginAnimationFromKeyboardNotification:note];
    self.tableView.frame = newTableViewFrame;
    if (animated) {
        [UIView commitAnimations];
    }
    [self.tableView flashScrollIndicators];
}

#pragma mark * Table view callbacks

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tv)
    #pragma unused(section)
    assert(tv == self.tableView);
    assert(section == 0);

    return [self.pickList count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)
    UITableViewCell *	cell;

    assert(tv == self.tableView);
    assert(indexPath != nil);
    assert(indexPath.section == 0);
    assert(indexPath.row < [self.pickList count]);

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"] autorelease];
        assert(cell != nil);

        cell.textLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    }
    cell.textLabel.text = [self.pickList objectAtIndex:indexPath.row];

    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    assert(tv == self.tableView);
    assert(indexPath != nil);
    assert(indexPath.section == 0);
    assert(indexPath.row < [self.pickList count]);

    if ([self.delegate respondsToSelector:@selector(pickList:didPick:)]) {
        // It's likely that the client is going to release its reference to us in 
        // response to to this callback, so we ensure that our reference to self 
        // persists while everything shuts down.
        //
        // This also means we don't have to copy the item from the pickList array; we 
        // retain that array until we're deallocated, and we aren't be deallocated until 
        // the autorelease pool drains.

        [[self retain] autorelease];

        [self.delegate pickList:self didPick:[self.pickList objectAtIndex:indexPath.row]];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
