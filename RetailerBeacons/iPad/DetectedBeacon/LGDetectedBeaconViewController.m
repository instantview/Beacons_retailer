//
//  LGDetectedBeaconViewController.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 22/08/2014.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "AFNetworking.h"
#import "Constants.h"
#import "UIColor+UIColorCategory.h"
#import "LGDetectedBeaconViewController.h"

@interface LGDetectedBeaconViewController () <
	UITextFieldDelegate,
	UINavigationControllerDelegate,
	UIImagePickerControllerDelegate,
	MBProgressHUDDelegate,
	CLLocationManagerDelegate>
{
    MBProgressHUD *HUD;
}

@property (strong, nonatomic) NSMutableArray *knownBeacons;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) NSString *foundUUID;
@property (strong, nonatomic) UIImage *beaconImage;

@end

@implementation LGDetectedBeaconViewController

@synthesize beaconName;
@synthesize knownBeacons;
@synthesize detectedView;
@synthesize foundUUID;
@synthesize beaconImage;
@synthesize buttonTakePhoto;

NSString *const kDefaultBeaconName = @"Name this beacon";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self){
        self.view.backgroundColor = [UIColor colorWithHexString:@"0xEEEEEE"];
        self.navigationItem.title = @"Add New Product";
        self.detectedView.alpha = 0.0f;
        self.beaconName.delegate = self;
		
        [self lookForBeacons];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)lookForBeacons
{
    // Show an activity indicator
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	HUD.delegate = self;
    HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.labelText = @"Searching";
	HUD.detailsLabelText = @"Place your beacon next to the iPad";
    
    // Look for beacons here
	[HUD show:YES];
    
    self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
	
	[self.locationManager requestAlwaysAuthorization];
	
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:kInstantViewUUID];
    
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"com.beacons.instantview"];
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
    self.beaconRegion.notifyOnEntry = YES;
    self.beaconRegion.notifyOnExit = YES;
	
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"Entered region...");
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Exited region...");
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    for (CLBeacon *beacon in beacons){
        
        NSString *uuid = beacon.proximityUUID.UUIDString;
		NSString *beaconID = [NSString stringWithFormat:@"%@|%@|%@", beacon.proximityUUID.UUIDString, beacon.major, beacon.minor];
        
        // have we seen this beacon before?
        if ([uuid isEqualToString:kInstantViewUUID]){
            if (beacon.proximity == CLProximityNear || beacon.proximity == CLProximityImmediate){
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                
                [UIView animateWithDuration:0.5 animations:^() {
                    self.detectedView.alpha = 1.0f;
                }];
				
				self.foundUUID = beaconID;

				[self.locationManager stopMonitoringForRegion:self.beaconRegion];
				[self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
            }
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([textField.text isEqualToString:kDefaultBeaconName]){
        textField.text = @"";
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)buttonTakePhoto:(id)sender
{
	UIImagePickerController *imagePickerController = [UIImagePickerController new];
	imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
	imagePickerController.delegate = self;
	imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
	
	[self presentViewController:imagePickerController animated:NO completion:nil];
}

- (IBAction)buttonSaveBeacon:(id)sender
{
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.labelText = @"Saving";
	HUD.detailsLabelText = @"Adding new beacon...";
	
	[HUD show:YES];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *userId = [userDefaults objectForKey:@"guid"];
	
	NSString *url = [NSString stringWithFormat:@"%@/product/addNewBeacon", kBaseAPIUrl];
	NSDictionary *params = @{
							 @"UserGUID" : userId,
							 @"manufacturer" : @"InstantView",
							 @"productName" : self.beaconName.text,
							 @"availableStock": @"0",
							 @"numberOfVisits": @"0",
							 @"price": @"0.00",
							 @"UUID" : self.foundUUID};
	
	[[AFHTTPSessionManager manager] POST:url
							  parameters:params
								 success:^(NSURLSessionDataTask *task, id responseObject) {
									
									 [self addNewOffer:[responseObject objectForKey:@"UUID"]];
									 
								 } failure:^(NSURLSessionDataTask *task, NSError *error) {
									 
									 NSLog(@"Fail: %@", error);
									 
									 HUD.mode = MBProgressHUDModeText;
									 HUD.labelText = @"Server error";
									 HUD.detailsLabelText = @"Please try again.";
									 
									 [HUD hide:YES afterDelay:2];
									 
								 }];
	
}

- (void)addNewOffer:(NSString *)uuid
{
	HUD.mode = MBProgressHUDModeText;
	HUD.detailsLabelText = @"Creating new offer...";
	
	NSString *url = [NSString stringWithFormat:@"%@/offer/addProductOffer", kBaseAPIUrl];
	NSDictionary *params = @{@"beaconUUID" : self.foundUUID};
	
	[[AFHTTPSessionManager manager] POST:url
							  parameters:params
								 success:^(NSURLSessionDataTask *task, id responseObject) {
									 
									 NSLog(@"Added offer...");
									 NSLog(@"%@", responseObject);
									 
								 } failure:^(NSURLSessionDataTask *task, NSError *error) {
									 
									 NSLog(@"Fail: %@", error);
									 
									 HUD.mode = MBProgressHUDModeText;
									 HUD.labelText = @"Server error";
									 HUD.detailsLabelText = @"Please try again.";
									 
									 [HUD hide:YES afterDelay:2];
									 
								 }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[self dismissViewControllerAnimated:YES completion:nil];
	
	self.beaconImage = [info objectForKey:UIImagePickerControllerOriginalImage];
	self.buttonTakePhoto.titleLabel.text = @"Done!";
}

@end
