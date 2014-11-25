//
//  LGProductViewController.h
//  RetailerBeacons
//
//  Created by Matt Richardson on 8/26/14.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LGProductViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

// General properties for setting up the different views
@property (strong, nonatomic) NSString *beaconUUID;
@property (strong, nonatomic) IBOutlet UISegmentedControl *productSegmentController;
@property (strong, nonatomic) IBOutlet UIView *productContainer;
@property (strong, nonatomic) IBOutlet UIView *analyticsContainer;
@property (strong, nonatomic) IBOutlet UIView *offersContainer;

// Product properties
@property (strong, nonatomic) IBOutlet UIImageView *productImage;
@property (strong, nonatomic) IBOutlet UITextField *productManufacturer;
@property (strong, nonatomic) IBOutlet UITextField *productName;
@property (strong, nonatomic) IBOutlet UITextField *productPrice;


// Offer properties
@property (strong, nonatomic) IBOutlet UITableView *offersTable;
@property (strong, nonatomic) IBOutlet UITextField *offerTitleField;
@property (strong, nonatomic) IBOutlet UITextField *offerStraplineField;
@property (strong, nonatomic) IBOutlet UITextField *startDateField;
@property (strong, nonatomic) IBOutlet UITextField *endDateField;
@property (strong, nonatomic) IBOutlet UITextField *startTimeField;
@property (strong, nonatomic) IBOutlet UITextField *endTimeField;
@property (strong, nonatomic) IBOutlet UITextView *descriptionField;
@property (strong, nonatomic) IBOutlet UIButton *saveOffer;
@property (strong, nonatomic) IBOutlet UIButton *resetForm;

// Possible actions
- (IBAction)changeCategory:(id)sender;
- (IBAction)productChange:(id)sender;
- (IBAction)changePhoto:(id)sender;
- (IBAction)saveAllChanges:(id)sender;
- (IBAction)saveOfferButton:(id)sender;
- (IBAction)resetFormButton:(id)sender;

@end
