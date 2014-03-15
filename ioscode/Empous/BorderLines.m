//
//  BorderLines.m
//  Empous
//
//  Created by Ryan Personal on 1/1/14.
//  Copyright (c) 2014 HurleyProg. All rights reserved.
//

#import "BorderLines.h"
#import "Tools.h"

@implementation BorderLines

+ (id) nodeWithMap:(Map*)map
{
    return [[[self alloc] initWithMap:map] autorelease];
}

- (id)initWithMap:(Map*)map
{
    self = [super init];
    if (self) {
        linesToDraw = [[NSMutableSet alloc] init];
        
        //Go through the map and add all the border lines for every territory
        for (TerritoryElement* territory in [map territories])
        {
            CGPoint labelLocation = [territory labelLocation];
            for (TerritoryElement* border in [territory borders])
            {
                CGPoint neighborLabelLocation = [border labelLocation];
                
                //Check for both ways the line could have been made
                CGLine firstLine = CGLineMake(labelLocation, neighborLabelLocation);
                CGLine secondLine = CGLineMake(neighborLabelLocation, labelLocation);
                
                NSValue* firstLineData = [NSValue valueWithBytes:&firstLine objCType:@encode(CGLine)];
                NSValue* secondLineData = [NSValue valueWithBytes:&secondLine objCType:@encode(CGLine)];

                //If it doesn't exist yet, add it
                if (![linesToDraw containsObject:firstLineData] && ![linesToDraw containsObject:secondLineData])
                {
                    [linesToDraw addObject:firstLineData];
                }
            }
        }
    }
    
    return self;
}

-(void)dealloc
{
    [linesToDraw release];
    [super dealloc];
}

-(void) draw
{
    //Set color and line width
    glLineWidth(8.0f);
    
    for(NSValue* lineData in linesToDraw){
        CGLine line;
        
        [lineData getValue:&line];
        
        CGPoint startCorrected = [Tools mapLabelLocationToWorld:line.point1];
        CGPoint endCorrected = [Tools mapLabelLocationToWorld:line.point2];
        
        ccDrawColor4F(0.2,0.2,0.2,1.0);
        ccDrawLine(startCorrected, endCorrected);
    }
}


@end
