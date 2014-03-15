//
//  GameMode.h
//  Empous
//
//  Created by Ryan Hurley on 3/5/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Map.h"
#import "Player.h"
#import "Enums.h"
#import "EmpousJsonSerializable.h"

@interface GameMode : NSObject <NSCoding>{
    Map* map; //The game map
    int numberOfPlayers; //Number of players for the game
    NSDictionary* players; //Array of Player objects
    NSMutableDictionary* territoryCapturedThisTurn; //Array of NSNumbers which represent BOOLs
    NSMutableDictionary* chanceRefinforcements; //Array of Chances
    NSMutableDictionary* hasButPassedUpReinforcements; //Array of Chances
}

@property (retain) NSDictionary* players;

#pragma mark - 
#pragma mark Pregame Setup
//Contructor takes in a map and the number of players
-(id)initWithMap:(Map*)gameMap andPlayers:(NSDictionary*) gamePlayers;

//Distributes the territories to all the players.
-(void)distributeTerritories;

//Distributes the initial values of units on the map
-(void)generateInitialUnits;

#pragma mark -
#pragma mark Reinforcement Methods

//Calculate the reinforcements based on the map
-(int)calculateReinforcementsForPlayer:(int)pId;

#pragma mark -
#pragma mark Attack Methods

//Returns the number of units that can attack
-(int)unitsAllowedInAttack:(TerritoryElement*)territory;

//Calculate who wins after an attack
-(AttackResult)attackFromTerritory:(TerritoryElement*)attacker toTerritory:(TerritoryElement*)defender withUnits:(int)units;

//Player has captured a territory
-(void)capturedTerritory:(TerritoryElement*)territory withEmpousId:(int)empousId;




@end
