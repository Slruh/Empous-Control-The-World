//
//  Territory.m
//  Empous
//
//  Created by Ryan Hurley on 1/19/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "TerritoryElement.h"
#import "Tools.h"

@implementation TerritoryElement
@synthesize tId;
@synthesize empousId;
@synthesize units;
@synthesize additionalUnits;
@synthesize highlighted;
@synthesize controlledCoordinates;
@synthesize originalLocation;
@synthesize labelLocation;
@synthesize borders;
-(id) init
{
    self = [super init];
    if (self) {

        kind = TERRITORY;
        highlighted = FALSE;
    }
    
    return self;
}

-(id) initWithId:(int)_tId xLoc:(int)x yLoc:(int)y
{
    self = [super initWithXLoc:x andYLoc:y];
    if (self) {
        tId = _tId;
        kind = TERRITORY;
        originalLocation = CGPointMake(x,y);
        labelLocation = CGPointMake(0,0);
        
        borders = [[NSMutableSet alloc] init];
        borderCoordinates = [[NSMutableSet alloc] init];
        controlledCoordinates = [[NSMutableSet alloc] init];
        
        borderCoordinates = [[NSMutableSet alloc] init];
        NSMutableArray* firstCoordinates = [[NSMutableArray alloc] initWithCapacity: 2];
        [Tools insertIntIntoNSMutableArray:firstCoordinates index:0 value:x];
        [Tools insertIntIntoNSMutableArray:firstCoordinates index:1 value:y];

        [borderCoordinates addObject: firstCoordinates];
        [controlledCoordinates addObject: firstCoordinates];
        
        [firstCoordinates release];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    //Encode the map element
    [super encodeWithCoder:aCoder];
    
    //Encode all the ints
    [aCoder encodeInt:tId forKey:@"tId"];
    [aCoder encodeInt:empousId forKey:@"empousId"];
    [aCoder encodeInt:units forKey:@"units"];
    [aCoder encodeInt:additionalUnits forKey:@"additionalUnits"];
    
    //Encode the CGPoints
    [aCoder encodeCGPoint:originalLocation forKey:@"orginalLocation"];
    [aCoder encodeCGPoint:labelLocation forKey:@"labelLocation"];
    
    //Encode the border stuff
    [aCoder encodeObject:borders forKey:@"borders"];
    [aCoder encodeObject:controlledCoordinates forKey:@"controlledCoordinates"];
    [aCoder encodeObject:borderCoordinates forKey:@"borderCoordinates"];
}

-(NSDictionary*)toJSONDict
{
    NSMutableDictionary* territoryElementDict = [[[NSMutableDictionary alloc] init] autorelease];
    
    //Set parent map element properties
    [territoryElementDict setObject:[super toJSONDict] forKey:@"map_element"];
    
    //Set the ints
    [territoryElementDict setObject:[NSNumber numberWithInt:tId] forKey:@"territory_id"];
    [territoryElementDict setObject:[NSNumber numberWithInt:empousId] forKey:@"empous_id"];
    [territoryElementDict setObject:[NSNumber numberWithInt:units] forKey:@"units"];
    [territoryElementDict setObject:[NSNumber numberWithInt:additionalUnits] forKey:@"additional_units"];
    
    //Set the points for the label
    [territoryElementDict setObject:[EmpousJsonSerializable pointAsDict:labelLocation] forKey:@"label_location"];
    
    //Set the border stuff
    NSMutableArray* bordersDict = [[[NSMutableArray alloc] init] autorelease];
    for (TerritoryElement* territory in borders)
    {
        [bordersDict addObject:[NSNumber numberWithInt:[territory tId]]];
    }
    [territoryElementDict setObject:bordersDict forKey:@"borders"];
    
    //Other numbers
    [territoryElementDict setObject:[EmpousJsonSerializable setOfCoordinatesToArray:controlledCoordinates] forKey:@"controlled_coordinates"];
    if (borderCoordinates != nil)
    {
        [territoryElementDict setObject:[EmpousJsonSerializable setOfCoordinatesToArray:borderCoordinates] forKey:@"border_coordinates"];
    }
    
    return territoryElementDict;
}

-(id)initWithJsonData:(NSDictionary *)jsonData
{
    self = [super initWithJsonData:[jsonData objectForKey:@"map_element"]];
    if (self)
    {
        tId = [[jsonData objectForKey:@"territory_id"] intValue];
        empousId = [[jsonData objectForKey:@"empous_id"] intValue];
        units = [[jsonData objectForKey:@"units"] intValue];
        additionalUnits = [[jsonData objectForKey:@"additional_units"] intValue];
        
        //Set up the label location
        NSDictionary* label = [jsonData objectForKey:@"label_location"];
        labelLocation = ccp([[label objectForKey:@"xcoor"] floatValue],[[label objectForKey:@"ycoor"] floatValue]);
        
        //Use the numbers as borders for now - these will get fixed after to be actual objects
        borders = [[NSMutableSet alloc] init];
        for (id borderId in [jsonData objectForKey:@"borders"])
        {
            [borders addObject:borderId];
        }
        
        //Check for other coordinates
        controlledCoordinates = [[EmpousJsonSerializable arrayOfCoordinatesToSet:[jsonData objectForKey:@"controlled_coordinates"]] retain];
        NSArray* borderCoords = [jsonData objectForKey:@"border_coordinates"];
        if (borderCoords != nil)
        {
            borderCoordinates = [[EmpousJsonSerializable arrayOfCoordinatesToSet:borderCoords] retain];
        }
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        //Decode Integers
        tId = [aDecoder decodeIntForKey:@"tId"];
        empousId = [aDecoder decodeIntForKey:@"empousId"];
        units = [aDecoder decodeIntForKey:@"units"];
        additionalUnits = [aDecoder decodeIntForKey:@"additionalUnits"];
        
        //Decode CGPoints
        originalLocation = [aDecoder decodeCGPointForKey:@"originalLocation"];
        labelLocation = [aDecoder decodeCGPointForKey:@"labelLocation"];
        
        //Decode the border stuff
        borders = [[aDecoder decodeObjectForKey:@"borders"]retain];
        controlledCoordinates = [[aDecoder decodeObjectForKey:@"controlledCoordinates"] retain];
        borderCoordinates = [[aDecoder decodeObjectForKey:@"boderCoordinates"] retain];
        
        //Other variable values
        highlighted = NO;
    }
    return self;
}

- (NSMutableSet*)enemyTerritories
{
    NSMutableSet* enemies = [[[NSMutableSet alloc] init] autorelease];
    for(TerritoryElement* possibleEnemy in borders)
    {
        if([possibleEnemy empousId] != empousId){
            [enemies addObject:possibleEnemy];
        }
    }
    
    return enemies;
}

-(void)confirmAdditionalUnits
{
    units = units + additionalUnits;
    additionalUnits = 0;
}

- (NSMutableSet*) friendlyTerritories
{
    NSMutableSet* friendlies = [[[NSMutableSet alloc] init] autorelease];
    for(TerritoryElement* neighbor in borders)
    {
        if([neighbor empousId] == empousId && [neighbor tId] != tId){
            [friendlies addObject:neighbor];
        }
    }
    
    return friendlies;
}

- (NSMutableSet*) unhighlightedfriendlyTerritories
{
    NSMutableSet* friendlies = [[[NSMutableSet alloc] init] autorelease];
    for(TerritoryElement* neighbor in borders)
    {
        if([neighbor empousId] == empousId && [neighbor tId] != tId && [neighbor highlighted] == NO){
            [friendlies addObject:neighbor];
        }
    }
    
    return friendlies;
}


@end
