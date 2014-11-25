//
//  LGRegisterViewController.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 9/26/14.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>
#import "LGRegisterViewController.h"
#import "LGAllBeaconsViewController.h"
#import "UIColor+UIColorCategory.h"
#import "Constants.h"
#import "AFNetworking.h"

@interface LGRegisterViewController () <UITextFieldDelegate, MBProgressHUDDelegate> {
	MBProgressHUD *HUD;
}

@property (nonatomic) UITextField *inputName;
@property (nonatomic) UITextField *inputEmail;
@property (nonatomic) UITextField *inputPassword;
@property (nonatomic) UITextField *inputPhone;
@property (nonatomic) UIButton *buttonCreateAccount;
@property (nonatomic) UILabel *messageText;

@end

@implementation LGRegisterViewController

@synthesize inputEmail;
@synthesize inputName;
@synthesize inputPassword;
@synthesize inputPhone;
@synthesize buttonCreateAccount;
@synthesize messageText;

NSString *const kInputNameDefault = @"Full Name";
NSString *const kInputEmailDefault = @"Email";
NSString *const kInputPasswordDefault = @"Password";
NSString *const kInputPhoneDefault = @"Phone";

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (self){
		[self setup];
	}
	
	return self;
}

- (void)setup
{
	self.view.backgroundColor = [UIColor colorWithHexString:@"0x222222"];
	
	UIImage *shopIcon = [UIImage imageNamed:@"shop"];
	UIImageView *iconView = [[UIImageView alloc] initWithImage:shopIcon];
	iconView.frame = CGRectMake((self.view.frame.size.width / 2) - 64, 40, 128, 128);
	iconView.contentMode = UIViewContentModeScaleAspectFill;
	
	[self.view addSubview:iconView];
	
	UIButton *button = [UIButton new];
	button.frame = CGRectMake((self.view.frame.size.width / 2) - 125, 190, 250, 40);
	button.tintColor = [UIColor greenColor];
	button.titleLabel.tintColor = [UIColor greenColor];
	button.titleLabel.font = [UIFont systemFontOfSize:15.0f];
	
	[button setTitle:@"Already registered? Login here" forState:UIControlStateNormal];
	[button addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
	
	[self.view addSubview:button];
	[self.view bringSubviewToFront:button];
	
	UIView *containerView = [UIView new];
	containerView.backgroundColor = [UIColor whiteColor];
	containerView.frame = CGRectMake((self.view.frame.size.width / 2) - 192, 250, 384, 300);
	containerView.layer.borderWidth = 1.0f;
	containerView.layer.borderColor = [UIColor colorWithHexString:@"0xEEEEEE"].CGColor;
	
	[self.view addSubview:containerView];
	
	self.messageText = [UILabel new];
	self.messageText.frame = CGRectMake((self.view.frame.size.width / 2) - 172, 270, 344, 30);
	self.messageText.font = [UIFont systemFontOfSize:16.0f];
	self.messageText.text = @"Add your details";
	self.messageText.textAlignment = NSTextAlignmentCenter;
	
	[self.view addSubview:self.messageText];
	
	// Name field
	self.inputName = [UITextField new];
	self.inputName.frame = CGRectMake((self.view.frame.size.width / 2) - 172, 320, 344, 30);
	self.inputName.borderStyle = UITextBorderStyleRoundedRect;
	self.inputName.text = kInputNameDefault;
	self.inputName.font = [UIFont systemFontOfSize:14.0f];
	self.inputName.delegate = self;
	self.inputName.tag = 1;
	
	// Phone number field
	self.inputPhone = [UITextField new];
	self.inputPhone.frame = CGRectMake((self.view.frame.size.width / 2) - 172, 370, 344, 30);
	self.inputPhone.borderStyle = UITextBorderStyleRoundedRect;
	self.inputPhone.text = kInputPhoneDefault;
	self.inputPhone.font = [UIFont systemFontOfSize:14.0f];
	self.inputPhone.delegate = self;
	self.inputPhone.tag = 2;
	
	// Email field
	self.inputEmail = [UITextField new];
	self.inputEmail.frame = CGRectMake((self.view.frame.size.width / 2) - 172, 420, 344, 30);
	self.inputEmail.borderStyle = UITextBorderStyleRoundedRect;
	self.inputEmail.text = kInputEmailDefault;
	self.inputEmail.font = [UIFont systemFontOfSize:14.0f];
	self.inputEmail.delegate = self;
	self.inputEmail.tag = 3;
	
	// Password field
	self.inputPassword = [UITextField new];
	self.inputPassword.frame = CGRectMake((self.view.frame.size.width / 2) - 172, 470, 344, 30);
	self.inputPassword.borderStyle = UITextBorderStyleRoundedRect;
	self.inputPassword.text = kInputPasswordDefault;
	self.inputPassword.font = [UIFont systemFontOfSize:14.0f];
	self.inputPassword.delegate = self;
	self.inputPassword.tag = 4;
	
	[self.view addSubview:self.inputPhone];
	[self.view addSubview:self.inputName];
	[self.view addSubview:self.inputEmail];
	[self.view addSubview:self.inputPassword];
	
	// Create Account button
	self.buttonCreateAccount = [UIButton new];
	self.buttonCreateAccount.frame = CGRectMake((self.view.frame.size.width / 2) - 192, 570, 384, 50);
	self.buttonCreateAccount.backgroundColor = [UIColor yellowColor];
	self.buttonCreateAccount.backgroundColor = [UIColor yellowColor];
	self.buttonCreateAccount.layer.cornerRadius = 5.0f;
	self.buttonCreateAccount.titleLabel.font = [UIFont systemFontOfSize:15.0f];
	
	[self.buttonCreateAccount setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
	[self.buttonCreateAccount setTitle:@"Create Account" forState:UIControlStateNormal];
	[self.buttonCreateAccount addTarget:self action:@selector(createAccount) forControlEvents:UIControlEventTouchUpInside];
	
	[self.view addSubview:self.buttonCreateAccount];
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if ([textField.text isEqualToString:kInputEmailDefault] ||
		[textField.text isEqualToString:kInputNameDefault] ||
		[textField.text isEqualToString:kInputPasswordDefault] ||
		[textField.text isEqualToString:kInputPhoneDefault])
	{
		textField.text = @"";
	}
	
	if (textField.tag == 4)
	{
		textField.secureTextEntry = YES;
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if ([textField.text isEqualToString:@""])
	{
		if (textField.tag == 1)
		{
			textField.text = kInputNameDefault;
		}
		
		if (textField.tag == 2)
		{
			textField.text = kInputPhoneDefault;
		}
		
		if (textField.tag == 3)
		{
			textField.text = kInputEmailDefault;
		}
		
		if (textField.tag == 4)
		{
			textField.secureTextEntry = NO;
			textField.text = kInputPasswordDefault;
		}
	}
}

- (void)showActivity
{
	[self.view endEditing:YES];
	
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeIndeterminate;
	
	[HUD show:YES];
}

- (void)hideActivity
{
	[HUD show:NO];
}

- (void)login
{
	NSLog(@"Disappear....");
	
	[self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)createAccount
{
	[self showActivity];
	
	NSString *url = [NSString stringWithFormat:@"%@/user/RequestUserAccount", kBaseAPIUrl];
	
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFJSONResponseSerializer serializer];
	
	NSDictionary *params = @{@"name" : self.inputName.text,
							 @"password" : self.inputPassword.text,
							 @"email" : self.inputEmail.text,
							 @"telephone" : self.inputPhone.text,
							 @"level": @"1"};
	
	[manager POST:url
	   parameters:params
		  success:^(AFHTTPRequestOperation *operation, id responseObject){
			  
			  NSLog(@"%@", responseObject);
			  
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

- (BOOL)validEmail:(NSString*) emailString
{
	if([emailString length]==0)
	{
		return NO;
	}
	
	NSString *regExPattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
	NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:regExPattern options:NSRegularExpressionCaseInsensitive error:nil];
	NSUInteger regExMatches = [regEx numberOfMatchesInString:emailString options:0 range:NSMakeRange(0, [emailString length])];
	
	if (regExMatches == 0) {
		return NO;
	}
	
	return YES;
}


- (BOOL)prefersStatusBarHidden
{
	return YES;
}

@end
