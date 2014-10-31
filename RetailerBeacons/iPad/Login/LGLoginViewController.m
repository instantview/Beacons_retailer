//
//  LGLoginViewController.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 01/09/2014.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import "MBProgressHUD/MBProgressHUD.h"
#import "LGLoginViewController.h"
#import "LGAllBeaconsTableViewController.h"

@interface LGLoginViewController () <UITextFieldDelegate, MBProgressHUDDelegate> {
    MBProgressHUD *HUD;
}

@end

@implementation LGLoginViewController

@synthesize inputEmail;
@synthesize inputPassword;
@synthesize containerView;
@synthesize message;

NSString *const kDefaultEmailInput = @"Email";
NSString *const kDefaultPasswordInput = @"Password";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
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
    self.view.backgroundColor = [UIColor colorWithRed:(247/255.0)
                                                green:(247/255.0)
                                                 blue:(247/255.0)
                                                alpha:1];
    self.inputEmail.delegate = self;
    self.inputPassword.delegate = self;
}

# pragma mark - Complete the login
- (IBAction)login:(id)sender
{
    if ([self.inputEmail.text isEqualToString:kDefaultEmailInput] || [self.inputEmail.text isEqualToString:@""])
    {
        [self setErrorMessageText:@"Please enter your email address"];
        return;
    }
    
    if (![self validEmail:self.inputEmail.text])
    {
        [self setErrorMessageText:@"Please enter a valid email address"];
        return;
    }
    
    if ([self.inputPassword.text isEqualToString:kDefaultPasswordInput] || [self.inputPassword.text isEqualToString:@""])
    {
        [self setErrorMessageText:@"Please enter your password"];
        return;
    }
    
    [self showLoginActivity];
    
    if (![self validLogin])
    {
        [self hideLoginActivity];
        [self setErrorMessageText:@"Incorrect login. Please try again."];
        
        self.containerView.hidden = NO;
    }
    else
    {
        LGAllBeaconsTableViewController *allBeacons = [[LGAllBeaconsTableViewController alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:allBeacons];
        navigation.navigationBar.backgroundColor = [UIColor yellowColor];
        
        self.view.window.rootViewController = navigation;
    }
    
}

- (void)setErrorMessageText:(NSString *)messageText
{
    self.message.textColor = [UIColor redColor];
    self.message.text = messageText;
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

- (BOOL)validLogin
{
    return YES;
}

- (void)showLoginActivity
{
    [self.view endEditing:YES];
    
    // Update the view to reflect the login process happening
    self.containerView.hidden = YES;
    
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
    if ([textField.text isEqualToString:kDefaultEmailInput] || [textField.text isEqualToString:kDefaultPasswordInput])
    {
        textField.text = @"";
    }
    
    if (textField.tag == 2)
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
            textField.text = kDefaultEmailInput;
        }
        
        if (textField.tag == 2)
        {
            textField.secureTextEntry = NO;
            textField.text = kDefaultPasswordInput;
        }
    }
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
