//
//  Player.m
//  Empous
//
//  Created by Ryan Hurley on 3/10/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "Player.h"
#import "Tools.h"

@implementation Player
@synthesize color;
@synthesize empousId;
@synthesize chanceBonusReinforcements;
@synthesize name;
@synthesize territories;

- (id)init
{
    self = [super init];
    if (self) {
        //4 is chosen as a default for now (Capacity is different then size)
        territories = [[NSMutableSet alloc]init];
    }
    
    return self;
}

-(id)initWithEmpousId:(int)theEmpousId playerName:(NSString*)playerName;
{
    self = [self init];
    if(self)
    {
        [self setEmpousId:theEmpousId];
        [self setName:playerName];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:territories forKey:@"territories"];
    [aCoder encodeInt:empousId forKey:@"empousId"];
    [aCoder encodeObject:name forKey:@"name"];
    [aCoder encodeInt:chanceBonusReinforcements forKey:@"chanceBonusReinforcements"];
    
    //Handle color
    NSData* colorData = [NSData dataWithBytes:&color length:sizeof(color)];
    [aCoder encodeObject:colorData forKey:@"color"];
}

-(NSDictionary*)toJSONDict
{
    NSMutableDictionary* player = [[[NSMutableDictionary alloc] init] autorelease];
    
    [player setObject:name forKey:@"name"];
    [player setObject:[NSNumber numberWithInt:empousId] forKey:@"empous_id"];
    [player setObject:[NSNumber numberWithInt:chanceBonusReinforcements] forKey:@"chance_bonus_reinforcements"];
    
    //Handle the territories - just record the tId
    NSMutableArray* playerTerritories = [[[NSMutableArray alloc] init] autorelease];
    for (TerritoryElement* territory in territories)
    {
        [playerTerritories addObject:[NSNumber numberWithInt:[territory tId]]];
    }
    [player setObject:playerTerritories forKey:@"territories"];
    
    //Handle color
    [player setObject:[EmpousJsonSerializable colorAsDict:color] forKey:@"color"];
    
    return player;
}

-(id)initWithJsonData:(NSDictionary *)jsonData
{
    self = [super init];
    if(self){
        name = [[jsonData objectForKey:@"name"] retain];
        empousId = [[jsonData objectForKey:@"empous_id"] intValue];
        chanceBonusReinforcements = [[jsonData objectForKey:@"chance_bonus_reinforcements"] intValue];
        
        NSDictionary* territoryLookup = [jsonData objectForKey:@"territoryLookup"];
        territories = [[NSMutableSet alloc] init];
        for (NSNumber* territoryId in [jsonData objectForKey:@"territories"])
        {
            TerritoryElement* territory = [territoryLookup objectForKey:[territoryId stringValue]];
            [territories addObject:territory];
        }
        
        color = [EmpousJsonSerializable colorFromDict:[jsonData objectForKey:@"color"]];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        territories = [[aDecoder decodeObjectForKey:@"territories"] retain];
        empousId = [aDecoder decodeIntForKey:@"empousId"];
        name = [[aDecoder decodeObjectForKey:@"name"]retain];
        chanceBonusReinforcements = [aDecoder decodeIntForKey:@"chanceBonusReinforcements"];
        
        //Decode color
        NSData* colorData = [[aDecoder decodeObjectForKey:@"color"]retain];
        [colorData getBytes:&color length:sizeof(color)];
        [colorData release];
    }
    return self;
}

-(void)dealloc{
    for(TerritoryElement* territory in territories){
        [territory release];
    }
    [territories release];
    [name release];
    [super dealloc];
}

-(void)addTerritory:(TerritoryElement*) territory{
    //Retaining may be a bad idea here!
    [territory retain];
    [territories addObject:territory];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"%@",name];
}

@end
