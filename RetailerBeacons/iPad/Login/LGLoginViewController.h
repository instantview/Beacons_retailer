//
//  LGLoginViewController.h
//  RetailerBeacons
//
//  Created by Matt Richardson on 01/09/2014.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LGLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITextField *inputEmail;
@property (weak, nonatomic) IBOutlet UITextField *inputPassword;

- (IBAction)login:(id)sender;

@end
