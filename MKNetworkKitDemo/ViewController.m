//
//  ViewController.m
//  MKNetworkKit
//
//  Created by Mugunth Kumar on 7/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "UIAlertView+MKNetworkKitAdditions.h"

@implementation ViewController

@synthesize uploadOperation = _uploadOperation;
@synthesize downloadOperation = _downloadOperation;
@synthesize currencyOperation = _currencyOperation;

@synthesize downloadProgessBar = _downloadProgessBar;
@synthesize uploadProgessBar = _uploadProgessBar;

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
    self.downloadProgessBar = nil;
    self.uploadProgessBar = nil;
}

-(void) viewDidDisappear:(BOOL)animated {
    
    if(self.currencyOperation) {
        
        [self.currencyOperation cancel];
        self.currencyOperation = nil;
    }

    // upload and download operations are expected to run in background even when view disappears
}

-(IBAction)convertCurrencyTapped:(id)sender {
    
    self.currencyOperation = [ApplicationDelegate.engine currencyRateFor:@"SGD" 
                      inCurrency:@"USD" 
                    onCompletion:^(double rate) {
                        
                        DLog(@"%f", rate);
                    } 
                         onError:^(NSError* error) {
                             
                             
                             DLog(@"%@\t%@\t%@\t%@", [error localizedDescription], [error localizedFailureReason], 
                                  [error localizedRecoveryOptions], [error localizedRecoverySuggestion]);
                         }];    
}

-(IBAction)uploadImageTapped:(id)sender {
    
    self.uploadOperation = [ApplicationDelegate.uploader uploadImageFromFile:@"/Users/mugunth/Desktop/transit.png"];    
    
    [self.uploadOperation onUploadProgressChanged:^(double progress) {
        
        DLog(@"%.2f", progress*100.0);
        self.uploadProgessBar.progress = progress;
    }];
    
    [self.uploadOperation onCompletion:^(MKNetworkOperation* completedRequest) {
        
        DLog(@"%@", completedRequest);        
    }
             onError:^(NSError* error) {

                 [UIAlertView showWithError:error];
             }];
}

-(IBAction)downloadFileTapped:(id)sender {
    
    self.downloadOperation = [ApplicationDelegate.downloader downloadFatAssFileFrom:@"http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURLRequest_Class/NSURLRequest_Class.pdf" 
                                                              toFile:@"/Users/mugunth/Desktop/a.pdf"]; 
    
    [self.downloadOperation onDownloadProgressChanged:^(double progress) {
        
        DLog(@"%.2f", progress*100.0);
        self.downloadProgessBar.progress = progress;
    }];
    
    [self.downloadOperation onCompletion:^(MKNetworkOperation* completedRequest) {
        
        DLog(@"%@", completedRequest);        
    }
             onError:^(NSError* error) {
                 
                 DLog(@"%@", error);
             }];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
