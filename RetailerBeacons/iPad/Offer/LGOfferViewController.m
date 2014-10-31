//
//  LGOfferViewController.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 8/26/14.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import "LGOfferViewController.h"

@interface LGOfferViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@implementation LGOfferViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)uploadPhoto:(id)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"User cancelled picking a photo...");
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)setup
{
    self.navigationItem.title = @"Samsung TV's";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
