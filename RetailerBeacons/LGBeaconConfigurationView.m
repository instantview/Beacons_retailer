//
//  LGBeaconConfigurationView.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 10/21/14.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import "LGBeaconConfigurationView.h"

@implementation LGBeaconConfigurationView

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self)
	{
		[self layoutView];
	}
	
	return self;
}

- (void)layoutView
{
	UILabel *label = [UILabel new];
	label.text = @"Hello world!";
	
	[self addSubview:label];
}

@end
