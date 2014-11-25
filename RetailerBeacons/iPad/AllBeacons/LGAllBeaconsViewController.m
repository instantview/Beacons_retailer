//
//  LGAllBeaconsViewController.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 10/3/14.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "Constants.h"
#import "MBProgressHud.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "UIColor+UIColorCategory.h"
#import "LGAllBeaconsViewController.h"
#import "LGBeaconCellLayout.h"
#import "LGBeaconCell.h"
#import "LGProductViewController.h"
#import "LGLoginViewController.h"
#import "LGBeaconConfigurationView.h"

typedef NS_ENUM(NSInteger, LGBeaconType){
	LGBeaconTypeDiscovered,
	LGBeaconTypeKnown
};

@interface LGAllBeaconsViewController () <
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
UICollectionViewDataSource,
UICollectionViewDelegate,
UITableViewDataSource,
UITableViewDelegate,
UITextFieldDelegate,
UISearchBarDelegate,
CBCentralManagerDelegate,
CLLocationManagerDelegate>
{
	MBProgressHUD *HUD;
}

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) UICollectionView *collection;
@property (strong, nonatomic) UICollectionViewLayout *collectionViewLayout;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIView *searchOverlay;
@property (strong, nonatomic) NSMutableArray *beacons;
@property (strong, nonatomic) NSMutableArray *discoveredBeacons;
@property (strong, nonatomic) NSMutableArray *knownBeacons;
@property (strong, nonatomic) CBCentralManager *bluetoothManager;

// New beacon details
@property (strong, nonatomic) NSString *foundUUID;
@property (strong, nonatomic) UITextField *beaconName;
@property (strong, nonatomic) UIView *noBeaconsView;
@property (strong, nonatomic) UIView *closeView;

// Camera
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) UIImage *beaconInstallationImage;
@property (nonatomic) BOOL hasPhoto;

// Search results/filtering
@property (strong, nonatomic) NSMutableArray *searchSet;
@property (strong, nonatomic) NSArray *searchResults;
@property (strong, nonatomic) UITableView *searchResultsView;

@end

@implementation LGAllBeaconsViewController

@synthesize locationManager;
@synthesize beaconRegion;
@synthesize beaconName;
@synthesize collection;
@synthesize collectionViewLayout;
@synthesize searchBar;
@synthesize searchOverlay;
@synthesize beacons;
@synthesize discoveredBeacons;
@synthesize knownBeacons;
@synthesize bluetoothManager;
@synthesize searchResults, searchSet;
@synthesize noBeaconsView, closeView, foundUUID;
@synthesize imagePicker, beaconInstallationImage, hasPhoto;

NSString *const kBeaconCellIdentifier = @"cell";
NSString *const kDefaultNameForBeacon = @"Choose a private name to identify this beacon...";

bool searchIsDisplayed = NO;
bool bluetoothEnabled = NO;
int serviceTimes = 0;

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setup];
}

- (void)viewWillLayoutSubviews
{
	[super viewWillLayoutSubviews];
	
	self.collection.frame = CGRectMake(10, 10, self.view.frame.size.width, self.view.frame.size.height);
	
	[self.collection.collectionViewLayout invalidateLayout];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self updateKnownBeacons];
	[self findNewBeacons];
}

- (void)setup
{
	self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self
																 queue:nil
															   options:nil];
	self.beacons			= [NSMutableArray new];
	self.knownBeacons		= [NSMutableArray new];
	self.discoveredBeacons	= [NSMutableArray new];
	self.searchSet			= [NSMutableArray new];
	self.hasPhoto			= NO;
	
	self.view.backgroundColor = [UIColor colorWithHexString:@"0xEEEEEE"];
	
	UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout"
																	 style:UIBarButtonItemStylePlain
																	target:self
																	action:@selector(logout)];
	self.navigationItem.leftBarButtonItem = logoutButton;
	self.navigationItem.title = @"Locate Sense";
	
	LGBeaconCellLayout *layout = [[LGBeaconCellLayout alloc] init];
	layout.scrollDirection = UICollectionViewScrollDirectionVertical;
	layout.minimumLineSpacing = 15;
	layout.itemSize = CGSizeMake(240,280);
	layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
	
	CGRect rect = CGRectMake(10, 10, self.view.frame.size.width, self.view.frame.size.height);
	
	self.collection = [[UICollectionView alloc] initWithFrame:rect
										 collectionViewLayout:layout];
	self.collection.backgroundColor = [UIColor clearColor];
	self.collection.delegate = self;
	self.collection.dataSource = self;
	
	[self.collection registerClass:[LGBeaconCell class] forCellWithReuseIdentifier:kBeaconCellIdentifier];
	[self.view addSubview:self.collection];
	
	self.searchBar = [UISearchBar new];
	self.searchBar.delegate = self;
	self.searchBar.showsCancelButton = NO;
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeSearch)];
	
	self.searchOverlay = [UIView new];
	self.searchOverlay.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	self.searchOverlay.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
	self.searchOverlay.userInteractionEnabled = NO;
	self.searchOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.searchOverlay addGestureRecognizer:tapGesture];
	[self.view addSubview:self.searchOverlay];
	[self closeSearchBar];
	
	self.searchResultsView = [[UITableView alloc] initWithFrame:CGRectMake(0,64,self.view.frame.size.width, self.view.frame.size.height)
														  style:UITableViewStylePlain];
	self.searchResultsView.delegate = self;
	self.searchResultsView.dataSource = self;
	self.searchResultsView.hidden = YES;
	self.searchResultsView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	self.searchResultsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.view addSubview:self.searchResultsView];
	
	// View if there are no beacons to display
	int noBeaconsWidth = self.view.frame.size.width - 50;
	int noBeaconsHeight = 200;
	int noBeaconsX = (self.view.frame.size.width - noBeaconsWidth) / 2;
	int noBeaconsY = 64 + 20;
	
	UILabel *noBeaconsMessage = [UILabel new];
	noBeaconsMessage.frame = CGRectMake(0, noBeaconsHeight / 2, noBeaconsWidth, 30);
	noBeaconsMessage.text = @"You currently have no beacons available.";
	noBeaconsMessage.textAlignment = NSTextAlignmentCenter;
	noBeaconsMessage.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	self.noBeaconsView = [UIView new];
	self.noBeaconsView.frame = CGRectMake(noBeaconsX, noBeaconsY, noBeaconsWidth, noBeaconsHeight);
	self.noBeaconsView.hidden = NO;
	self.noBeaconsView.backgroundColor = [UIColor clearColor];
	self.noBeaconsView.autoresizesSubviews = YES;
	self.noBeaconsView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	[self.noBeaconsView addSubview:noBeaconsMessage];
	[self.view addSubview:self.noBeaconsView];
}

- (void)findNewBeacons
{
	[self bluetoothServiceUpdate];
	
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

- (void)showSearchBar
{
	self.navigationItem.titleView = self.searchBar;
	searchIsDisplayed = YES;
	
	if (self.searchBar.text.length > 0)
	{
		self.searchResultsView.hidden = NO;
	}
	
	UIBarButtonItem *closeSearchBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Close"
																			 style:UIBarButtonItemStylePlain
																			target:self
																			action:@selector(closeSearchBar)];
	self.navigationItem.rightBarButtonItem = closeSearchBarButton;
	[self.searchBar becomeFirstResponder];
}

- (void)closeSearchBar
{
	self.searchResultsView.hidden = YES;
	self.navigationItem.titleView = nil;
	searchIsDisplayed = NO;
	UIBarButtonItem *searchBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Search"
																		style:UIBarButtonItemStylePlain
																	   target:self
																	   action:@selector(showSearchBar)];
	self.navigationItem.rightBarButtonItem = searchBarButton;
}

- (void)bluetoothServiceUpdate
{
	BOOL locationAllowed = [CLLocationManager locationServicesEnabled];
	
	if (!bluetoothEnabled || !locationAllowed)
	{
		[self displayMessage:@"Locate Sense works best with bluetooth and location services. Please update your settings."];
	}
}

# pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
		didRangeBeacons:(NSArray *)beaconsDetected
			   inRegion:(CLBeaconRegion *)region
{
	// Loop throug the beacons discovered
	for (CLBeacon *beacon in beaconsDetected)
	{
		NSString *beaconID = [NSString stringWithFormat:@"%@-%@-%@",
								beacon.proximityUUID.UUIDString,
								beacon.major,
								beacon.minor];
		BOOL exists = NO;
		
		// Compare the beacons we've just discovered with the ones we already know
		for (int i=0; i<[self.beacons count]; i++)
		{
			NSDictionary *previouslyFoundBeacon = [self.beacons objectAtIndex:i];
			
			if ([beaconID isEqualToString:[previouslyFoundBeacon objectForKey:@"UUID"]])
			{
				exists = YES;
			}
		}
		
		if (!exists)
		{
			[self.discoveredBeacons addObject:@{@"UUID": beaconID, @"type": [NSNumber numberWithInt:LGBeaconTypeDiscovered]}];
		}
	}
	
	[self updateCollection];
}

# pragma mark - UICollectionViewDelegate and UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	LGBeaconCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kBeaconCellIdentifier forIndexPath:indexPath];
	
	if (indexPath.row < [self.beacons count])
	{
		NSDictionary *data = [self.beacons objectAtIndex:indexPath.row];
		
		if ([data[@"type"] intValue] == LGBeaconTypeKnown)
		{
			UIImage *defaultImage = [UIImage imageNamed:@"noimage"];
			NSString *url = [data objectForKey:@"img"];
			
			if (![url isKindOfClass:[NSNull class]])
			{
				[cell.beaconImageView setImageWithURL:[NSURL URLWithString:url]
											 placeholderImage:defaultImage];
			}
			
			cell.beaconImageView.layer.borderColor = [UIColor whiteColor].CGColor;
			cell.beaconImageView.layer.borderWidth = 1.0f;
			cell.beaconImageView.backgroundColor = [UIColor blackColor];
			cell.beaconImageView.contentMode = UIViewContentModeScaleAspectFill;
			cell.beaconImageView.layer.masksToBounds = YES;
			cell.beaconLabel.text = (data[@"name"] == (id)[NSNull null]) ? @"Your Beacon" : data[@"name"];
		}
		else
		{
			cell.beaconImageView.image = [UIImage imageNamed:@"newbeacon"];
			cell.beaconLabel.text = @"New Beacon";
		}
	}
	
	return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.beacons.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *beacon = [self.beacons objectAtIndex:indexPath.row];
	[self segueToProduct:beacon[@"UUID"]];
}

# pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	self.searchResultsView.hidden = (searchText.length > 0) ? NO : YES;
	
	NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchText];
	self.searchResults = [self.searchSet filteredArrayUsingPredicate:resultPredicate];
	[self.searchResultsView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	self.searchOverlay.userInteractionEnabled = YES;
	
	[UIView animateWithDuration:0.3 delay:0. options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.searchOverlay.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
	} completion:^(BOOL finished) {
		// completion code (if needed)
	}];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	self.searchOverlay.userInteractionEnabled = NO;
	
	[UIView animateWithDuration:0.3 delay:0. options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.searchOverlay.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
	} completion:^(BOOL finished) {
		// Completion code (if needed)
	}];
}

- (void)closeSearch
{
	self.searchOverlay.userInteractionEnabled = NO;
	
	[self.searchBar resignFirstResponder];
	
	[UIView animateWithDuration:0.3 delay:0. options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.searchOverlay.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
	} completion:^(BOOL finished) {
		// Completion code (if needed)
	}];
}

# pragma mark - UITableViewDelegate & UITableViewDataSource (for search results)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"searchResultCell"];
	
	if (!cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"searchResultCell"];
	}
	
	cell.textLabel.text = [self.searchResults objectAtIndex:indexPath.row];
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.searchResults.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *productName = [self.searchResults objectAtIndex:indexPath.row];
	
	for (NSDictionary *beacon in self.beacons)
	{
		if ([productName isEqualToString:[beacon objectForKey:@"name"]])
		{
			[self segueToProduct:beacon[@"UUID"]];
		}
	}
}

# pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
	bluetoothEnabled = ([central state] == CBCentralManagerStatePoweredOn) ? YES: NO;
	[self bluetoothServiceUpdate];
}

# pragma mark - AFNetworking

- (void)updateKnownBeacons
{
//	HUD = [[MBProgressHUD alloc] initWithView:self.view];
//	[self.view addSubview:HUD];
//
//	[HUD showWhileExecuting:@selector(updateBeaconData) onTarget:self withObject:nil animated:YES];
	
	[self updateBeaconData];
}

- (void)updateBeaconData
{
	self.knownBeacons = [NSMutableArray new];
	
	NSString *url = [NSString stringWithFormat:@"%@/product/getRetailerProducts", kBaseAPIUrl];
	
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFJSONResponseSerializer serializer];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *guid = [userDefaults objectForKey:@"guid"];
	
	NSDictionary *params = @{@"userGUID" : guid};
	
	[manager GET:url
	  parameters:params
		 success:^(AFHTTPRequestOperation *operation, id responseObject){
			
			 if ([responseObject isKindOfClass:[NSArray class]])
			 {
				 for (int i=0; i<[responseObject count]; i++)
				 {
					 NSDictionary *dictionary = @{@"UUID" : responseObject[i][@"UUID"],
												  @"name" : responseObject[i][@"productName"],
												  @"img"  : responseObject[i][@"imageInstallationURL"],
												  @"type" : [NSNumber numberWithInt:LGBeaconTypeKnown]};
					 
					 [self.knownBeacons addObject:dictionary];
					 [self.searchSet addObject:responseObject[i][@"productName"]];
				 }
			 }
			
			 [self updateCollection];
			 
		 }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			 NSLog(@"Fail");
			 NSLog(@"%@", error);
		 }];
}

- (void)updateCollection
{
	self.beacons = [NSMutableArray new];
	
	if ([self.knownBeacons count] > 0)
	{
		for (int i=0; i<[self.knownBeacons count]; i++)
		{
			[self.beacons addObject:[self.knownBeacons objectAtIndex:i]];
		}
	}
	
	if ([self.discoveredBeacons count] > 0)
	{
		for (int i=0; i<[self.discoveredBeacons count]; i++)
		{
			[self.beacons insertObject:[self.discoveredBeacons objectAtIndex:i] atIndex:0];
		}
	}
	
	[self toggleBeaconMessageCount];
	[self.collection reloadData];
}

- (void)toggleBeaconMessageCount
{
	self.noBeaconsView.hidden = (self.beacons.count == 0) ? NO : YES;
}

- (void)displayMessage:(NSString *)message
{
	UIView *messageView = [UIView new];
	messageView.frame = CGRectMake(0, 64, self.view.frame.size.width, 60);
	messageView.backgroundColor = [UIColor whiteColor];
	messageView.layer.masksToBounds = NO;
	messageView.layer.shadowOffset = CGSizeMake(0, 4);
	messageView.layer.shadowRadius = 5;
	messageView.layer.shadowOpacity = 0.25;
	
	UILabel *messageLabel = [UILabel new];
	messageLabel.frame = CGRectMake(0, 0, messageView.frame.size.width, messageView.frame.size.height);
	messageLabel.text = message;
	messageLabel.textAlignment = NSTextAlignmentCenter;
	messageLabel.font = [UIFont boldSystemFontOfSize:15.0];
	
	[messageView addSubview:messageLabel];
	[self.view addSubview:messageView];
	[self performSelector:@selector(removeMessage:) withObject:messageView afterDelay:5];
}

# pragma mark - Deal with adding new beacons

- (void)segueToProduct:(NSString *)beaconId
{
	int type = -1;
	
	for (NSDictionary *beacon in self.beacons)
	{
		if ([beacon[@"UUID"] isEqualToString:beaconId])
		{
			type = [beacon[@"type"] intValue];
		}
	}
	
	if (type == LGBeaconTypeKnown)
	{
		self.searchSet = [NSMutableArray new];
		
		LGProductViewController *productVC = [[LGProductViewController alloc] initWithNibName:@"Product" bundle:nil];
		productVC.beaconUUID = beaconId;
		
		[self.navigationController pushViewController:productVC animated:YES];
	}
	
	if (type == LGBeaconTypeDiscovered)
	{
		[self checkBeaconIsNew:beaconId];
	}
}

- (void)checkBeaconIsNew:(NSString *)beaconId
{
	NSString *url = [NSString stringWithFormat:@"%@/product/getProduct", kBaseAPIUrl];
	NSDictionary *params = @{@"UUID" : beaconId};
	
	[[AFHTTPSessionManager manager] GET:url
							 parameters:params
								success:^(NSURLSessionDataTask *task, id responseObject){
									
									NSLog(@"%@", responseObject);
									
									if ([responseObject objectForKey:@"ID"])
									{
										[self showBeaconIsAdded];
									}
									else
									{
										self.foundUUID = beaconId;
										[self allowToConfigureBeacon:beaconId];
									}
									
								} failure:^(NSURLSessionDataTask *task, NSError *error) {
									NSLog(@"Error: %@", error);
								}];
}

- (void)showBeaconIsAdded
{
	[self displayMessage:@"Sorry, this beacon is already being used by another user."];
}

- (void)allowToConfigureBeacon:(NSString *)beaconId
{
	self.searchOverlay.userInteractionEnabled = NO;
	self.navigationController.navigationBar.userInteractionEnabled = NO;
	
	[UIView animateWithDuration:0.3 delay:0. options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.searchOverlay.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
	} completion:nil];

	self.closeView = [UIView new];
	self.closeView.frame = CGRectMake(50, 100, self.view.frame.size.width - 100, 200);
	self.closeView.backgroundColor = [UIColor whiteColor];
	self.closeView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	UILabel *configureTitle = [UILabel new];
	configureTitle.frame = CGRectMake(0, 20, self.closeView.frame.size.width, 50);
	configureTitle.text = @"Add Your New Beacon";
	configureTitle.font = [UIFont boldSystemFontOfSize:19.0f];
	configureTitle.textAlignment = NSTextAlignmentCenter;
	
	[self.closeView addSubview:configureTitle];
	
	int width = self.closeView.frame.size.width - 100;
	int xOffset = (self.closeView.frame.size.width - width) / 2;
	
	self.beaconName = [UITextField new];
	self.beaconName.frame = CGRectMake(xOffset, 80, width, 30);
	self.beaconName.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.beaconName.text = kDefaultNameForBeacon;
	self.beaconName.textAlignment = NSTextAlignmentCenter;
	self.beaconName.borderStyle = UITextBorderStyleRoundedRect;
	self.beaconName.delegate = self;
	
	[self.closeView addSubview:self.beaconName];
	
	UIImage *closeImage = [UIImage imageNamed:@"close"];
	UIImageView *closeImageView = [[UIImageView alloc] initWithImage:closeImage];
	closeImageView.frame = CGRectMake(self.closeView.frame.size.width - 52, 20, 32, 32);
	closeImageView.clipsToBounds = NO;
	
	[closeImageView setUserInteractionEnabled:YES];
	
	UITapGestureRecognizer *closeGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
																				   action:@selector(closeConfigureModal)];
	
	[closeImageView addGestureRecognizer:closeGesture];
	[self.closeView addSubview:closeImageView];
	[self.closeView bringSubviewToFront:closeImageView];
	
	UIButton *takePhotoButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	takePhotoButton.frame = CGRectMake(20, self.closeView.frame.size.height - 60, 150, 40);
	takePhotoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	
	[takePhotoButton setTitle:@"Take Photo" forState:UIControlStateNormal];
	[takePhotoButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
	
	[self.closeView addSubview:takePhotoButton];
	
	UIButton *saveBeacon = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	saveBeacon.frame = CGRectMake(self.closeView.frame.size.width - 170, self.closeView.frame.size.height - 60, 150, 40);
	saveBeacon.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
	saveBeacon.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	
	[saveBeacon setTitle:@"Save Beacon" forState:UIControlStateNormal];
	[saveBeacon addTarget:self action:@selector(saveBeaconAction) forControlEvents:UIControlEventTouchUpInside];
	
	[self.closeView addSubview:saveBeacon];
	
	[self.view addSubview:self.closeView];
	[self.view bringSubviewToFront:self.closeView];
}

- (void)closeConfigureModal
{
	[self.closeView removeFromSuperview];
	
	[UIView animateWithDuration:0.3 delay:0. options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.searchOverlay.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
	} completion:nil];
	
	self.searchOverlay.userInteractionEnabled = NO;
	self.navigationController.navigationBar.userInteractionEnabled = YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if ([textField.text isEqualToString:kDefaultNameForBeacon])
	{
		textField.text = @"";
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if ([textField.text isEqualToString:@""])
	{
		textField.text = kDefaultNameForBeacon;
	}
}

# pragma mark - Handle the camera controls

- (void)takePhoto
{
	self.imagePicker = [UIImagePickerController new];
	self.imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
	self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	self.imagePicker.delegate = self;
	self.imagePicker.showsCameraControls = YES;
	self.imagePicker.allowsEditing = YES;
	
	self.hasPhoto = YES;
	
	[self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[self.imagePicker dismissViewControllerAnimated:YES completion:nil];
	self.beaconInstallationImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	self.hasPhoto = NO;
}


/**
 * Update the server with the beacon information
 **/
- (void)saveBeaconAction
{
	[self closeConfigureModal];
	
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.labelText = @"Saving";
	HUD.detailsLabelText = @"Adding beacon...";
	
	[HUD show:YES];
	
	// First, upload the data to the server before adding the installation image
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *userId = [userDefaults objectForKey:@"guid"];
	
	NSString *url = [NSString stringWithFormat:@"%@/product/addNewBeacon", kBaseAPIUrl];
	NSDictionary *params = @{
							 @"UserGUID" : userId,
							 @"manufacturer" : @"Locate Sense",
							 @"productName" : self.beaconName.text,
							 @"availableStock": @"0",
							 @"numberOfVisits": @"0",
							 @"price": @"0.00",
							 @"UUID" : self.foundUUID};
	
	[[AFHTTPSessionManager manager] POST:url
							  parameters:params
								 success:^(NSURLSessionDataTask *task, id responseObject) {
									 
									 NSLog(@"Beacon added");
									 NSLog(@"%@", responseObject);
									 
									 [self uploadInstallationImage];
									 
								 } failure:^(NSURLSessionDataTask *task, NSError *error) {
									 
									 NSLog(@"Fail: %@", error);
									 
									 HUD.mode = MBProgressHUDModeText;
									 HUD.labelText = @"Server error";
									 HUD.detailsLabelText = @"Please try again.";
									 
									 [HUD hide:YES afterDelay:2];
									 
								 }];
}

- (void)uploadInstallationImage
{
	if (!self.hasPhoto)
	{
		HUD.mode = MBProgressHUDModeText;
		HUD.labelText = @"Beacon Added";
		HUD.detailsLabelText = @"";
		
		[HUD hide:YES afterDelay:2];
		
		// remove beacon from detected beacons
		[self removeBeaconFromDiscoveredBeacons:self.foundUUID];
		[self updateBeaconData];
		
		return;
	}
	
	HUD.detailsLabelText = @"Uploading photo...";
	
	NSString *url = [NSString stringWithFormat:@"%@/product/SaveInstallationImage", kBaseAPIUrl];
	
	// Resize the image before uploading
	float actualHeight = self.beaconInstallationImage.size.height;
	float actualWidth = self.beaconInstallationImage.size.width;
	float imgRatio = actualWidth/actualHeight;
	float maxRatio = 320.0/480.0;
	
	if(imgRatio!=maxRatio){
		if(imgRatio < maxRatio){
			imgRatio = 480.0 / actualHeight;
			actualWidth = imgRatio * actualWidth;
			actualHeight = 480.0;
		}
		else{
			imgRatio = 320.0 / actualWidth;
			actualHeight = imgRatio * actualHeight;
			actualWidth = 320.0;
		}
	}
	
	CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
	UIGraphicsBeginImageContext(rect.size);
	[self.beaconInstallationImage drawInRect:rect];
	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	NSData *imageData = UIImageJPEGRepresentation(img, 0.7);
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *guid = [userDefaults objectForKey:@"guid"];
	
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

	[manager POST:url parameters:@{@"UserGUID":guid, @"UUID":self.foundUUID} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
		[formData appendPartWithFileData:imageData
									name:@"file"
								fileName:@"test.jpg"
								mimeType:@"image/jpeg"];
	} success:^(AFHTTPRequestOperation *operation, id responseObject) {
		
		NSLog(@"Success: %@", responseObject);
		
		HUD.mode = MBProgressHUDModeText;
		HUD.labelText = @"Beacon Added";
		HUD.detailsLabelText = @"";
		
		[HUD hide:YES afterDelay:2];
		
		[self removeBeaconFromDiscoveredBeacons:self.foundUUID];
		[self updateBeaconData];
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		
		NSLog(@"Error: %@", error);
		
		HUD.mode = MBProgressHUDModeText;
		HUD.labelText = @"Server Error";
		HUD.detailsLabelText = @"Please try again.";
		
		[HUD hide:YES afterDelay:2];
		
	}];

}

- (void)removeBeaconFromDiscoveredBeacons:(NSString *)UUID
{
	for (NSDictionary *beacon in self.discoveredBeacons)
	{
		if ([beacon objectForKey:@"UUID"] == UUID)
		{
			[self.discoveredBeacons removeObject:beacon];
		}
	}
}

- (void)removeMessage:(UIView *)messageView
{
	[messageView removeFromSuperview];
}

- (void)logout
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:@"guid"];
	
	LGLoginViewController *login = [[LGLoginViewController alloc] initWithNibName:@"Login" bundle:nil];
	
	self.view.window.rootViewController = login;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
