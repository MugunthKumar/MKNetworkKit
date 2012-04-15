//
//  S3ViewController.m
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth Kumar on 15/4/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "S3ViewController.h"

@interface S3ViewController ()
@property (nonatomic, assign) IBOutlet UITextField *accessIdTextField;
@property (nonatomic, assign) IBOutlet UITextField *secretTextField;
@property (strong, nonatomic) MKS3Engine *s3Engine;
@end

@implementation S3ViewController
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

-(IBAction)loginButtonTapped:(id)sender {
  
  self.s3Engine = [[MKS3Engine alloc] initWithAccessId:self.accessIdTextField.text 
                                             secretKey:self.secretTextField.text];
  
}

-(IBAction)enumBucketsButtonTapped:(id)sender {
  
}

@end
