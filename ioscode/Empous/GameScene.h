//
//  GameScene.h
//  Empous
//
//  Created by Ryan Hurley on 2/20/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "cocos2d.h"
#import "Map.h"
#import "GameMode.h"
#import "Player.h"
#import "ControlLayer.h"
#import "NumberPicker.h"
#import "Enums.h"
#import "ReinforcementLabelsLayer.h"
#import "AttackLines.h"
#import "ConfirmLayer.h"
#import "CCLoadingOverlay.h"
#import "GameMenu.h"
#import "EmpousJsonSerializable.h"
#import "CCLayerPanZoom.h"
#import "BorderLines.h"

#pragma mark Layer Levels
#define BACKGROUND_LEVEL -6
#define BORDER_LEVEL -5
#define MAP_LEVEL -4
#define ATTACK_LINE_LEVEL -2
#define TERRITORY_LABEL_BACKGROUND_LEVEL -1
#define TERRITORY_LABEL_LEVEL 0
#define STATS_LEVEL 2
#define ATTACK_BUTTON_LEVEL 1
#define REINFORCEMENT_LABEL_LEVEL 1
#define PICKER_LEVEL 3
#define CONFIRMBOX_LEVEL 4
#define LOADING_LEVEL 5

/**
 The main Empous class which represents a game. Controls all the UI and code for managing a session.
 */
@interface GameScene : CCLayer <ControlLayerDelegate, NSCoding, MenuDelegate, EmpousSerializable, CCLayerPanZoomClickDelegate>{
    //Empous Logic Classes
    Map* gameMap;
    
    //Game Variables
    NSMutableDictionary* playerLookup;
    Player* thisPlayer; //The player this app is concerned with
    NSMutableArray* orderOfPlayersTurns;
    GameMode* mode; //The rules for the current game
    GamePhase currentPhase; //What phase the game is in
    
    TerritoryElement* highlightedTerritory; //The current highlighted territory
    TerritoryElement* targetedEnemy; //The secondary highlighted territory

    //Layers
    CCSprite* background; //Background stuff
    AttackLines* attackLines; //Attack lines
    BorderLines* borderLines; //Borders
    
    CCLayer* mapAndFriendsLayer; //Holds anything that relies on map positioning
    CCLayer* screenShotLayer;
    CCLayerPanZoom* zoomableLayer;
    CCTMXTiledMap* mapLayer; //Map layer itself
    CCTMXLayer* mapTiles; //Tiles of map
    CCLayer* territoryValues; //Labels for the units on each territory
    ControlLayer* controlLayer; //Control Layer...holds buttons etc
    NumberPicker* picker; //The picker layer
    ReinforcementLabelsLayer* reinforcementLayer; //Holds the numbers being added during the reinforcement phase
    ConfirmLayer* showReinforcements;
    CCLoadingOverlay* spinner;
    CCButton* victoryButton;
    
    //Game Variables
    BOOL fortifyPlaced;
    int currentPlayerId;
    int empousGameId; //The id assigned from the empous server
}

@property (retain) NSMutableArray* orderOfPlayersTurns;
@property (readonly) NSMutableDictionary* playerLookup;

#pragma mark -
#pragma mark Initializers
-(id)initWithPlayer:(Player*)creatingPlayer withEnemies:(NSMutableArray*)enemyPlayers andMode:(Class) gameModeClass withContinents:(BOOL)playingWithContinents;
-(void)setEmpousGameId:(int)empousId;

#pragma mark - 
#pragma mark Serialization Methods
-(NSDictionary*)toJSONDict;

#pragma mark -
#pragma mark Delegate Methods called from the control layer
-(void)attack;
-(void)cancelAttack;
-(void)moveUnits;
-(void)nextPhase;

#pragma mark -
#pragma mark Picker Methods
-(void)pickerValueChanged:(int)value;

#pragma mark -
#pragma mark Menu Methods
-(void)updateTileMap;
-(void)resetMap;


@end
