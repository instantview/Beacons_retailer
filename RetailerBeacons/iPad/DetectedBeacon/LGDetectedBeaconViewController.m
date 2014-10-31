//
//  LGDetectedBeaconViewController.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 22/08/2014.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "LGDetectedBeaconViewController.h"

@interface LGDetectedBeaconViewController () <UITextFieldDelegate, MBProgressHUDDelegate, CLLocationManagerDelegate> {
    MBProgressHUD *HUD;
}

@property (strong, nonatomic) NSMutableArray *knownBeacons;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;

@end

@implementation LGDetectedBeaconViewController

@synthesize beaconName;
@synthesize knownBeacons;
@synthesize detectedView;

NSString *const kUUID = @"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0";
NSString *const kDefaultBeaconName = @"Name this beacon";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
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
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:kUUID];
    
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
        //NSString *major = [NSString stringWithFormat:@"%@", foundBeacon.major];
        //NSString *minor = [NSString stringWithFormat:@"%@", foundBeacon.minor];
        
        NSLog(@"UUID: %@", uuid);
        NSLog(@"UUID: %@", [kUUID uppercaseString]);
        
        // have we seen this beacon before?
        if ([uuid isEqualToString:kUUID]){
            
            if (beacon.proximity == CLProximityNear || beacon.proximity == CLProximityImmediate){
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                
                [UIView animateWithDuration:0.5 animations:^() {
                    self.detectedView.alpha = 1.0f;
                }];
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

@end
