//
//  MapElement.m
//  Empous
//
//  Created by Ryan Hurley on 1/19/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "MapElement.h"

@implementation MapElement

@synthesize kind;

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

-(id)initWithXLoc:(int)x andYLoc:(int)y;
{
    self = [super init];
    if (self) {
        kind = WATER;
        xloc = x;
        yloc = y;
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:kind forKey:@"kind"];
    [aCoder encodeInt:xloc forKey:@"xloc"];
    [aCoder encodeInt:yloc forKey:@"yloc"];
}

-(NSDictionary*)toJSONDict
{
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kind], @"kind", [NSNumber numberWithInt:xloc], @"xloc",[NSNumber numberWithInt:yloc], @"yloc",nil];
}

-(id)initWithJsonData:(NSDictionary *)jsonData
{
    self = [super init];
    if (self)
    {
        kind = [[jsonData objectForKey:@"kind"] intValue];
        xloc = [[jsonData objectForKey:@"xloc"] intValue];
        yloc = [[jsonData objectForKey:@"yloc"] intValue];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        kind = [aDecoder decodeIntForKey:@"kind"];
        xloc = [aDecoder decodeIntForKey:@"xloc"];
        yloc = [aDecoder decodeIntForKey:@"yloc"];
    }
    return self;
}

@end
