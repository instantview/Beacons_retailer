//
//  LGOfferViewController.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 8/26/14.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "Constants.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "UIColor+UIColorCategory.h"
#import "LGProductViewController.h"

@interface LGProductViewController ()
	<UINavigationControllerDelegate,
	 UIImagePickerControllerDelegate,
	 MBProgressHUDDelegate,
	 UITextFieldDelegate>
{
	MBProgressHUD *HUD;
}

@property (nonatomic) NSMutableArray *capturedImages;
@property (nonatomic) UIImagePickerController *imagePicker;
@property (nonatomic) NSString *imageURL;
@property (nonatomic) NSString *productId;
@property (nonatomic) NSMutableArray *offers;
@property (nonatomic) BOOL hasNewImage;
@property (nonatomic) int updateOfferId;

@end

@implementation LGProductViewController

@synthesize beaconUUID;
@synthesize productId;
@synthesize productImage;
@synthesize productSegmentController;
@synthesize capturedImages;
@synthesize imageURL;
@synthesize hasNewImage;
@synthesize offersContainer;
@synthesize offersTable;
@synthesize saveOffer;
@synthesize resetForm;
@synthesize updateOfferId;

NSString *const kTabTitleProduct = @"Product Information";
NSString *const kTabTitleOffers = @"Product Offers";
NSString *const kTabTitleAnalytics = @"Product Analytics";

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
	self.offersTable.delegate = self;
	self.offersTable.dataSource = self;
	self.offersTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	HUD.delegate = self;
	
	[HUD showWhileExecuting:@selector(fetchBeaconData) onTarget:self withObject:nil animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Form elements for the offers view
	self.descriptionField.layer.borderColor = [UIColor colorWithHexString:@"0xDDDDDD"].CGColor;
	self.descriptionField.layer.borderWidth = 1.0f;
	self.offerTitleField.text = @"";
	self.offerStraplineField.text = @"";
	self.descriptionField.text = @"";
	self.updateOfferId = 0;
	
	self.startDateField.delegate = self;
	self.endDateField.delegate = self;
	
	[self.resetForm setTitle:@"Clear Form" forState:UIControlStateNormal];
	[self populateOffers];
}

- (void)setup
{
	self.hasNewImage = NO;
	self.imageURL = nil;
	self.productImage.backgroundColor = [UIColor blackColor];
	self.capturedImages = [NSMutableArray new];
	self.navigationItem.title = kTabTitleProduct;
	self.offers = [NSMutableArray new];
	
	UILabel *label = [UILabel new];
	label.frame = CGRectMake(22, 126, 100, 30);
	
	[label setText:@"Hello world!"];
	
	[self.offersContainer addSubview:label];
	
}

- (void)fetchBeaconData
{
	NSString *url = [NSString stringWithFormat:@"%@/product/getProduct", kBaseAPIUrl];
	NSDictionary *params = @{@"UUID" : self.beaconUUID};
	
	[[AFHTTPSessionManager manager] GET:url
							 parameters:params
								success:^(NSURLSessionDataTask *task, id responseObject) {
									dispatch_async(dispatch_get_main_queue(), ^{
										
										if ([responseObject objectForKey:@"ID"])
										{
											self.productId = responseObject[@"ID"];
											[self displayData:responseObject];
										}
										
									});
								} failure:^(NSURLSessionDataTask *task, NSError *error) {
									NSLog(@"Error: %@", error);
								}];
}

- (void)displayData:(NSDictionary *)response
{
	if (response)
	{
		NSLog(@"%@", response);
		
		self.productManufacturer.text = [response objectForKey:@"manufacturer"];
		self.productName.text = [response objectForKey:@"productName"];
		self.productPrice.text = [[response objectForKey:@"price"] stringValue];
		
		UIImage *defaultImage = [UIImage imageNamed:@"noimage"];
		
		NSString *url = [response objectForKey:@"imageURL"];
		
		if (![url isKindOfClass:[NSNull class]])
		{
			[self.productImage setImageWithURL:[NSURL URLWithString:url]
							  placeholderImage:defaultImage];
		}
		
		self.productImage.backgroundColor = [UIColor blackColor];
	}
	
	self.productContainer.hidden = NO;
	
}

- (IBAction)changeCategory:(id)sender
{
	[self.view endEditing:YES];
}

- (IBAction)productChange:(id)sender
{
	[self.view endEditing:YES];
	
	self.productContainer.hidden = YES;
	self.analyticsContainer.hidden = YES;
	self.offersContainer.hidden = YES;
	
	UISegmentedControl *segment = (UISegmentedControl *) sender;
	NSInteger selected = segment.selectedSegmentIndex;
	
	if (selected == 0)
	{
		self.productContainer.hidden = NO;
		self.navigationItem.title = kTabTitleProduct;
	}
	else if (selected == 1)
	{
		self.offersContainer.hidden = NO;
		self.navigationItem.title = kTabTitleOffers;
	}
	else if (selected == 2)
	{
		self.analyticsContainer.hidden = NO;
		self.navigationItem.title = kTabTitleAnalytics;
	}
}

- (IBAction)changePhoto:(id)sender
{
	self.imagePicker = [UIImagePickerController new];
	self.imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
	self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	self.imagePicker.delegate = self;
	self.imagePicker.showsCameraControls = YES;
	
	[self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (IBAction)saveAllChanges:(id)sender
{
	[self.productManufacturer resignFirstResponder];
	[self.productName resignFirstResponder];
	[self.productPrice resignFirstResponder];
	
	HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.labelText = @"Saving";
	
	[HUD show:YES];
	
	if (!self.hasNewImage)
	{
		[self updateAll];
		return;
	}
	
	HUD.detailsLabelText = @"Uploading image";
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *guid = [userDefaults objectForKey:@"guid"];
	
	NSString *url = [NSString stringWithFormat:@"%@/product/SaveProductImage", kBaseAPIUrl];
	
	// Resize the image before uploading
	float actualHeight = self.productImage.image.size.height;
	float actualWidth = self.productImage.image.size.width;
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
	[self.productImage.image drawInRect:rect];
	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	NSData *imageData = UIImageJPEGRepresentation(img, 0.7);
	
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	[manager POST:url parameters:@{@"UserGUID":guid, @"UUID":self.beaconUUID} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
		[formData appendPartWithFileData:imageData
									name:@"file"
								fileName:@"test.jpg"
								mimeType:@"image/jpeg"];
	} success:^(AFHTTPRequestOperation *operation, id responseObject) {
		[self updateAll];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Error: %@", error);
	}];
	
}

- (void)updateAll
{
	HUD.detailsLabelText = @"Updating properties";
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *guid = [defaults objectForKey:@"guid"];
	
	NSString *updateURL = [NSString stringWithFormat:@"%@/product/updateProduct", kBaseAPIUrl];
	NSDictionary *updateParams = @{
								   @"UserGUID" : guid,
								   @"manufacturer" : self.productManufacturer.text,
								   @"productName" : self.productName.text,
								   @"price" : self.productPrice.text,
								   @"UUID" : self.beaconUUID
								   };
	
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	[manager POST:updateURL
	   parameters:updateParams
		  success:^(AFHTTPRequestOperation *operation, id responseObject) {
			  
			  HUD.mode = MBProgressHUDModeText;
			  HUD.labelText = @"Product Updated";
			  HUD.detailsLabelText = @"";
			  
			  [HUD hide:YES afterDelay:2];
			  
	   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		   NSLog(@"Error: %@", error);
		   
		   HUD.mode = MBProgressHUDModeText;
		   HUD.labelText = @"Server error";
		   HUD.detailsLabelText = @"Please try again.";
		   
		   [HUD hide:YES afterDelay:2];
	   }];
}

- (void)populateOffers
{
	self.offers = [NSMutableArray new];
	
	NSString *url = [NSString stringWithFormat:@"%@/offer/getProductOffersByUUID", kBaseAPIUrl];
	NSDictionary *params = @{@"beaconUUID": self.beaconUUID};
	
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	[manager  GET:url
	   parameters:params
		  success:^(AFHTTPRequestOperation *operation, id responseObject){
			  
			  for (int i=0; i<[responseObject count]; i++)
			  {
				  [self.offers addObject:responseObject[i]];
			  }
			  
			  [self.offersTable reloadData];
			  
	   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			NSLog(@"Error: %@", error);
	   }];
}

# pragma mark - Camera delegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[self.imagePicker dismissViewControllerAnimated:YES completion:nil];
	
	self.hasNewImage = YES;
	self.productImage.image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
	self.productImage.contentMode = UIViewContentModeScaleAspectFit;
	self.productImage.backgroundColor = [UIColor blackColor];
}

# pragma mark - UITableView Datasource and Delegates
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	
	if (!cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
	}
	
	NSDictionary *offer = [self.offers objectAtIndex:indexPath.row];
	
	cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", offer[@"title"], offer[@"strapLine"]];
	cell.accessoryType = UITableViewCellAccessoryDetailButton;
	
	NSLog(@"Offer to display: %@", offer);
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row < [self.offers count])
	{
		NSDictionary *selectedOffer = [self.offers objectAtIndex:indexPath.row];
		
		self.offerTitleField.text = selectedOffer[@"title"];
		self.offerStraplineField.text = selectedOffer[@"strapLine"];
		self.descriptionField.text = selectedOffer[@"description"];
		self.updateOfferId = [selectedOffer[@"ID"] integerValue];
		
		// Format the start date from the server
		NSString *newStartTimestamp = [[[selectedOffer objectForKey:@"startDateTime"] componentsSeparatedByCharactersInSet:
								[[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
							   componentsJoinedByString:@""];
		
		double newTimestamp = [newStartTimestamp doubleValue] / 1000;
		
		NSDate *date = [NSDate dateWithTimeIntervalSince1970:newTimestamp];
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
		[dateFormatter setDateFormat:@"dd MMM yyyy HH:mm"];
		self.startDateField.text = [dateFormatter stringFromDate:date];
		
		// Format the end date from the server
		NSString *newEndTimestamp = [[[selectedOffer objectForKey:@"endDateTime"] componentsSeparatedByCharactersInSet:
										[[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
									   componentsJoinedByString:@""];
		
		double newEndTimestampDbl = [newEndTimestamp doubleValue] / 1000;
		
		NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:newEndTimestampDbl];
		NSDateFormatter *endDateFormatter = [[NSDateFormatter alloc]init];
		[endDateFormatter setDateFormat:@"dd MMM yyyy HH:mm"];
		self.endDateField.text = [endDateFormatter stringFromDate:endDate];
		
		[self.saveOffer setTitle:@"Update Offer" forState:UIControlStateNormal];
	}
	
	[self.offersTable deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.offers count];
}

# pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	UIDatePicker *datePicker = [[UIDatePicker alloc]init];
	datePicker.datePickerMode = UIDatePickerModeDateAndTime;
	datePicker.tag = textField.tag;
	[datePicker addTarget:self
				   action:@selector(datePickerValueChanged:)
		 forControlEvents:UIControlEventValueChanged];
	
	if (textField.text.length == 0)
	{
		[datePicker setDate:[NSDate date]];
		datePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:-31536000];
	}
	else
	{
		NSTimeInterval timeInterval = [self epochFromString:textField.text];
		[datePicker setDate:[NSDate dateWithTimeIntervalSince1970:timeInterval]];
	}
	
	if (textField.tag == 1)
	{
		self.startDateField.inputView = datePicker;
		self.startDateField.text = [self formatDate:datePicker.date];
	}
	
	if (textField.tag == 2)
	{
		self.endDateField.inputView = datePicker;
		self.endDateField.text = [self formatDate:datePicker.date];
	}
}

- (void)datePickerValueChanged:(id)sender
{
	if ([sender tag] == 1)
	{
		UIDatePicker *picker = (UIDatePicker*)self.startDateField.inputView;
		self.startDateField.text = [self formatDate:picker.date];
	}
	
	if ([sender tag] == 2)
	{
		UIDatePicker *picker = (UIDatePicker*)self.endDateField.inputView;
		self.endDateField.text = [self formatDate:picker.date];
	}
}

- (NSString *)formatDate:(NSDate *)date
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateFormat:@"dd MMM yyyy HH:mm"];
	NSString *formattedDate = [dateFormatter stringFromDate:date];
	return formattedDate;
}

- (NSTimeInterval)epochFromString:(NSString *)string
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"dd MMM yyyy HH:mm"];
	NSDate *date = [[NSDate alloc] init];
	date = [dateFormatter dateFromString:string];
	
	return [date timeIntervalSince1970];
}

- (IBAction)saveOfferButton:(id)sender
{
	if (self.updateOfferId > 0)
	{
		[self updateOfferWithId:self.updateOfferId];
	}
	else
	{
		[self addNewOffer];
	}
}

- (void)addNewOffer
{
	HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.labelText = @"Adding New Offer";
	
	[HUD show:YES];
	
	[self.offerTitleField resignFirstResponder];
	[self.offerStraplineField resignFirstResponder];
	[self.descriptionField resignFirstResponder];
	[self.startDateField resignFirstResponder];
	[self.endDateField resignFirstResponder];
	
	// sanity check before adding
	if ([self.offerTitleField.text isEqualToString:@""] || [self.offerStraplineField.text isEqualToString:@""])
	{
		HUD.mode = MBProgressHUDModeText;
		HUD.labelText = @"Please enter an offer title and strapline";
		[HUD hide:YES afterDelay:2];
		return;
	}
	
	// format start date
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"dd MMM yyyy HH:mm"];
	NSDate *date = [formatter dateFromString:self.startDateField.text];
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString *newStartDate = [formatter stringFromDate:date];
	
	// format the end date
	NSDateFormatter *endDateformatter = [[NSDateFormatter alloc] init];
	[endDateformatter setDateFormat:@"dd MMM yyyy HH:mm"];
	NSDate *endDate = [endDateformatter dateFromString:self.endDateField.text];
	[endDateformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString *newEndDate = [endDateformatter stringFromDate:endDate];
	
	NSLog(@"%@", newStartDate);
	NSLog(@"%@", newEndDate);
	
	NSString *updateURL = [NSString stringWithFormat:@"%@/offer/addProductOffer", kBaseAPIUrl];
	NSDictionary *updateParams = @{
								   @"beaconUUID" : self.beaconUUID,
								   @"startDateTime" : newStartDate,
								   @"endDateTime" : newEndDate,
								   @"title" : self.offerTitleField.text,
								   @"strapLine" : self.offerStraplineField.text,
								   @"description" : self.descriptionField.text,
								   @"price" : @"0"
								   };
	
	NSLog(@"%f", [self epochFromString:self.startDateField.text]);
	
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	[manager POST:updateURL
	   parameters:updateParams
		  success:^(AFHTTPRequestOperation *operation, id responseObject) {
			  
			  NSLog(@"Offer response: %@", responseObject);
			  
			  HUD.mode = MBProgressHUDModeText;
			  HUD.labelText = @"Offer Added";
			  HUD.detailsLabelText = @"";
			  
			  [HUD hide:YES afterDelay:2];
			  
			  [self populateOffers];
			  
	   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		   NSLog(@"Error: %@", error);
		   
		   HUD.mode = MBProgressHUDModeText;
		   HUD.labelText = @"Server error";
		   HUD.detailsLabelText = @"Please try again.";
		   
		   [HUD hide:YES afterDelay:2];
	   }];

}

- (void)updateOfferWithId:(int)offerId
{
	HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.labelText = @"Updating Offer";
	
	[HUD show:YES];
	
	[self.offerTitleField resignFirstResponder];
	[self.offerStraplineField resignFirstResponder];
	[self.descriptionField resignFirstResponder];
	[self.startDateField resignFirstResponder];
	[self.endDateField resignFirstResponder];
	
	// sanity check before adding
	if ([self.offerTitleField.text isEqualToString:@""] || [self.offerStraplineField.text isEqualToString:@""])
	{
		HUD.mode = MBProgressHUDModeText;
		HUD.labelText = @"Please enter an offer title and strapline";
		[HUD hide:YES afterDelay:2];
		return;
	}
	
	// format start date
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"dd MMM yyyy HH:mm"];
	NSDate *date = [formatter dateFromString:self.startDateField.text];
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString *newStartDate = [formatter stringFromDate:date];
	
	// format the end date
	NSDateFormatter *endDateformatter = [[NSDateFormatter alloc] init];
	[endDateformatter setDateFormat:@"dd MMM yyyy HH:mm"];
	NSDate *endDate = [endDateformatter dateFromString:self.endDateField.text];
	[endDateformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString *newEndDate = [endDateformatter stringFromDate:endDate];
	
	NSLog(@"%@", newStartDate);
	NSLog(@"%@", newEndDate);
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *guid = [defaults objectForKey:@"guid"];
	
	NSString *updateURL = [NSString stringWithFormat:@"%@/offer/addProductOffer", kBaseAPIUrl];
	NSDictionary *updateParams = @{
								   @"UserGUID" : guid,
								   @"offerID" : [NSString stringWithFormat:@"%d", offerId],
								   @"beaconUUID" : self.beaconUUID,
								   @"startDateTime" : newStartDate,
								   @"endDateTime" : newEndDate,
								   @"title" : self.offerTitleField.text,
								   @"strapLine" : self.offerStraplineField.text,
								   @"description" : self.descriptionField.text,
								   @"price" : @"0"
								   };
	
	NSLog(@"%f", [self epochFromString:self.startDateField.text]);
	
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	[manager POST:updateURL
	   parameters:updateParams
		  success:^(AFHTTPRequestOperation *operation, id responseObject) {
			  
			  NSLog(@"Offer response: %@", responseObject);
			  
			  HUD.mode = MBProgressHUDModeText;
			  HUD.labelText = @"Offer Updated";
			  HUD.detailsLabelText = @"";
			  
			  [HUD hide:YES afterDelay:2];
			  
			  [self populateOffers];
			  
	   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		   NSLog(@"Error: %@", error);
		   
		   HUD.mode = MBProgressHUDModeText;
		   HUD.labelText = @"Server error";
		   HUD.detailsLabelText = @"Please try again.";
		   
		   [HUD hide:YES afterDelay:2];
	   }];
}

- (IBAction)resetFormButton:(id)sender
{
	self.offerTitleField.text = @"";
	self.offerStraplineField.text = @"";
	self.descriptionField.text = @"";
	self.startDateField.text = @"";
	self.endDateField.text = @"";
	
	self.updateOfferId = 0;
	
	[self.saveOffer setTitle:@"Save Offer" forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


@end
