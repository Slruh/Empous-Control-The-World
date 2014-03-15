//
//  GameMode.m
//  Empous
//
//  Created by Ryan Hurley on 3/5/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "GameMode.h"
#import "Player.h"

@implementation GameMode
@synthesize players;

NSMutableDictionary* playerCards;

//Init is not supported
- (id)init
{
    [NSException raise:@"MBMethodNotSupportedException" format:@"\"- (id)init\" is not supported. Please use the designated initializer \"- (id)initWithMapAndPlayers:gameMap:numPlayers:\""];
    return nil;
}

//Initialize the mode with a map and some players
-(id)initWithMap:(Map*)gameMap andPlayers:(NSDictionary*) gamePlayers
{
    self = [super init];
    if (self) {
        // Initialization code here.
        [gameMap retain];
        map = gameMap;
        numberOfPlayers = [gamePlayers count];
        [self setPlayers:gamePlayers];
        [self initStructures];
    }
    return self;
}

//Release any Obj-C Objects
-(void)dealloc{
    [map release];
    [players release];
    [territoryCapturedThisTurn release];
    [super dealloc];
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:map forKey:@"map"];
    [aCoder encodeInt:numberOfPlayers forKey:@"numOfPlayers"];
    [aCoder encodeObject:players forKey:@"players"];
}

-(void)initStructures
{
    //Set all the players captured territories to NO
    territoryCapturedThisTurn = [[NSMutableDictionary alloc]initWithCapacity:numberOfPlayers]; //Array of NSNumbers which represent BOOLs
    chanceRefinforcements = [[NSMutableDictionary alloc]initWithCapacity:numberOfPlayers]; //Array of Chances
    hasButPassedUpReinforcements = [[NSMutableDictionary alloc]initWithCapacity:numberOfPlayers]; //Array of Chances
    
    
    for(id key in [self players])
    {
        Player* player = [players objectForKey:key];
        NSString* playerId = [NSString stringWithFormat:@"%d",[player empousId]];
        [territoryCapturedThisTurn setValue:NO forKey:playerId];
        [chanceRefinforcements setValue:0 forKey:playerId];
        [hasButPassedUpReinforcements setValue:NO forKey:playerId];
    }
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        map = [[aDecoder decodeObjectForKey:@"map"]retain];
        numberOfPlayers = [aDecoder decodeIntForKey:@"numOfPlayers"];
        players = [[aDecoder decodeObjectForKey:@"players"]retain];
        
        [self initStructures];
    }
    return self;
}

#pragma mark -
#pragma mark Initial GameMode Methods

//Distributes the territories to all the players
-(void)distributeTerritories{
    
    //How many territories each player gets - Assume #Territories % #players = 0
    int territoriesForEach = [map numberOfTerritories]/numberOfPlayers;
    
    //May be to naive...assuming the set will be different enough each time 
    //3/18/12 Seems to work pretty well since the map generation is randomly done
    NSMutableSet* localTerritories = [NSMutableSet setWithSet:[map territories]];
    
    //Go through each player and assign them territories
    for(id key in [self players])
    {
        Player* player = [players objectForKey:key];
        int empousId = [player empousId];
        
        for(int j = 0; j < territoriesForEach; j++){
            TerritoryElement* territory = [localTerritories anyObject];
            [territory setEmpousId:empousId]; //Tell the territory that it is owned by the player
            [localTerritories removeObject:territory]; 
            [player addTerritory:territory]; //Assign the territory to the player
        }
    }
}

//Generate initial units (Each territory always gets one, then the remaining are randomly distributed
-(void)generateInitialUnits{
    for(id key in [self players])
    {
        Player* player = [players objectForKey:key];
        NSMutableArray *territoriesArray = [NSMutableArray arrayWithArray:[[player territories] allObjects]];
        
        //First make sure every territory has one unit
        for(TerritoryElement* territory in territoriesArray){
            [territory setUnits:[territory units] + 1];
        }
        
        //For the remaining units, we randomly select a territory and increment its unit count
        for(int remaining = 3; remaining > 0; remaining--){
            int index = arc4random() % [territoriesArray count];
            TerritoryElement* territoryToIncrement = [territoriesArray objectAtIndex:index];
            [territoryToIncrement setUnits:[territoryToIncrement units] + 1];
        }
    }
}

#pragma mark -
#pragma mark Reinforcement Methods

//Given the available variables (Map, Players, etc) calculate the number of reinforcements a player gets
-(int)calculateReinforcementsForPlayer:(int)empousId
{
    Player* player = [[self players ]objectForKey:[NSString stringWithFormat:@"%d",empousId]];
    int territoryBonus = [[player territories] count] / 3;
    
    //Select the max of the two values
    int reinforcements = MAX(3, territoryBonus);
    NSLog(@"Reinforcements: %d", reinforcements);
    return reinforcements;
}

#pragma mark -
#pragma mark Attack Methods

-(int)unitsAllowedInAttack:(TerritoryElement*)territory
{
    return [territory units] - 1;
}

-(AttackResult)attackFromTerritory:(TerritoryElement *)attacker toTerritory:(TerritoryElement *)defender withUnits:(int)units
{
    //While there are units to attack with
    while(units > 0){
        NSMutableArray* attackerDice = [[[NSMutableArray alloc]initWithObjects:[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0], nil] autorelease];
        NSMutableArray* defenceDice = [[[NSMutableArray alloc]initWithObjects:[NSNumber numberWithInt:0],[NSNumber numberWithInt:0], nil] autorelease];
        
        NSLog(@"Defense Units: %d", [defender units]);
        NSLog(@"Attack Units: %d",units);
        
        //Default attack dice to 3, but lower if units is less than 3
        int attackDice = 3;
        if(units < 3){
            attackDice = units;
        }
        
        //Generate a random number for each of the dice rolls
        for (int index = 0; index < attackDice; index++) {
            [attackerDice insertObject:[NSNumber numberWithInt:((arc4random() % 6) + 1)] atIndex:index];
        }
        
        //If the defense reaches 0 return WIN
        if([defender units] < 1){
            return WIN;
        }
        
        //Get the amount of dice the defense should roll
        int defenseDice = 2;
        if([defender units] < 2){
            defenseDice = [defender units];
        }
            
        //Generate the defense dice rolls
        for(int index = 0; index < defenseDice; index++){
            [defenceDice insertObject:[NSNumber numberWithInt:((arc4random() % 6) + 1)] atIndex:index];
        }
        
        //Both the attack and defense arrays should have dice values so sort highest to lowest
        NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        [attackerDice sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
        [defenceDice sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
        
        //Get the dice to compare
        NSNumber* attack1 = [attackerDice objectAtIndex:0];
        NSNumber* attack2 = [attackerDice objectAtIndex:1];
        NSNumber* defense1 = [defenceDice objectAtIndex:0];
        NSNumber* defense2 = [defenceDice objectAtIndex:1];
        
        if([attack1 intValue] != 0 && [defense1 intValue] != 0){
            if([attack1 intValue] > [defense1 intValue]){
                NSLog(@"Attack Win");
                //Attack win
                [defender setUnits:MAX(0,[defender units] -1)];
            }else{
                NSLog(@"Defense Win");
                //Defense win
                units --;
                [attacker setUnits:MAX(1,[attacker units] -1)];
                
            }
        }
        
        if(units < 1){
            return LOSE;
        }
        if([defender units] < 1){
            return WIN;
        }
        
        if([attack2 intValue] != 0 && [defense2 intValue] != 0){
            if([attack2 intValue] > [defense2 intValue]){
                //Attack win
                NSLog(@"Attack Win");
                [defender setUnits:MAX(0,[defender units] -1)];
                
            }else{
                NSLog(@"Defense Win");
                //Defense win
                units --;
                [attacker setUnits:MAX(1,[attacker units] -1)];
            }
        }
        
        if(units < 1){
            return LOSE;
        }
        if([defender units] < 1){
            return WIN;
        }
    }
    return LOSE;
}

//Increment the bonus by 20% once per player turn.  
-(void)capturedTerritory:(TerritoryElement *)territory withEmpousId:(int)empousId
{
    NSString* empousIdString = [NSString stringWithFormat:@"%d",empousId];
    BOOL capturedAlready = [[territoryCapturedThisTurn objectForKey:empousIdString] boolValue];
    if(!capturedAlready){
        Player* capturer = [[self players ]objectForKey:[NSString stringWithFormat:@"%d",empousId]];
        [capturer setChanceBonusReinforcements:[capturer chanceBonusReinforcements] + 20]; 
        [territoryCapturedThisTurn setObject:[NSNumber numberWithBool:YES] forKey:empousIdString];
    }
}


@end
