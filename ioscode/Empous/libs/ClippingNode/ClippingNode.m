//
//  ClippingNode.m
//  Empous
//
//  Created by Ryan Personal on 3/3/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "ClippingNode.h"

@interface ClippingNode (PrivateMethods)
-(void) deviceOrientationChanged:(NSNotification*)notification;
@end

@implementation ClippingNode

-(id) init
{
    if ((self = [super init]))
    { }
    return self;
}

-(void) dealloc
{
    [super dealloc];
}

-(CGRect) clippingRegion
{
    return clippingRegionInNodeCoordinates;
}

-(void) setClippingRegion:(CGRect)region
{
    // keep the original region coordinates in case the user wants them back unchanged
    clippingRegionInNodeCoordinates = region;
    self.contentSize = clippingRegionInNodeCoordinates.size;
    
    // convert to retina coordinates if needed
    region = CC_RECT_POINTS_TO_PIXELS(region);
    
    // respect scaling
    clippingRegion = CGRectMake(region.origin.x * _scaleX, region.origin.y * _scaleY,
                                region.size.width * _scaleX, region.size.height * _scaleY);
}

-(void) setScale:(float)newScale
{
    [super setScale:newScale];
    // re-adjust the clipping region according to the current scale factor
    [self setClippingRegion:clippingRegionInNodeCoordinates];
}

-(void) visit
{
    glEnable(GL_SCISSOR_TEST);
    glScissor(clippingRegion.origin.x + _position.x, clippingRegion.origin.y + _position.y,
              clippingRegion.size.width, clippingRegion.size.height);
    
    [super visit];
    
    glDisable(GL_SCISSOR_TEST);
}

@end
