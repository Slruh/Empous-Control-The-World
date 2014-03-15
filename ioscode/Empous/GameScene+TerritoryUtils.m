//
//  GameSceneTerritory.m
//  Empous
//
//  Created by Ryan Hurley on 4/9/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "GameScene+TerritoryUtils.h"
#import "GameScene.h"
#import "Tools.h"

@implementation GameScene (TerritoryUtils)

-(void)pulseOnPlayerTerritories
{
    for (TerritoryElement* territory in [thisPlayer territories])
    {
        NSMutableSet* controlledTiles = [territory controlledCoordinates];
        //Color all the tiles that territory controls
        for(NSMutableArray* tileLocation in controlledTiles){
            int xLoc = [(NSNumber*)[tileLocation objectAtIndex:0] intValue];
            int yLoc = [(NSNumber*)[tileLocation objectAtIndex:1] intValue];
            CCSprite* tile = [mapTiles tileAt:[Tools mapToTileMap:gameMap point:CGPointMake(xLoc, yLoc)]];

            CCTintBy* brighten = [CCTintBy actionWithDuration:1 red:75 green:75 blue:75];
            CCCallFunc* function = [CCCallFuncN actionWithTarget:self selector:@selector(pulseOffSprite:)];
            CCSequence* pulseSequence = [CCSequence actionWithArray:[NSArray arrayWithObjects:brighten,function, nil]];
            
            [tile runAction:pulseSequence];
        }
    }
}

-(void)stopPulsePlayerTerritories
{
    [self updateTileMap];
    for (TerritoryElement* territory in [thisPlayer territories])
    {
        NSMutableSet* controlledTiles = [territory controlledCoordinates];
        //Color all the tiles that territory controls
        for(NSMutableArray* tileLocation in controlledTiles){
            int xLoc = [(NSNumber*)[tileLocation objectAtIndex:0] intValue];
            int yLoc = [(NSNumber*)[tileLocation objectAtIndex:1] intValue];
            CCSprite* tile = [mapTiles tileAt:[Tools mapToTileMap:gameMap point:CGPointMake(xLoc, yLoc)]];
            [tile stopAllActions];
        }
    }
}

-(void)pulseOnSprite:(CCNode*)node
{
    CCTintBy* brighten = [CCTintBy actionWithDuration:1 red:75 green:75 blue:75];
    CCCallFunc* function = [CCCallFuncN actionWithTarget:self selector:@selector(pulseOffSprite:)];
    CCSequence* pulseSequence = [CCSequence actionWithArray:[NSArray arrayWithObjects:brighten,function, nil]];
    [node runAction:pulseSequence];
}

-(void)pulseOffSprite:(CCNode*)node
{
    CCTintBy* brighten = [CCTintBy actionWithDuration:1 red:-75 green:-75 blue:-75];
    CCCallFunc* function = [CCCallFuncN actionWithTarget:self selector:@selector(pulseOnSprite:)];
    CCSequence* pulseSequence = [CCSequence actionWithArray:[NSArray arrayWithObjects:brighten,function, nil]];
    [node runAction:pulseSequence];
}

-(void)highlightTerritory:(TerritoryElement*)territory{
    NSMutableSet* controlledTiles = [territory controlledCoordinates];
    
    //If already highlighted then unhighlight it
    char bright = 75;
    if([territory highlighted] == YES){
        bright = -75;
        [territory setHighlighted:NO];
        
    }else{
        [territory setHighlighted:YES];
    }
    
    //Color all the tiles that territory controls
    for(NSMutableArray* tileLocation in controlledTiles){
        int xLoc = [(NSNumber*)[tileLocation objectAtIndex:0] intValue];
        int yLoc = [(NSNumber*)[tileLocation objectAtIndex:1] intValue];
        
        CCSprite* tile = [mapTiles tileAt:[Tools mapToTileMap:gameMap point:CGPointMake(xLoc, yLoc)]];
        ccColor3B tileColor = [tile color];
        ccColor3B newColor = {MIN(255,tileColor.r + bright),MIN(255,tileColor.g + bright),MIN(255,tileColor.b + bright)};
        [tile setColor:newColor];
    }
}

-(void)highlightConnectedFriendlyTerritories:(TerritoryElement*)territory
{
    NSMutableDictionary* seenTerritories = [NSMutableDictionary dictionaryWithObjectsAndKeys:territory,[NSString stringWithFormat:@"%d",[territory tId]], nil];
    [self highlightTerritoryHelper:territory withPreviouslySeenTerritories:seenTerritories];
}

-(void)highlightTerritoryHelper:(TerritoryElement*)current withPreviouslySeenTerritories:(NSMutableDictionary*) seenTerritories
{
    NSMutableSet* friendlyTerritories = [current friendlyTerritories];
    for(TerritoryElement* friend in friendlyTerritories){
        
        //Add the line
        [attackLines addLineFrom:[current labelLocation] toEnd:[friend labelLocation]];
        
        //If the territory hasn't been seen yet
        if([seenTerritories objectForKey:[NSString stringWithFormat:@"%d", [friend tId]]] == nil){
            //Add the territorye to the seen list
            [seenTerritories setValue:friend forKey:[NSString stringWithFormat:@"%d",[friend tId]]];
            [self highlightTerritoryHelper:friend withPreviouslySeenTerritories:seenTerritories];
        }
    }
}

-(BOOL)isFirstTerritoryConnected:(TerritoryElement*)territoryStart toSecondTerritory:(TerritoryElement*)territoryEnd
{
    //Check to see if the start and end are
    if([territoryStart empousId] != [territoryEnd empousId]){
        return NO;
    }
    
    if([territoryStart tId] == [territoryEnd tId]){
        return NO;
    }
    
    //Create a dictionary with the first territory
    NSMutableDictionary* seenTerritories = [NSMutableDictionary dictionaryWithObjectsAndKeys:territoryStart, [NSString stringWithFormat:@"%d",[territoryStart tId]], nil];
    return [self territoryConnectedHelper:territoryStart goalTerritory:territoryEnd visitedTerritories:seenTerritories];
}

-(BOOL)territoryConnectedHelper:(TerritoryElement*)current goalTerritory:(TerritoryElement*)goal visitedTerritories:(NSMutableDictionary*)seenTerritories
{
    NSMutableSet* friendlyTerritories = [current friendlyTerritories];
    for(TerritoryElement* friend in friendlyTerritories)
    {
        //If the territory hasn't been seen yet
        if([seenTerritories objectForKey:[NSString stringWithFormat:@"%d", [friend tId]]] == nil)
        {
            if([friend tId] == [goal tId])
            {
                return YES;
            }else{
                //Add the territorye to the seen list
                [seenTerritories setValue:friend forKey:[NSString stringWithFormat:@"%d",[friend tId]]];
                if([self territoryConnectedHelper:friend goalTerritory:goal visitedTerritories:seenTerritories]){
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

@end
