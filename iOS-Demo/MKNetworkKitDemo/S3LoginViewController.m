//
//  S3LoginViewController.m
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth Kumar on 15/4/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "S3LoginViewController.h"

@interface S3LoginViewController ()
@property (nonatomic, assign) IBOutlet UITextField *accessIdTextField;
@property (nonatomic, assign) IBOutlet UITextField *secretTextField;
@property (strong, nonatomic) MKS3Engine *s3Engine;
@end

@implementation S3LoginViewController
@synthesize accessIdTextField = _accessIdTextField;
@synthesize secretTextField = _secretTextField;
@synthesize s3Engine = _s3Engine;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.accessIdTextField.text = @"AKIAJ7EDMKR6PHAFMUEA";
  self.secretTextField.text = @"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";
  // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction)enumBucketsButtonTapped:(id)sender {
  
  self.s3Engine = [[MKS3Engine alloc] initWithAccessId:self.accessIdTextField.text 
                                             secretKey:self.secretTextField.text];
  
  [self.s3Engine enumerateBucketsOnSucceeded:^(NSMutableArray *listOfModelBaseObjects) {
    
  } onError:^(NSError *engineError) {
    DLog(@"%@", engineError);
  }];
  
  [self.s3Engine enumerateItemsAtPath:@""
                            onSucceeded:^(NSMutableArray *listOfModelBaseObjects) {
                              
                              DLog(@"%@", listOfModelBaseObjects);
                            } onError:^(NSError *engineError) {
                              DLog(@"%@", engineError);
                            }];
}

@end
