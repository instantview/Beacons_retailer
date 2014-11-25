//
//  LGBeaconCell.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 10/6/14.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import "LGBeaconCell.h"

@implementation LGBeaconCell

@synthesize beaconLabel;
@synthesize beaconImageView;

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self){
		[self setup];
	}
	
	return self;
}

- (void)setup
{
	self.beaconImageView = [UIImageView new];
	self.beaconImageView.frame = CGRectMake(self.bounds.origin.x + 10, self.bounds.origin.y + 10, 220, 220);
	
	self.beaconLabel = [UILabel new];
	self.beaconLabel.frame = CGRectMake(self.bounds.origin.x,
										self.bounds.origin.y + 240,
										self.bounds.size.width,
										30);
	self.beaconLabel.textAlignment = NSTextAlignmentCenter;
	self.beaconLabel.font = [UIFont systemFontOfSize:15.0f];
	
	[self addSubview:beaconImageView];
	[self addSubview:beaconLabel];
}

@end
