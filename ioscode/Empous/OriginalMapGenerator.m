//
//  OriginalMapGenerator.m
//  Empous
//
//  Created by Ryan Hurley on 1/16/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "OriginalMapGenerator.h"
#import "Map.h"
#import "TerritoryElement.h"
#import "Tools.h"

@implementation OriginalMapGenerator

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (Map*) createMapWithWidth:(int)width andHeight:(int)height withNumberOfTerritories:(int) numberOfTerritories;
{
    Map* map = [super createMapWithWidth:width andHeight:height withNumberOfTerritories:numberOfTerritories];

    if (map == nil)
    {
        return nil;
    }
    
    //Check to make sure all the territories are reachable
    if(![self checkAllTerritoriesConnected:map])
    {
        return nil;
    }
    
    return map;
}

+(BOOL)checkAllTerritoriesConnected:(Map*)map
{
    //Pick the first territory then make sure you can get to all the others
    TerritoryElement* randomStart = [[map territories] anyObject];
    NSMutableDictionary* seenTerritories = [NSMutableDictionary dictionaryWithObjectsAndKeys:randomStart,[NSString stringWithFormat:@"%d",[randomStart tId]], nil];
    [self checkConnectedHelper:randomStart withPreviouslySeenTerritories:seenTerritories];
    if([seenTerritories count] == [map numberOfTerritories])
    {
        return YES;
    }
    return NO;
}

+(void)checkConnectedHelper:(TerritoryElement*)current withPreviouslySeenTerritories:(NSMutableDictionary*) seenTerritories
{
    NSMutableSet* neighbors = [current borders];
    for(TerritoryElement* neighbor in neighbors){
        
        //If the territory hasn't been seen yet
        if([seenTerritories objectForKey:[NSString stringWithFormat:@"%d", [neighbor tId]]] == nil){
            //Add the territory to the seen list
            [seenTerritories setValue:neighbor forKey:[NSString stringWithFormat:@"%d",[neighbor tId]]];
            [self checkConnectedHelper:neighbor withPreviouslySeenTerritories:seenTerritories];
        }
    }
}

@end





