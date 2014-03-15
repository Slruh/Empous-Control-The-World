//
//  MapGenerator.m
//  Empous
//
//  Created by Ryan Hurley on 1/16/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "MapGenerator.h"
#import "Map.h"
#import "TerritoryElement.h"
#import "Tools.h"

@implementation MapGenerator

+ (Map*) createMapWithWidth:(int)width andHeight:(int)height withNumberOfTerritories:(int) numberOfTerritories;
{
    //Create a new empty map with the dimensions based of the number of territories
    Map* map = [[[Map alloc] initWithWidth:width withHeight:height andNumberOfTerritories:numberOfTerritories] autorelease];
    int success = 1;
    
    if (success) {
        NSLog(@"PLACE - putting territories on the map");
        success = [self placeTerritories: map];
    }
    
    if (success) {
        NSLog(@"EXPAND - incrementally expanding each territory");
        success = [self expandTerritories: map];
    }
    
    if (success){
        NSLog(@"TILE - building tile array for map generation");
        success = [self defineTileMap: map];
    }
    
    if (success){
        NSLog(@"TERRITORY PROPERTIES - predefining map properties");
        success = [self predefineProperties: map];
    }
    
    if (success)
    {
        return map;
    }
    
    return nil;
}


/**
 * PLACING TERRITORIES
 **/

//Randomly place territories on map object
+ (BOOL) placeTerritories: (Map*) map
{
    int randx, randy;
    bool territoryPlaced;
    int tries, maxTries = 1000;
    
    //Create the designated number of territories 
    for (int tId = 0; tId < map->numberOfTerritories; tId++)
    {
        territoryPlaced = NO;
        tries = 0;
        //Keep trying until you place the territory
        while (!territoryPlaced && tries < maxTries)
        {
            randx = arc4random() % map->width;
            randy = arc4random() % map->height;
            if([MapGenerator acceptTerritoryLoc: map: randx: randy]){
                [MapGenerator createTerritoryAt: map: tId: randx: randy];
                territoryPlaced = YES;
            }
            tries++;
        }
        if (tries == maxTries){
            return 0;
        }
    }
    return 1;
}

//Acceptable territory location parameters defined here
+ (BOOL) acceptTerritoryLoc:(Map*)map :(int)x :(int)y;
{
    int xStart, xEnd, yStart, yEnd;
    
    int minimumDistance = [self minimumDistanceBetweenTerritories];
    int edgeBuffer = [self edgeBufferSize];
    
    //Make sure the x is not within the edge buffer
    xStart = x - minimumDistance;
    xEnd = x + minimumDistance;
    if (xStart < edgeBuffer)
        return NO;
    if (xEnd >= map->width - edgeBuffer)
        return NO;
    
    //Make sure the y is not within the edge buffer
    yStart = y - minimumDistance;
    yEnd = y + minimumDistance;
    if (yStart < edgeBuffer)
        return NO;
    if (yEnd >= map->height - edgeBuffer)
        return NO;
    
    //Make sure there is only water in the zone
    for (int curX = xStart; curX < xEnd; curX++){
        for (int curY = yStart; curY < yEnd; curY++){
            if (![map isWaterAtXLoc:curX andYLoc:curY]){
                return NO;
            }
        }
    }
    
    return YES;
}

//Creates a new Territory at the given index and adds it to the territories list
+ (void) createTerritoryAt:(Map*)map :(int)tId :(int)x :(int) y;
{
    TerritoryElement* newTerritory = [[TerritoryElement alloc] initWithId:tId xLoc:x yLoc:y];
    [[map->map objectAtIndex: x] replaceObjectAtIndex:y withObject: newTerritory];
    [map->territories addObject: newTerritory];
    [newTerritory release];
}


/**
 * EXPANDING TERRITORIES
 **/

//Iterate through each territory and expand it
+ (BOOL) expandTerritories: (Map*) map
{
    for (int expandIter = 0; expandIter < EXPAND_NUM; expandIter++){
        for (TerritoryElement* curTerritory in map->territories){
            [MapGenerator expandTerritory: map: curTerritory];
        }
    }
    
    //Check the case where territories are touching but never expanded into each other
    for (TerritoryElement* curTerritory in map->territories){
        [self checkBordersForAdjacentTerritories:curTerritory andMap:map];
    }

    return 1;
}

+(void)checkBordersForAdjacentTerritories:(TerritoryElement*)territory andMap:(Map*)map
{
    int x, y, xStart, xEnd, yStart, yEnd;
    for (NSMutableArray* coordinates in territory->borderCoordinates){
        x = [[coordinates objectAtIndex: 0] intValue];
        y = [[coordinates objectAtIndex: 1] intValue];
        
        xStart = [Tools chooseMaxIntOf:0 and:x - 1];
        xEnd = [Tools chooseMinIntOf:map->width - 1 and:x + 1];
        
        yStart = [Tools chooseMaxIntOf:0 and:y - 1];
        yEnd = [Tools chooseMinIntOf:map->height - 1 and:y + 1];
        
        for (int curX = xStart; curX <= xEnd; curX++){
            for (int curY = yStart; curY <= yEnd; curY++){
                if (curX == x || curY == y){
                    if ([[map getElementAtXLoc:curX andYLoc:curY] kind] == TERRITORY)
                    {
                        TerritoryElement* borderTerritory = (TerritoryElement*) [map getElementAtXLoc:curX andYLoc:curY];
                        [territory->borders addObject: borderTerritory];
                        [borderTerritory->borders addObject: territory];
                    }
                }
            }
        }
    }
}

//Expand the specified territory
+ (void) expandTerritory:(Map*)map :(TerritoryElement*) territory;
{
    NSMutableSet* newBorder = [[NSMutableSet alloc] init];
    int rand, x, y, xStart, xEnd, yStart, yEnd;
    int expandChance; //expandChance% Chance
    bool addXY;
    
    for (NSMutableArray* coordinates in territory->borderCoordinates){
        x = [[coordinates objectAtIndex: 0] intValue];
        y = [[coordinates objectAtIndex: 1] intValue];
        addXY = NO;
        
        xStart = [Tools chooseMaxIntOf:0 and: x - 1];
        xEnd = [Tools chooseMinIntOf:map->width - 1 and: x + 1];
        
        yStart = [Tools chooseMaxIntOf:0 and: y - 1];
        yEnd = [Tools chooseMinIntOf:map->height - 1 and: y + 1];
        
        
        for (int curX = xStart; curX <= xEnd; curX++){
            for (int curY = yStart; curY <= yEnd; curY++){
                if (curX == x || curY == y){
                    if ([map isWaterAtXLoc:curX andYLoc:curY]){
                        expandChance = [MapGenerator calcExpandChance: territory];
                        rand = arc4random() % 100;
                        if (rand < expandChance){
                            [[map->map objectAtIndex: curX] replaceObjectAtIndex:curY withObject:territory];
                            
                            NSMutableArray* newCoordinates = [[NSMutableArray alloc] initWithCapacity: 2];
                            [Tools insertIntIntoNSMutableArray:newCoordinates index:0 value:curX];
                            [Tools insertIntIntoNSMutableArray:newCoordinates index:1 value:curY];
                            
                            [territory->controlledCoordinates addObject: newCoordinates];
                            [newBorder addObject: newCoordinates];
                            [newCoordinates release];
                        } else {
                            addXY = YES;
                        }
                    } else if ([[map getElementAtXLoc:curX andYLoc:curY] kind] == TERRITORY)  {
                        TerritoryElement* borderTerritory = (TerritoryElement*) [map getElementAtXLoc:curX andYLoc:curY];
                        [territory->borders addObject: borderTerritory];
                        [borderTerritory->borders addObject: territory];
                    }
                }
            }
        }
        
        if (addXY){
            NSMutableArray* newCoordinates = [[NSMutableArray alloc] initWithCapacity: 2];
            [Tools insertIntIntoNSMutableArray:newCoordinates index:0 value:x];
            [Tools insertIntIntoNSMutableArray: newCoordinates index:1 value:y];
            
            [territory->controlledCoordinates addObject: newCoordinates];
            [newBorder addObject: newCoordinates];
            [newCoordinates release];
        }
                
        territory->borderCoordinates = newBorder;
    }
}

//Returns the chance of territory expansion
+ (int) calcExpandChance:(TerritoryElement*)territory
{
    double minArea = 5;
    double maxArea = 40;
    double area = [Tools chooseMaxIntOf:[territory->controlledCoordinates count] and:minArea];
    double chance = 1 - (area - minArea) / maxArea;
    return [Tools chooseMinIntOf:(int)(MIN_EXPAND_CHANCE + chance * 100) and:100];
}

/**
 * MAP DRAWING UTILITIES
 **/

//Goes through each element and determine which tile to use
+ (BOOL) defineTileMap:(Map*)map
{
    for (int x = 0; x < map->width; x++){
        for (int y = 0; y < map->height; y++){
            int curTileBorder = [MapGenerator calcCurBorder:map :x :y];
            [Tools insertIntIntoNSMutableArray:map->tiles row:x col:y value:curTileBorder];
        }
    }
    return 1;
}

//Calculates the borders for a given map element
//Used to determine which tile to use
+ (int) calcCurBorder:(Map*)map :(int)x :(int) y
{
    MapElement* curElement = [map getElementAtXLoc:x andYLoc:y];
    MapElement* adjElement;
    int curBorder = NO_BORDER;
    
    if (curElement->kind == TERRITORY){
        TerritoryElement* curTElement = (TerritoryElement*)curElement;
        if (x - 1 >= 0){
            adjElement = [map getElementAtXLoc:x-1 andYLoc:y];
            if (adjElement->kind == TERRITORY){
                if (((TerritoryElement*)adjElement)->tId != curTElement->tId){
                    curBorder |= EAST;
                }
            } else {
                curBorder |= EAST;
            }
        }
        if (x + 1 < map->width){
            adjElement = [map getElementAtXLoc:x+1 andYLoc:y];
            if (adjElement->kind == TERRITORY){
                if (((TerritoryElement*)adjElement)->tId != curTElement->tId){
                    curBorder |= WEST;
                }
            } else {
                curBorder |= WEST;
            }
        }
        if (y - 1 >= 0){
            adjElement = [map getElementAtXLoc:x andYLoc:y-1];
            if (adjElement->kind == TERRITORY){
                if (((TerritoryElement*)adjElement)->tId != curTElement->tId){
                    curBorder |= NORTH;
                }
            } else {
                curBorder |= NORTH;
            }
        }
        if (y + 1 < map->height){
            adjElement = [map getElementAtXLoc:x andYLoc:y+1];
            if (adjElement->kind == TERRITORY){
                if (((TerritoryElement*)adjElement)->tId != curTElement->tId){
                    curBorder |= SOUTH;
                }
            } else {
                curBorder |= SOUTH;
            }
        }
    }
    return curBorder;
}

/**
 * MAP PROPERTY DEFINITIONS
 **/
+ (BOOL) predefineProperties:(Map*)map
{
    for (TerritoryElement* territory in map->territories)
    {
        //Ensure Good Territories
        BOOL result = [MapGenerator acceptableTerritory: map: territory];
        if (!result)
        {
            return NO;
        }
        
        //Label Placement
        [MapGenerator defineLabelLocation: map: territory];
    }
    
    return YES;
}

+ (BOOL) acceptableTerritory:(Map*)map :(TerritoryElement*)territory
{
    NSMutableArray* coordinate = [[[NSMutableArray alloc] init] autorelease];
    int x, y;
    
    //Disallow Skinny Territories
    int numBorderless = 0;
    double minPercentBorderless = 10 / 100; //10% Borderless
    for (coordinate in [territory controlledCoordinates]){
        x = [[coordinate objectAtIndex:0] intValue];
        y = [[coordinate objectAtIndex:1] intValue];
        if ([[map->tiles objectAtIndex:x] objectAtIndex:y] != NO_BORDER)
            numBorderless++;
        
    }
    if (numBorderless / [[territory controlledCoordinates] count] < minPercentBorderless)
        return NO;
    
    return YES;
}

+ (void) defineLabelLocation:(Map*)map :(TerritoryElement*)territory
{
    NSMutableArray* coordinate = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray* candidateCoordinates = [NSMutableArray arrayWithArray: [[territory controlledCoordinates] allObjects]];
    NSMutableArray* removeCoordinateSet = [[[NSMutableArray alloc] init] autorelease];
    bool shaved = NO, remove = NO;
    int numBorders;
    int x, y;
    int minY, maxY, minX, maxX;
    int numAtXMax, numAtXMin, numAtYMax, numAtYMin;
    int maxAtExtreme = 1;
    double averageX, averageY;
    double distFromAverage, minDistFromAverage = 1000;
    
    for (coordinate in candidateCoordinates){
        x = [[coordinate objectAtIndex:0] intValue];
        y = [[coordinate objectAtIndex:1] intValue];
        numBorders = [[[map->tiles objectAtIndex: x] objectAtIndex: y] intValue];
        if (numBorders != NO_BORDER){
            [removeCoordinateSet addObject: coordinate];
        }
    }
    [candidateCoordinates removeObjectsInArray: removeCoordinateSet];
    [removeCoordinateSet removeAllObjects];
    
    while (!shaved){
        numAtXMax = 0;
        numAtXMin = 0;
        numAtYMax = 0;
        numAtYMin = 0;
        minY = map->height;
        maxY = -1;
        minX = map->width;
        maxX = -1;
        
        for (coordinate in candidateCoordinates){
            x = [[coordinate objectAtIndex:0] intValue];
            y = [[coordinate objectAtIndex:1] intValue];
            
            maxX = [Tools chooseMaxIntOf:maxX and:x];
            minX = [Tools chooseMinIntOf:minX and:x];
            maxY = [Tools chooseMaxIntOf:maxY and:y];
            minY = [Tools chooseMinIntOf:minY and:y];
        }
        
        for (coordinate in candidateCoordinates){
            x = [[coordinate objectAtIndex:0] intValue];
            y = [[coordinate objectAtIndex:1] intValue];
            
            if (x == maxX) numAtXMax++;
            if (x == minX) numAtXMin++;
            if (y == maxY) numAtYMax++;
            if (y == minY) numAtYMin++;
        }
        
        if ([candidateCoordinates count] > 1 &&
            (numAtXMax <= maxAtExtreme || numAtXMin <= maxAtExtreme || numAtYMax <= maxAtExtreme || numAtYMin <= maxAtExtreme)){
            shaved = NO;
            for (coordinate in candidateCoordinates){
                x = [[coordinate objectAtIndex:0] intValue];
                y = [[coordinate objectAtIndex:1] intValue];
                
                if ((numAtXMax <= maxAtExtreme && x == maxX) || (numAtXMin <= maxAtExtreme && x == minX) || 
                    (numAtYMax <= maxAtExtreme && y == maxY) || (numAtYMin <= maxAtExtreme && y == minY))
                    remove = YES;
                else
                    remove = NO;
                
                if (remove){
                    [removeCoordinateSet addObject: coordinate];
                }
                
                if ([candidateCoordinates count] - [removeCoordinateSet count] == 1)
                    break;
            }
            [candidateCoordinates removeObjectsInArray: removeCoordinateSet];
            [removeCoordinateSet removeAllObjects];
        } else {
            shaved = YES;
        }
    }
    averageX = (double)(maxX + minX) / 2.0;
    averageY = (double)(maxY + minY) / 2.0;
    
    for (coordinate in candidateCoordinates){
        x = [[coordinate objectAtIndex:0] intValue];
        y = [[coordinate objectAtIndex:1] intValue];
        distFromAverage = (x - averageX) * (x - averageX) + (y - averageY) * (y - averageY);
        
        if (distFromAverage < minDistFromAverage) {
            minDistFromAverage = distFromAverage;
            [territory setLabelLocation: [Tools convertCoordinateArrayToCGPoint:coordinate]];
        }
    }
}

/**
 * Returns the minimum distance between territory center placement
 */
+ (int) minimumDistanceBetweenTerritories
{
    return 3;
}

/**
 * Returns the distance from the edge that territories can be placed
 */
+ (int) edgeBufferSize
{
    return 2;
}

@end





