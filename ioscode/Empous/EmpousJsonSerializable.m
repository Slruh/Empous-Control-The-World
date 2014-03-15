//
//  EmpousJsonSerializable.m
//  Empous
//
//  Created by Ryan Personal on 11/30/13.
//  Copyright (c) 2013 HurleyProg. All rights reserved.
//

#import "EmpousJsonSerializable.h"

@implementation EmpousJsonSerializable

+(NSDictionary*)colorAsDict:(ccColor4B)color
{
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedChar:color.a], @"a", [NSNumber numberWithUnsignedChar:color.r], @"r", [NSNumber numberWithUnsignedChar:color.g], @"g", [NSNumber numberWithUnsignedChar:color.b] ,@"b", nil];
}

+(ccColor4B)colorFromDict:(NSDictionary*)dict
{
    return ccc4([[dict objectForKey:@"r"] intValue], [[dict objectForKey:@"g"] intValue], [[dict objectForKey:@"b"] intValue], [[dict objectForKey:@"a"] intValue]);
}

+(NSDictionary*)pointAsDict:(CGPoint)point
{
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:point.x], @"xcoor", [NSNumber numberWithFloat:point.y], @"ycoor", nil];
}

+(NSArray*)setOfCoordinatesToArray:(NSSet*)set
{
    NSMutableArray* coords = [[[NSMutableArray alloc] init] autorelease];
    for (id coord in set)
    {
        [coords addObject:[NSArray arrayWithObjects:[coord objectAtIndex:0],[coord objectAtIndex:1], nil]];
    }
    return coords;
}

+(NSMutableSet*)arrayOfCoordinatesToSet:(NSArray*)array
{
    NSMutableSet* set = [[[NSMutableSet alloc] init] autorelease];
    for (int i = 0; i < [array count]; i++)
    {
        [set addObject:[array objectAtIndex:i]];
    }
    return set;
}

@end
