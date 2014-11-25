//
//  LGBeaconCellLayout.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 10/3/14.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import "LGBeaconCellLayout.h"

@implementation LGBeaconCellLayout

- (NSArray *) layoutAttributesForElementsInRect:(CGRect)rect
{
	NSArray *answer = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
	
	for(int i = 1; i < [answer count]; ++i)
	{
		UICollectionViewLayoutAttributes *currentLayoutAttributes = answer[i];
		UICollectionViewLayoutAttributes *prevLayoutAttributes = answer[i - 1];
		NSInteger maximumSpacing = 15;
		NSInteger origin = CGRectGetMaxX(prevLayoutAttributes.frame);
		
		if(origin + maximumSpacing + currentLayoutAttributes.frame.size.width < self.collectionViewContentSize.width)
		{
			CGRect frame = currentLayoutAttributes.frame;
			frame.origin.x = origin + maximumSpacing;
			currentLayoutAttributes.frame = frame;
		}
	}
	
	return answer;
}

@end
