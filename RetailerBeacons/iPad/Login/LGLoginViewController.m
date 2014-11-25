//
//  LGLoginViewController.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 01/09/2014.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import "MBProgressHUD/MBProgressHUD.h"
#import "LGLoginViewController.h"
#import "LGAllBeaconsViewController.h"
#import "LGRegisterViewController.h"
#import "UIColor+UIColorCategory.h"
#import "AFNetworking.h"
#import "Constants.h"

@interface LGLoginViewController () <UITextFieldDelegate, MBProgressHUDDelegate> {
    MBProgressHUD *HUD;
}

@end

@implementation LGLoginViewController

@synthesize inputEmail;
@synthesize inputPassword;
@synthesize containerView;
@synthesize message;
@synthesize buttonLogin;

NSString *const kDefaultEmailInput = @"Email";
NSString *const kDefaultPasswordInput = @"Password";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self){
        [self setup];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)setup
{
	self.view.backgroundColor = [UIColor colorWithHexString:@"0x222222"];
    self.inputEmail.delegate = self;
    self.inputPassword.delegate = self;
	
	self.containerView.layer.borderWidth = 1.0f;
	self.containerView.layer.borderColor = [UIColor colorWithHexString:@"0xEEEEEE"].CGColor;
	
	self.buttonLogin.backgroundColor = [UIColor yellowColor];
	self.buttonLogin.layer.cornerRadius = 5.0f;
	self.buttonLogin.tintColor = [UIColor brownColor];
}

# pragma mark - Complete the login
- (IBAction)login:(id)sender
{
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.labelText = @"Logging in...";
	HUD.delegate = self;
	
	[HUD show:YES];
	
    if ([self.inputEmail.text isEqualToString:kDefaultEmailInput] || [self.inputEmail.text isEqualToString:@""]){
        [self setErrorMessageText:@"Please enter your email address"];
        return;
    }
    
    if (![self validEmail:self.inputEmail.text]){
        [self setErrorMessageText:@"Please enter a valid email address"];
        return;
    }
    
    if ([self.inputPassword.text isEqualToString:kDefaultPasswordInput] || [self.inputPassword.text isEqualToString:@""]){
        [self setErrorMessageText:@"Please enter your password"];
        return;
    }
    
    [self showLoginActivity];
    
    if (![self validLogin]){
        [self hideLoginActivity];
        [self setErrorMessageText:@"Incorrect login. Please try again."];
        
        self.containerView.hidden = NO;
    }
    else
    {
		NSLog(@"%@", kBaseAPIUrl);
		
		NSString *url = [NSString stringWithFormat:@"%@/user/UserLogin", kBaseAPIUrl];
		
		AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
		manager.responseSerializer = [AFJSONResponseSerializer serializer];
		
		NSDictionary *params = @{@"email" : self.inputEmail.text, @"password" : self.inputPassword.text};
		
		[manager POST:url
		   parameters:params
			  success:^(AFHTTPRequestOperation *operation, id responseObject){
				  
				  if ([responseObject objectForKey:@"guid"]){
					  
					  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
					  [defaults setValue:responseObject[@"guid"] forKey:@"guid"];
					  
					  // When the login has been successful
					  LGAllBeaconsViewController *allBeacons = [LGAllBeaconsViewController new];
					  UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:allBeacons];
					  navigation.navigationBar.backgroundColor = [UIColor blackColor];
					  navigation.navigationBar.tintColor = [UIColor yellowColor];
					  navigation.navigationBar.barTintColor = [UIColor blackColor];
					  navigation.navigationBar.barStyle = UIBarStyleBlackOpaque;
					  navigation.navigationBar.opaque = YES;
					  
					  self.view.window.rootViewController = navigation;
					  
				  } else {
					  
					  NSLog(@"Couldn't log you in %@", responseObject[@"message"]);
					  
					  HUD.mode = MBProgressHUDModeText;
					  HUD.labelText =  [NSString stringWithFormat:@"Incorrect Login"];
					  HUD.detailsLabelText = @"Please try again.";
					  
					  [HUD hide:YES afterDelay:2];
					  
				  }
				  
			  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				  
				  HUD.mode = MBProgressHUDModeText;
				  HUD.labelText =  [NSString stringWithFormat:@"Server error"];
				  HUD.detailsLabelText = @"Please try again.";
				  
				  [HUD hide:YES afterDelay:2];
				
				  NSLog(@"Failure: %@", error);
			  }];
    }
    
}

- (IBAction)createAccount:(id)sender
{
	NSLog(@"Create account...");
	
	LGRegisterViewController *createAccount = [LGRegisterViewController new];
	
	[self presentViewController:createAccount animated:NO completion:nil];
}

- (void)setErrorMessageText:(NSString *)messageText
{
    self.message.textColor = [UIColor redColor];
    self.message.text = messageText;
}

- (BOOL)validEmail:(NSString*) emailString
{
    if([emailString length]==0){
        return NO;
    }
    
    NSString *regExPattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:regExPattern
																	  options:NSRegularExpressionCaseInsensitive
																		error:nil];
    NSUInteger regExMatches = [regEx numberOfMatchesInString:emailString
													 options:0
													   range:NSMakeRange(0, [emailString length])];
    
    if (regExMatches == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validLogin
{
    return YES;
}

- (void)showLoginActivity
{
    [self.view endEditing:YES];
	
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	HUD.delegate = self;
    HUD.mode = MBProgressHUDModeIndeterminate;
    
	[HUD show:YES];
}

- (void)hideLoginActivity
{
    [HUD show:NO];
}

# pragma mark - UI Text Field Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([textField.text isEqualToString:kDefaultEmailInput] || [textField.text isEqualToString:kDefaultPasswordInput]){
        textField.text = @"";
		textField.keyboardType = UIKeyboardTypeEmailAddress;
    }
    
    if (textField.tag == 2){
        textField.secureTextEntry = YES;
		textField.keyboardType = UIKeyboardTypeDefault;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField.text isEqualToString:@""]){
		
        if (textField.tag == 1){
            textField.text = kDefaultEmailInput;
        }
        
        if (textField.tag == 2){
            textField.secureTextEntry = NO;
            textField.text = kDefaultPasswordInput;
        }
		
    }
}

- (BOOL)isModal {
	return self.presentingViewController.presentedViewController == self
	|| self.navigationController.presentingViewController.presentedViewController == self.navigationController
	|| [self.tabBarController.presentingViewController isKindOfClass:[UITabBarController class]];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
