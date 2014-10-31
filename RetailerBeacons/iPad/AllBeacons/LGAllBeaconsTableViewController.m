//
//  LGAllBeaconsTableViewController.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 8/26/14.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import "LGAllBeaconsTableViewController.h"
#import "LGDetectedBeaconViewController.h"
#import "LGOfferViewController.h"

@interface LGAllBeaconsTableViewController ()

@end

@implementation LGAllBeaconsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
		[self setup];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setup
{
    self.tableView.backgroundColor = [UIColor colorWithRed:(247/255.0) green:(247/255.0) blue:(247/255.0) alpha:1];
	self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.navigationItem.title = @"Your Products";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																						   target:self
																						   action:@selector(addBeacon:)];
}

- (IBAction)addBeacon:(id)sender
{
	LGDetectedBeaconViewController *detectedBeacon = [[LGDetectedBeaconViewController alloc] initWithNibName:@"DetectedBeacon"
																									  bundle:nil];
	[self.navigationController pushViewController:detectedBeacon animated:YES];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
	if (cell == nil){
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
	}
	
	cell.textLabel.text = @"Samsung TV's";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.detailTextLabel.text = @"UUID - Major - Minor";
	cell.indentationWidth = 0.0f;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"Load beacon at indexPath: %d", indexPath.row);
	
	LGOfferViewController *offer = [[LGOfferViewController alloc] initWithNibName:@"Offer" bundle:nil];
	
	[self.navigationController pushViewController:offer animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	UIView *view = [[UIView alloc] init];
	return view;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.0;
}

@end
