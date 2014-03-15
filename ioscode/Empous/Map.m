//
//  Map.m
//  Empous
//
//  Created by Ryan Hurley on 1/19/12.
//  Copyright 2012 Apple. All rights reserved.
//

#include <stdlib.h>
#import "Map.h"
#import "MapElement.h"
#import "MapGenerator.h"
#import "Tools.h"

@implementation Map
@synthesize height;
@synthesize width;
@synthesize territories;
@synthesize territoryLookup;
@synthesize numberOfTerritories;

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

//Create a new map with the given number of territories
-(id) initWithWidth:(int)_width withHeight:(int)_height andNumberOfTerritories:(int)_numberOfTerritories
{
    self = [super init];
    if (self) {
        //Initialize the map, and all other arrays to make it a matrix
        width = _width;
        height = _height;
        numberOfTerritories = _numberOfTerritories;
        map = [[NSMutableArray alloc] initWithCapacity: width];
        tiles = [[NSMutableArray alloc] initWithCapacity: width];
        for (int xloop = 0; xloop < width; xloop++) 
        {
            [map addObject:[[[NSMutableArray alloc] initWithCapacity: height] autorelease]];
            [tiles addObject:[[[NSMutableArray alloc] initWithCapacity: height] autorelease]];
            for (int yloop = 0; yloop < height; yloop++){
                MapElement* element = [[MapElement alloc] initWithXLoc:xloop andYLoc:yloop];
                [[map objectAtIndex:xloop] addObject:element];
                [element release];
                [[tiles objectAtIndex:xloop] addObject:[NSNumber numberWithInt:-1]];
            }
        }
        
        //Initialize the territories
        territories = [[NSMutableSet alloc] initWithCapacity: numberOfTerritories];
    }
    return self;
}

-(void)dealloc
{
    [map release];
    [tiles release];
    [territories release];
    [super dealloc];
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:map forKey:@"map"];
    [aCoder encodeObject:tiles forKey:@"tiles"];
    [aCoder encodeObject:territories forKey:@"territories"];
    
    [aCoder encodeInt:width forKey:@"width"];
    [aCoder encodeInt:height forKey:@"height"];
    [aCoder encodeInt:numberOfTerritories forKey:@"numberOfTerritories"];
}

-(NSDictionary*)toJSONDict
{
    NSMutableDictionary* mapDict = [[[NSMutableDictionary alloc] init] autorelease];
    
    //Jsonify the map elements
    NSMutableArray* mapElementsArray = [[[NSMutableArray alloc] init] autorelease];
    for (int x = 0; x < width; x++)
    {
        NSMutableArray* mapElementsArrayY = [[[NSMutableArray alloc] init] autorelease];
        [mapElementsArray addObject:mapElementsArrayY];
        
        for (int y = 0; y < height; y++)
        {
            //Handle territories specially here
            MapElement* mapElement = [[map objectAtIndex:x] objectAtIndex:y];
            NSDictionary* mapElementDict = [mapElement toJSONDict];
            
            //If a territory add only the ID the territories will be recorded later
            if ([mapElement isKindOfClass:[TerritoryElement class]])
            {
                NSDictionary* territoryElementDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    [[mapElementDict objectForKey:@"map_element"] objectForKey:@"xloc"], @"xloc",
                    [[mapElementDict objectForKey:@"map_element"] objectForKey:@"yloc"], @"yloc",
                    [[mapElementDict objectForKey:@"map_element"] objectForKey:@"kind"], @"kind",
                    [mapElementDict objectForKey:@"territory_id"], @"territory_id",
                 nil];
                [mapElementsArrayY addObject:territoryElementDict];
            }
            else
            {
                [mapElementsArrayY addObject:mapElementDict];
            }
        }
    }
    
    [mapDict setValue:mapElementsArray forKey:@"map"];
    
    //Store the tiles
    [mapDict setValue:tiles forKey:@"tiles"];
    
    //Jsonify the territories
    NSMutableDictionary* territoryElementsDict = [[[NSMutableDictionary alloc] init] autorelease];
    for (TerritoryElement* element in territories)
    {
        [territoryElementsDict setObject:[element toJSONDict] forKey:[NSString stringWithFormat:@"%d",[element tId]]];
    }
    [mapDict setValue:territoryElementsDict forKey:@"territories"];
    
    //Store the numbers
    [mapDict setValue:[NSNumber numberWithInt:width] forKey:@"width"];
    [mapDict setValue:[NSNumber numberWithInt:height] forKey:@"height"];
    [mapDict setValue:[NSNumber numberWithInt:numberOfTerritories] forKey:@"number_of_territories"];
    
    return mapDict;
}

-(id)initWithJsonData:(NSDictionary *)jsonData
{
    self = [super init];
    if (self)
    {
        //Store the numbers
        width = [[jsonData objectForKey:@"width"] intValue];
        height = [[jsonData objectForKey:@"height"] intValue];
        numberOfTerritories = [[jsonData objectForKey:@"number_of_territories"] intValue];
        
        //Restore the territory elements
        territories = [[NSMutableSet alloc] init];
        territoryLookup = [[NSMutableDictionary alloc] init];
        
        NSDictionary* territoriesDict = [jsonData objectForKey:@"territories"];
        for(id territoryId in territoriesDict)
        {
            NSDictionary* territoryData = [territoriesDict objectForKey:territoryId];
            TerritoryElement* territoryElement = [[TerritoryElement alloc] initWithJsonData:territoryData];
            [territories addObject:territoryElement];
            [territoryLookup setObject:territoryElement forKey:territoryId];
            [territoryElement release];
        }
        
        //Fix the territory borders by going through the lookup map and updating numbers to be territories
        for (TerritoryElement* territory in territories)
        {
            NSSet* territoryBorderIds = [territory borders];
            NSMutableSet* newTerritoryBorders = [[NSMutableSet alloc] init];
            for (NSNumber* territoryId in territoryBorderIds)
            {
                TerritoryElement* territory = [territoryLookup objectForKey:[territoryId stringValue]];
                [newTerritoryBorders addObject:territory];
            }
            [territory setBorders:newTerritoryBorders];
            [newTerritoryBorders release];
        }
        
        //Set up the tiles
        tiles = [[jsonData objectForKey:@"tiles"] retain];
        
        //Go through all the map elements and construct Map/Territory Elements as necessary
        NSArray* mapJson = [jsonData objectForKey:@"map"];
        map = [[NSMutableArray alloc] init];
        
        for (int x = 0; x < width; x++)
        {
            NSMutableArray* mapY = [[NSMutableArray alloc]init];
            [map addObject:mapY];
            [mapY release];
            
            for (int y = 0; y < height; y++)
            {
                NSDictionary* element = [[mapJson objectAtIndex:x] objectAtIndex:y];
                NSNumber* territoryId = [element objectForKey:@"territory_id"];

                if (territoryId == nil)
                {
                    //Just a map element i.e. water
                    MapElement* mapElement = [[MapElement alloc] initWithJsonData:element];
                    [mapY addObject:mapElement];
                    [mapElement release];
                }
                else
                {
                    TerritoryElement* territoryElement = [territoryLookup objectForKey:[territoryId stringValue]];
                    [mapY addObject:territoryElement];
                }
            }
        }
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self){
        map = [[aDecoder decodeObjectForKey:@"map"]retain];
        tiles = [[aDecoder decodeObjectForKey:@"tiles"]retain];
        territories = [[aDecoder decodeObjectForKey:@"territories"]retain];
        
        width = [aDecoder decodeIntForKey:@"width"];
        height = [aDecoder decodeIntForKey:@"height"];
        numberOfTerritories = [aDecoder decodeIntForKey:@"numberOfTerritories"];
    }
    return self;
}

//Checks to see if there is water at the index
-(BOOL) isWaterAtXLoc:(int)x andYLoc:(int)y
{
    MapElement* possibleElement = [[map objectAtIndex:x] objectAtIndex:y];
    if (possibleElement->kind == WATER)
    {
        return YES;
    }
    return NO;
}

-(MapElement*) getElementAtXLoc:(int)x andYLoc:(int)y
{
    return [[map objectAtIndex: x] objectAtIndex: y];
}

- (NSString *)description{
    NSMutableString* description = [[[NSMutableString alloc] initWithString:@""] autorelease];
    [description appendString:@"\n---------------------------------------\n"];
    for(int x = 0; x < width; x++){
        for(int y = 0; y < height; y++){
            MapElement* element = (MapElement*)[self getElementAtXLoc:x andYLoc:y];
            if([element kind] == TERRITORY){
                TerritoryElement* territory = (TerritoryElement*)element;
                [description appendString: [NSString stringWithFormat:@"%d", [territory tId]]];
            }else{
                [description appendString: @" "];
            }
            [description appendString:@" "];
        }
        [description appendString:@"|\n"];
    }
    [description appendString:@"---------------------------------------\n"];
    [description appendString:@"\nTiles:"];
    
    
    [description appendString:@"\n---------------------------------------\n"];
    for(int x = 0; x < width; x++){
        for(int y = 0; y < height; y++){
            NSNumber* tile = (NSNumber*)[[tiles objectAtIndex:x] objectAtIndex:y];
            [description appendString: @" "];
            [description appendString:[NSString stringWithFormat:@"%d", [tile intValue]]];
            
        }
        [description appendString:@"|\n"];
    }
    [description appendString:@"\n---------------------------------------\n"];
    
    [description appendString:@"\nTerritory Locations:\n"];
    for (TerritoryElement* tElement in territories){
        [description appendString: [NSString stringWithFormat:@"Territory: %d\n", tElement->tId]];
        [description appendString: @"Border:\n"];
        int x, y;
        for (NSMutableArray* coordinates in tElement->borderCoordinates){
            x = [[coordinates objectAtIndex: 0] intValue];
            y = [[coordinates objectAtIndex: 1] intValue];
            [description appendString: [NSString  stringWithFormat:@"%d, %d\n", x, y]];
        }
        [description appendString: @"Controlled:\n"];
        for (NSMutableArray* coordinates in tElement->controlledCoordinates){
            x = [[coordinates objectAtIndex: 0] intValue];
            y = [[coordinates objectAtIndex: 1] intValue];
            [description appendString: [NSString  stringWithFormat:@"%d, %d\n", x, y]];
        }
        [description appendString:@"\n---------------------------------------\n"];
    }
    
    return description;
}

#pragma mark -
#pragma mark Access Map Given TMX Point

-(TerritoryElement*) getTerritoryAt:(CGPoint)xylocation{
    MapElement* possibleTerritory = [self getElementAtXLoc:xylocation.x andYLoc:xylocation.y];
    if([possibleTerritory kind] == TERRITORY){
        return (TerritoryElement*)possibleTerritory;
    }
    return nil;
}

#pragma mark -
#pragma mark Map Generator Delegate

/** Returns the map's filePath to be saved to. */
- (NSString*) mapFilePath{
    // put this in the document directory, then you can grab the TMX file from iTunes sharing if you'd like.
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString *fullPath				= [path stringByAppendingPathComponent:mapFile];
	return fullPath;
}

/** Returns map setup parameters and properties. Keys listed in the "Map Setup Info Keys" section above.  
 * Number values can be strings or NSNumbers. */
- (NSDictionary*) mapAttributeSetup{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:5];
	[dict setObject:[NSString stringWithFormat:@"%i", width] forKey:kTMXGeneratorHeaderInfoMapWidth];
	[dict setObject:[NSString stringWithFormat:@"%i", height] forKey:kTMXGeneratorHeaderInfoMapHeight];
	[dict setObject:[NSString stringWithFormat:@"%i", kNumPixelsPerTileSquare] forKey:kTMXGeneratorHeaderInfoMapTileWidth];
	[dict setObject:[NSString stringWithFormat:@"%i", kNumPixelsPerTileSquare] forKey:kTMXGeneratorHeaderInfoMapTileHeight];
	[dict setObject:[self mapFilePath] forKey:kTMXGeneratorHeaderInfoMapPath];
	
	return dict;
}

/** Returns tileset setup information based on the name. **/
- (NSDictionary*) tileSetInfoForName:(NSString*)name{
    NSDictionary* dict = nil;
	
	if ([name isEqualToString:kTerritoryTileSetName])
	{
		// Filename for the tileset
		NSString* fileName = kTerritoryTileSetFile;
		dict = [TMXGenerator tileSetWithImage:fileName
										named:name 
										width:kNumPixelsPerTileSquare
									   height:kNumPixelsPerTileSquare
								  tileSpacing:kNumPixelsBetweenTiles
                ];
	}
	else // Add more tilesets here!
	{
		NSLog(@"tileSetInfoForName: called with name %@, name was not handled!", name);
	}
	
	return dict;

    
}

/** Returns layer setup information based on the name passed.  Keys listed in 
 * "Layer Setup Info Keys" section above. */
- (NSDictionary*) layerInfoForName:(NSString*)name{
    NSDictionary* dict = nil;
	
	// All tmxMap layers are visible by default.
	BOOL isVisible = YES;
    
	// Data will be filled in by tilePropertyForLayer:tileSetName:X:Y:.	
	dict = [TMXGenerator layerNamed:name width:width height:height data:nil visible:isVisible];
	return dict;

}

/** Empous has no object layers **/

/** Returns the names of all the object groups as NSStrings. 
 * It's ok to return nil if don't need objects. */
- (NSArray*) objectGroupNames{
    return nil;
}

/** Returns object group information based on the name passed.  Keys listed in 
 * "Objects Group Setup Info Keys" section above.
 */
- (NSArray*) objectsGroupInfoForName:(NSString*)name{
    return nil;
}

/** Returns all layer names as an array of NSStrings.
 * Order of array items returned here determine the heirarchy.
 */
- (NSArray*) layerNames{
    // Warning!  The order these are in determines the layer heirarchy, leftmost is lowest, rightmost is highest!
	return [NSArray arrayWithObjects:kTerritoryLayerName, nil];
}

/** Returns the names of all tilesets as NSStrings. */
- (NSArray*) tileSetNames{
    return [NSArray arrayWithObjects:kTerritoryTileSetName, nil];
}

/** Returns the name of the tileset (only one right now) for the layer. */
- (NSString*) tileSetNameForLayer:(NSString*)layerName{
    // if you were using multiple tilesets then you'd want to determine which tileset you needed based on the layer name here.
	if ([layerName isEqualToString:kTerritoryLayerName])
	{
		return kTerritoryTileSetName;
	}
	return nil;
}

/** Returns a uniquely identifying value for the key returned in the method 
 * keyForTileIdentificationForLayer: 
 * If the value is not found, the tile gets set to the minimum GID. */
- (NSString*) tilePropertyForLayer:(NSString*)layerName	tileSetName:(NSString*)tileSetName X:(int)x Y:(int)y{
    //Territories & TerritoryTileSet
    
    /*For Reference*/
    /*#define NO_BORDER 0x00
     #define NORTH 0x01
     #define EAST 0x02
     #define SOUTH 0x04
     #define WEST 0x08*/
    
     NSMutableDictionary *dict = [NSMutableDictionary dictionary];
     [dict setValue:[NSString stringWithFormat:@"0"] forKey:[NSString stringWithFormat:@"0"]];
     [dict setValue:[NSString stringWithFormat:@"1"] forKey:[NSString stringWithFormat:@"2"]];
     [dict setValue:[NSString stringWithFormat:@"2"] forKey:[NSString stringWithFormat:@"1"]];
     [dict setValue:[NSString stringWithFormat:@"3"] forKey:[NSString stringWithFormat:@"8"]];
     [dict setValue:[NSString stringWithFormat:@"4"] forKey:[NSString stringWithFormat:@"4"]];
     [dict setValue:[NSString stringWithFormat:@"5"] forKey:[NSString stringWithFormat:@"6"]];
     [dict setValue:[NSString stringWithFormat:@"6"] forKey:[NSString stringWithFormat:@"12"]];
     [dict setValue:[NSString stringWithFormat:@"7"] forKey:[NSString stringWithFormat:@"9"]];
     [dict setValue:[NSString stringWithFormat:@"8"] forKey:[NSString stringWithFormat:@"3"]];
     [dict setValue:[NSString stringWithFormat:@"9"] forKey:[NSString stringWithFormat:@"10"]];
     [dict setValue:[NSString stringWithFormat:@"10"] forKey:[NSString stringWithFormat:@"5"]];
     [dict setValue:[NSString stringWithFormat:@"11"] forKey:[NSString stringWithFormat:@"14"]];
     [dict setValue:[NSString stringWithFormat:@"12"] forKey:[NSString stringWithFormat:@"13"]];
     [dict setValue:[NSString stringWithFormat:@"13"] forKey:[NSString stringWithFormat:@"7"]];
     [dict setValue:[NSString stringWithFormat:@"14"] forKey:[NSString stringWithFormat:@"11"]];
     [dict setValue:[NSString stringWithFormat:@"15"] forKey:[NSString stringWithFormat:@"15"]];
    
    //We only have one layer for now, which is the Territory layer - Use the tiles double array
    if ([layerName isEqualToString:kTerritoryLayerName]){
        //Get the Territory 
        if([self isWaterAtXLoc:x andYLoc:height-1-y]){
            return [NSString stringWithFormat:@"%d", kTerritoryBlank];
        }
        
        //Get the tile value from the tile array and translate it into the appropriate territoryBorder guid.
        NSNumber* tile = [[tiles objectAtIndex:x] objectAtIndex:(height-1)-y];
        NSString* tileLookup = [dict objectForKey:[NSString stringWithFormat:@"%d", [tile intValue]]];
        return tileLookup;
    }
    return nil;
}

/* Returns the key to look for in the tile properties (like SQL primary key) 
 * when assigning tiles during map creation.
 */
- (NSString*) tileIdentificationKeyForLayer:(NSString*)layerName{
    //If we add more layers then we need to actually check for the name.  
    return kTerritoryAtlasKey;
    
}

/** Returns the properties for a given tileset. */
- (NSDictionary*) propertiesForTileSetNamed:(NSString*)name{
    NSMutableDictionary* retVal = [NSMutableDictionary dictionaryWithCapacity:numOfBorderTiles];
	NSMutableDictionary* dict;
	
	// These properties map to the given atlas tile.
	if ([name isEqualToString:kTerritoryTileSetName])
	{
		// Territory Atlas
        
        // tile 0 - No Borders
		dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryNone] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryNone]];
        
        //tile 1 - West Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryWest] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryWest]];
        
        //tile 2 - South Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritorySouth] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritorySouth]];
        
        //tile 3 - East Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryEast] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryEast]];
        
        //tile 4 - North Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryNorth] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryNorth]];
        
        //tile 5 - NorthWest Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryNorthWest] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryNorthWest]];
        
        //tile 6 - NorthEast Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryNorthEast] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryNorthEast]];
        
        //tile 7 - SouthEast Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritorySouthEast] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritorySouthEast]];
        
        //tile 8 - SouthWest Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritorySouthWest] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritorySouthWest]];
        
        //tile 9 - EastWest Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryEastWest] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryEastWest]];
        
        //tile 10 - NorthSouth Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryNorthSouth] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryNorthSouth]];
        
        //tile 11 - WestNorthEast Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryWestNorthEast] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryWestNorthEast]];
        
        //tile 12 - NorthEastSouth Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryNorthEastSouth] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryNorthEastSouth]];
        
        //tile 13 - NorthWestSouth Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryNorthWestSouth] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryNorthWestSouth]];
        
        //tile 14 - EastSouthWest Border
        dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryEastSouthWest] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryEastSouthWest]];
        
        // tile 15 - All Borders
		dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryAll] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryAll]];
        
        // tile 16 - All Borders
		dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setObject:[NSString stringWithFormat:@"%i", kTerritoryBlank] forKey:kTerritoryAtlasKey];
		[retVal setObject:dict forKey:[NSString stringWithFormat:@"%i", kTerritoryBlank]];
		
	}
    
    return retVal;
}

@end





