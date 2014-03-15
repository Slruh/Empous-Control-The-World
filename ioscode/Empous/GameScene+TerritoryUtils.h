//
//  GameSceneTerritory.h
//  Empous
//
//  Created by Ryan Hurley on 4/9/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "GameScene.h"

/**
 A category which adds some helpful methods for territory management
 */
@interface GameScene (TerritoryUtils)

-(void)pulseOnPlayerTerritories;

/**
 Lightens the color of the given territory
 */
-(void)highlightTerritory:(TerritoryElement*)territory;

/**
 Highlights all the connected friendly territories to the given one.
 It also adds the white lines between the territories
 */
-(void)highlightConnectedFriendlyTerritories:(TerritoryElement*)territory;

/**
 Checks to see if territoryStart is connected to territoryEnd by friendly territories.
 */
-(BOOL)isFirstTerritoryConnected:(TerritoryElement*)territoryStart toSecondTerritory:(TerritoryElement*)territoryEnd;

-(void)pulseOnSprite:(CCNode*)node;

-(void)pulseOffSprite:(CCNode*)node;

-(void)stopPulsePlayerTerritories;

@end
