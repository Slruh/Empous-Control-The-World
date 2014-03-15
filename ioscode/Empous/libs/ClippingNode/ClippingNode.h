//
//  ClippingNode.h
//  Empous
//
//  Created by Ryan Personal on 3/3/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "cocos2d.h"

/** Restricts (clips) drawing of all children to a specific region. */
@interface ClippingNode : CCNode
{
    CGRect clippingRegionInNodeCoordinates;
    CGRect clippingRegion;
}

@property (nonatomic) CGRect clippingRegion;

@end
