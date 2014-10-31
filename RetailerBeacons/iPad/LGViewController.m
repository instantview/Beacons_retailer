//
//  LGViewController.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 21/08/2014.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "LGViewController.h"
#import "LGMenuViewController.h"

@interface LGViewController () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeaconRegion *myBeaconRegion;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation LGViewController

- (id) init
{
    self = [super init];
    
    if (self)
    {
        [self setup];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    
    
    
    
    
    // All of this beacon code needs ripping out and putting into a main service
    // It's important to note that the UUID for the device must be known beforehand.
    // We will assign an ID to InstantView beacons in advance.
    // UUID: InstantView
    // Major: Company
    // Minor: Specific beacon (16 bit unsigned integer - 0-65353)
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    // This is the fixed UUID for InstantView
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"e2c56db5-dffb-48d2-b060-d0f5a71096e0"];
    
    self.myBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"com.beacons.instantview"];
    self.myBeaconRegion.notifyEntryStateOnDisplay = YES;
    
    [self.locationManager startMonitoringForRegion:self.myBeaconRegion];
    [self.locationManager startRangingBeaconsInRegion:self.myBeaconRegion];
}

- (void)setup
{
    
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
    CLBeacon *foundBeacon = [beacons firstObject];
    
    NSString *uuid = foundBeacon.proximityUUID.UUIDString;
    NSString *major = [NSString stringWithFormat:@"%@", foundBeacon.major];
    NSString *minor = [NSString stringWithFormat:@"%@", foundBeacon.minor];
    
    NSLog(@"UUID: %@", uuid);
    NSLog(@"Major: %@", major);
    NSLog(@"Minor: %@", minor);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
