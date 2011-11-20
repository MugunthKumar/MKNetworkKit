//
//  ViewController.m
//  MKNetworkKit
//
//  Created by Mugunth Kumar on 7/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
@synthesize engine = _engine;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSMutableDictionary *headerFields = [NSMutableDictionary dictionary]; 
    [headerFields setValue:@"iOS" forKey:@"x-client-identifier"];
    
    self.engine = [[YahooEngine alloc] initWithHostName:@"download.finance.yahoo.com" 
                       customHeaderFields:headerFields];

/*    
    [self.engine currencyRateFor:@"SGD" 
                 inCurrency:@"INR" 
               onCompletion:^(double rate) {
                                           
                   DLog(@"%f", rate);
               } 
                    onError:^(NSError* error) {
                        
                        
                        DLog(@"%@\t%@\t%@\t%@", [error localizedDescription], [error localizedFailureReason], 
                             [error localizedRecoveryOptions], [error localizedRecoverySuggestion]);
                    }];
 */

    [self.engine useCache];
    
    [self.engine uploadImageFromFile];
    //[self.engine uploadImageFromFile];
    //[self.engine uploadImageFromFile];

    //[self.engine uploadImageFromData];        
    
    //[self.engine downloadFatAssFileTo:@"A.pdf"];
    //[self.engine downloadFatAssFileTo:@"B.pdf"];
    //[self.engine downloadFatAssFileTo:@"C.pdf"];

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.engine = nil;
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
