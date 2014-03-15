//
//  Map.h
//  Empous
//
//  Created by Ryan Hurley on 1/19/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapElement.h"
#import "TMXGenerator.h"
#import "TerritoryElement.h"
#import "cocos2d.h"
#import "EmpousJsonSerializable.h"


@interface Map : CCLayer <TMXGeneratorDelegate,NSCoding, EmpousSerializable>
{
    @public
        NSMutableArray* map; // MapElement*
        NSMutableArray* tiles; //NSNumbers which represent the tile that should be used
        NSMutableSet* territories; //List of all the TerritoryElement*
        NSMutableDictionary* territoryLookup; //Used when restoring from serialized formats
        int width;
        int height;
        int numberOfTerritories;
}

#pragma mark -
#pragma mark Instance Methods
@property int height;
@property int width;
@property (retain) NSMutableSet* territories;
@property int numberOfTerritories;
@property (retain) NSDictionary* territoryLookup;

-(id) initWithWidth:(int)_width withHeight:(int)_height andNumberOfTerritories:(int)_numberOfTerritories;
-(BOOL) isWaterAtXLoc:(int)x andYLoc:(int)y;
-(MapElement*) getElementAtXLoc:(int)x andYLoc:(int)y;
-(TerritoryElement*) getTerritoryAt:(CGPoint)xylocation;
- (NSString*) mapFilePath;

#pragma mark -
#pragma mark Map Constants

#define NO_BORDER 0x00
#define NORTH 0x01
#define EAST 0x02
#define SOUTH 0x04
#define WEST 0x08

#pragma mark -
#pragma mark Map Delegate Constants

#define tileSetWidth                    80
#define tileSetHeight                   80
#define kNumPixelsPerTileSquare			16
#define kNumPixelsBetweenTiles			0

#define kTerritoryAtlasKey              @"TerritoryType" 
#define kTerritoryLayerName             @"Territories"
#define kTerritoryTileSetName           @"TerritoryTileSet"
#define kTerritoryTileSetFile           @"TerritoryTileSet.png"
#define numOfBorderTiles                17
#define mapFile                         @"testMap.tmx"

typedef enum {
	kTerritoryNone = 0,
	kTerritoryWest,
	kTerritorySouth,
	kTerritoryEast,
	kTerritoryNorth,
    kTerritoryNorthWest,
    kTerritoryNorthEast,
    kTerritorySouthEast,
    kTerritorySouthWest,
    kTerritoryEastWest,
    kTerritoryNorthSouth,
    kTerritoryWestNorthEast,
    kTerritoryNorthEastSouth,
    kTerritoryNorthWestSouth,
    kTerritoryEastSouthWest,
    kTerritoryAll,
    kTerritoryBlank
} territoryBorderType;


@end
