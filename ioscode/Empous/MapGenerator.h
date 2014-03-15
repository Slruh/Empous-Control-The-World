//
//  MapGenerator.h
//  Empous
//
//  Created by Ryan Hurley on 1/16/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Map.h"
#import "TerritoryElement.h"

@interface MapGenerator : NSObject

#define EXPAND_DIST 1 //Distance each expand iteration travels
#define EXPAND_NUM 4 //Number of times a territory will expand before it is complete
#define MIN_EXPAND_CHANCE 10 //The minimum chance of expanding

/**
 * This can return nil if the map is not build correctly. It is up to the caller to call again if the making 
 * fails.
 *
 * Many times you will only call this method then do some extra work to verify the map is what you want
 */
+ (Map*) createMapWithWidth:(int)width andHeight:(int)height withNumberOfTerritories:(int) numberOfTerritories;

/**
 * Decides if a territory is valid. By default this makes sure 
 * that the territories aren't too skinny.
 */
+ (BOOL) acceptableTerritory:(Map*)map :(TerritoryElement*)territory;

/**
 * Returns the minimum distance between territory center placement
 */
+ (int) minimumDistanceBetweenTerritories;

/**
 * Returns the distance from the edge that territories can be placed
 */
+ (int) edgeBufferSize;

@end

