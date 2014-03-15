//
//  GameMenu+Opacity.m
//  Empous
//
//  Created by Ryan Hurley on 4/9/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "GameMenu+Opacity.h"

@implementation GameMenu (Opacity)

// Set the opacity of all of our children that support it - Warning are unvoidable
-(void) setOpacity: (GLubyte) opacity
{
    for( CCNode *node in [self children] )
    {
        if( [node conformsToProtocol:@protocol( CCRGBAProtocol)] )
        {
            [(id<CCRGBAProtocol>) node setOpacity: opacity];
        }
    }
}
-(GLubyte) opacity
{
    for( CCNode *node in [self children] )
    {
        if( [node conformsToProtocol:@protocol( CCRGBAProtocol)] )
        {
            return [(id<CCRGBAProtocol>)node opacity];
        }
    }
}
@end