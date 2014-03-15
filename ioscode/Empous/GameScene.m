//
//  GameScene.m
//  Empous
//
//  Created by Ryan Hurley on 2/20/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "GameScene.h"
#import "OriginalMapGenerator.h"
#import "TMXGenerator.h"
#import "Colors.h"
#import "Tools.h"
#import "Player.h"
#import <Foundation/Foundation.h>
#import "MainMenuScene.h"
#import "CurrentGamesScene.h"
#import "EmpousAPIWrapper.h"
#import "ConfirmLayer.h"
#import "SimpleAudioEngine.h"
#import "GameScene+TerritoryUtils.h"
#import "GameScene+ArchiveHttpUtils.h"
#import "TutorialScene.h"
#import "ContinentMapGenerator.h"

@implementation GameScene
{
    GameMenu* menu;
    BOOL attackedATerritory;
}

@synthesize orderOfPlayersTurns;
@synthesize playerLookup;

static int inited = 0;

Player* passedInPlayer;
NSMutableArray* passedInEnemyPlayers;

#pragma mark -
#pragma mark Initializers

- (id)init
{
    self = [super init];
    if (self) {
        //Get screensize
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp(winSize.width/2,winSize.height/2);
        
        //Add the Sprite for the background
        background = [CCSprite spriteWithFile: @"Empous-Background.png"];
        background.position = ccp(center.x, 160);
        [self addChild:background z:BACKGROUND_LEVEL];
        
    }
    return self;
}

-(void)onExitTransitionDidStart
{
    if([[self children] containsObject:spinner])
    {
        [self removeChild:spinner cleanup:YES];
    }
    [super onExitTransitionDidStart];
}

/*
 * Creates a new game, the players must be an instance of Player and include their empous ids.
 */
-(id)initWithPlayer:(Player*)creatingPlayer withEnemies:(NSMutableArray*)enemyPlayers andMode:(Class) gameModeClass withContinents:(BOOL)playingWithContinents;
{
    self = [self init];
    if(self){
        //Hold the passed in players for the onEnterTransition method
        passedInEnemyPlayers = [enemyPlayers retain];
        passedInPlayer = [creatingPlayer retain];
        
        //Get the total number of players
        int numPlayers = [enemyPlayers count] + 1;  //Plus one for the current player!
        
        //Default for Empous classic
        int numTerritoriesPerGame[5];
        numTerritoriesPerGame[2] = 10;
        numTerritoriesPerGame[3] = 12;
        numTerritoriesPerGame[4] = 16;
        
        if (playingWithContinents)
        {
            numTerritoriesPerGame[2] = 16;
            numTerritoriesPerGame[3] = 21;
            numTerritoriesPerGame[4] = 24;
        }
        
        //Generate the game map (the matrix version) 
        gameMap = Nil;
        int tries = 0, maxTries = 200;
        while (gameMap == Nil && tries < maxTries){
            if (playingWithContinents)
            {
                gameMap = [ContinentMapGenerator createMapWithWidth:45 andHeight:30 withNumberOfTerritories:numTerritoriesPerGame[numPlayers]];
            }
            else
            {
                gameMap = [OriginalMapGenerator createMapWithWidth:30 andHeight:20 withNumberOfTerritories:numTerritoriesPerGame[numPlayers]];
            }
            [gameMap retain];
            tries++;
        }
        if (tries == maxTries){
            NSLog(@"Failed to create map after %d tries", maxTries);
            exit(-1);
        }
        [gameMap retain];
        
        //Remove the first player and assign it to the player of this game.
        thisPlayer = creatingPlayer;
        currentPlayerId = [thisPlayer empousId];
        
        //TODO: Randomize order of players
        orderOfPlayersTurns = [[NSMutableArray alloc] initWithCapacity:numPlayers];
        playerLookup = [[NSMutableDictionary alloc] initWithCapacity:numPlayers];

        for(int i = 0; i < [enemyPlayers count]; i++)
        {
            Player* enemyPlayer = (Player*)[enemyPlayers objectAtIndex:i];
            [orderOfPlayersTurns addObject:[NSNumber numberWithInt:[enemyPlayer empousId]]];
            [playerLookup setValue:enemyPlayer forKey:[NSString stringWithFormat:@"%d",[enemyPlayer empousId]]];
        }
        //We add the current player onto the end and add to lookup
        [orderOfPlayersTurns addObject:[NSNumber numberWithInt:[thisPlayer empousId]]];
        [playerLookup setValue:thisPlayer forKey:[NSString stringWithFormat:@"%d",[thisPlayer empousId]]];

        NSMutableArray* gameColors = [[NSMutableArray alloc] initWithObjects:
                                      [NSValue valueWithBytes:&ccBROWN objCType:@encode(ccColor4B)],
                                      [NSValue valueWithBytes:&ccDARKGREEN objCType:@encode(ccColor4B)],
                                      [NSValue valueWithBytes:&ccDARKOLIVEGREEN objCType:@encode(ccColor4B)],
                                      [NSValue valueWithBytes:&ccFORESTGREEN objCType:@encode(ccColor4B)],
                                      [NSValue valueWithBytes:&ccOLIVE objCType:@encode(ccColor4B)],
                                      [NSValue valueWithBytes:&ccSADDLEBROWN objCType:@encode(ccColor4B)],
                                      nil];
        
        //Choose a random color for all the players
        for(id key in playerLookup)
        {
            Player* player = [playerLookup objectForKey:key];
            //Randomly choose a color from the list of colors
            int index = arc4random() % [gameColors count];
            ccColor4B color;
            [[gameColors objectAtIndex:index]getValue:&color];
            [gameColors removeObject:[gameColors objectAtIndex:index]];
            [player setColor:color];
        }
        [gameColors release];
        
        //CAREFUL: If you do not pass in a GameMode class this will crash the program!!!!
        mode = [[gameModeClass alloc] initWithMap:gameMap andPlayers:playerLookup];
        [mode distributeTerritories];
        [mode generateInitialUnits];
        [self setupMap];
        
        //Set the current mode.  This player which started the game starts first.
        currentPhase = REINFORCEMENTS;
            
        spinner = [CCLoadingOverlay nodeWithMessage:@"Loading Game" withFont:@"Armalite Rifle"];
        [self addChild:spinner z:LOADING_LEVEL];
        
        inited = 1;        
    }
    return self;
}

- (void)onEnterTransitionDidFinish
{
    //Only called after initted
	if (inited) {
		[super onEnterTransitionDidFinish];
        
        //Send the game to the server
        empousGameId = [[EmpousAPIWrapper sharedEmpousAPIWrapper] createEmpousGame:passedInPlayer withEnemies:passedInEnemyPlayers withGameState:[self archiveCurrentGame] withScreenShot:[self createScreenShot]];
                
        if(empousGameId < 1)
        {
            [self schedule:@selector(handleReturnToMain) interval:.5]; //Important otherwise main menu locks up
            return;
        }
        
        [self removeChild:spinner cleanup:YES];
        
        reinforcementLayer = [[ReinforcementLabelsLayer alloc] initWithPlayer:thisPlayer];
        int reinforceValue = [mode calculateReinforcementsForPlayer:[thisPlayer empousId]];
        [mapAndFriendsLayer addChild:reinforcementLayer z:REINFORCEMENT_LABEL_LEVEL];
        

        [reinforcementLayer setReinforcementsLeft:reinforceValue];
        [controlLayer setMessage:[NSString stringWithFormat:@"%d Reinforcements Left" , [reinforcementLayer reinforcementsLeft]]];
        [picker updatePickerValues:NSMakeRange(0, reinforceValue + 1) startValue:0];
        
        [self pulseOnPlayerTerritories];
        
		inited = 0;
        
        //Check to see if this is the first game ever!
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL shownHowTo = [defaults boolForKey:@"shownHowTo"];
        if (!shownHowTo)
        {
            currentPhase = FIRST_TIME;
            UIAlertView* dialog = [[UIAlertView alloc] init];
            [dialog setDelegate:self];
            [dialog setTitle:@"First Time Playing?"];
            [dialog setMessage:@"Would you like to see the \"How To\"?"];
            [dialog addButtonWithTitle:@"No"];
            [dialog addButtonWithTitle:@"Yes"];
            [dialog show];
            [dialog release];
        }
	}
    
    [self resetMap];
}

-(void)handleReturnToMain
{
    [self removeChild:spinner cleanup:YES];
    [self unschedule:@selector(handleReturnToMain)];
    [[CCDirector sharedDirector] pushScene: [CCTransitionFade transitionWithDuration:0.5f scene:[MainMenuScene node]]];
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:gameMap forKey:@"game_map"];
    [aCoder encodeObject:[NSNumber numberWithInt:empousGameId] forKey:@"game_id"];
    [aCoder encodeObject:mode forKey:@"mode"];
    [aCoder encodeObject:orderOfPlayersTurns forKey:@"order_of_players"];
    [aCoder encodeObject:[NSNumber numberWithInt:currentPlayerId] forKey:@"current_player_turn"];
    [aCoder encodeInt:currentPhase  forKey:@"current_phase"];
    [aCoder encodeObject:playerLookup forKey:@"player_lookup"];
}

-(NSDictionary*)toJSONDict;
{
    NSDictionary* gameState = [[[NSMutableDictionary alloc] init] autorelease];
    
    //Get the game id
    [gameState setValue:[NSNumber numberWithInt:empousGameId] forKey:@"game_id"];
    
    //Get the current player
    [gameState setValue:[NSNumber numberWithInt:currentPlayerId] forKey:@"current_player_turn"];
    
    //Get the order of players turns
    [gameState setValue:orderOfPlayersTurns forKey:@"order_of_players"];
    
    //get the currentPhase (used in non-end of turn updates)
    [gameState setValue:[NSNumber numberWithInt:currentPhase] forKey:@"current_phase"];
    
    //Save the map
    [gameState setValue:[gameMap toJSONDict] forKey:@"game_map"];
    
    //Save the player lookup - Just write each player as a dictionary
    NSMutableDictionary* players = [[[NSMutableDictionary alloc] init] autorelease];
    for (id key in playerLookup)
    {
        Player* player = [playerLookup objectForKey:key];
        [players setValue:[player toJSONDict] forKey:key];
    }
    
    [gameState setValue:players forKey:@"players"];
    
    return gameState;
}

-(id)initWithJsonData:(NSDictionary*)jsonData
{
    self = [self init];
    if (self)
    {
        empousGameId = [[jsonData objectForKey:@"game_id"] intValue];
        currentPlayerId = [[jsonData objectForKey:@"current_player_turn"] intValue];
        orderOfPlayersTurns = [[NSMutableArray arrayWithArray:[jsonData objectForKey:@"order_of_players"]] retain];
        
        //Decode the map itself
        gameMap = [[Map alloc] initWithJsonData:[jsonData objectForKey:@"game_map"]];
        
        NSDictionary* territoryLookup = [gameMap territoryLookup];
        
        //Create the player lookup
        playerLookup = [[NSMutableDictionary alloc] init];
        NSDictionary* playersDict = [jsonData objectForKey:@"players"];
        for (id playerDictKey in playersDict)
        {
            //Add the territory lookup to the player dict
            NSDictionary* playerDict = [playersDict objectForKey:playerDictKey];
            NSMutableDictionary* playerDictWithTerritories = [NSMutableDictionary dictionaryWithDictionary:playerDict];
            [playerDictWithTerritories setObject:territoryLookup forKey:@"territoryLookup"];

            Player* player = [[Player alloc] initWithJsonData:playerDictWithTerritories];
            NSString* playerId  = [NSString stringWithFormat:@"%d",[[playerDict objectForKey:@"empous_id"] intValue]];
            [playerLookup setObject:player forKey:playerId];
            [player release];
        }
        
        //Initialize the mode again
        mode = [[GameMode alloc] initWithMap:gameMap andPlayers:playerLookup];
        
        //Set up the visual map. ASSUMPTION: gameMap has been decoded.
        [self setupMap];
        
        //Handle phase
        GamePhase tmpPhase = [[jsonData objectForKey:@"current_phase"] intValue];
        [self setupPlayerAndPhase:tmpPhase];
    }
    return self;
}

/*
 *  Initialized this object from a serialized file
 */
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if(self){
        gameMap = [[aDecoder decodeObjectForKey:@"game_map"]retain];
        empousGameId = [(NSNumber*)[aDecoder decodeObjectForKey:@"game_id"] intValue];
        mode = [[aDecoder decodeObjectForKey:@"mode"]retain];
        orderOfPlayersTurns = [[aDecoder decodeObjectForKey:@"order_of_players"]retain];
        currentPlayerId = [[aDecoder decodeObjectForKey:@"current_player_turn"]intValue];
        playerLookup = [[aDecoder decodeObjectForKey:@"player_lookup"]retain];
        
        //Set up the visual map. ASSUMPTION: gameMap has been decoded.
        [self setupMap];
        
        GamePhase tmpPhase = [aDecoder decodeIntForKey:@"current_phase"];
        [self setupPlayerAndPhase:tmpPhase];
    }
    return self;
}

-(void)setupPlayerAndPhase:(GamePhase)tmpPhase
{
    //Get the empous id from NSUserdefaults and find the player that is you
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int empousId = [[defaults objectForKey:@"empous_id"] intValue];
    thisPlayer = [playerLookup objectForKey:[NSString stringWithFormat:@"%d",empousId]];
    
    //Set the current mode.  This player which started the game starts first.
    if(currentPlayerId == [thisPlayer empousId])
    {
        if(tmpPhase == ATTACK)
        {
            currentPhase = ATTACK;
            [controlLayer setMessage:@"Attack"];
        }
        else if(tmpPhase == FORTIFY)
        {
            currentPhase = FORTIFY;
            [controlLayer setMessage:@"Fortify"];
        }
        else if(tmpPhase == TURN_OVER_FAILED_SEND)
        {
            currentPhase = TURN_OVER_FAILED_SEND;
            [controlLayer setMessage:@"Turn Over"];
        }
        else //This handles the case where the currentPhase wasn't encoded
        {
            //It's your turn again!
            currentPhase = REINFORCEMENTS;
            reinforcementLayer = [[ReinforcementLabelsLayer alloc] initWithPlayer:thisPlayer];
            int reinforceValue = [mode calculateReinforcementsForPlayer:[thisPlayer empousId]];
            [reinforcementLayer setReinforcementsLeft:reinforceValue];
            
            //Update the picker
            [picker updatePickerValues:NSMakeRange(0, reinforceValue+1) startValue:0];
            
            [controlLayer setMessage:[NSString stringWithFormat:@"%d Reinforcements Left" , [reinforcementLayer reinforcementsLeft]]];
            [mapAndFriendsLayer addChild:reinforcementLayer z:REINFORCEMENT_LABEL_LEVEL];
        }
    }
    else
    {
        //Your enemies turn, you can't do anything!
        currentPhase = TURN_OVER;
        
        Player* currentPlayer = [playerLookup objectForKey:[NSString stringWithFormat:@"%d",currentPlayerId]];
        [controlLayer setMessage:[NSString stringWithFormat:@"%@\'s Turn", [currentPlayer name]]];
    }
}


-(void)setEmpousGameId:(int)empousId
{
    empousGameId = empousId;
}

/*
 * Sets up the map specified by the object in the gameMap variable
 */
-(void)setupMap
{
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"empous-in-game.mp3"];
    [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:0.5f];

    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    //Generate the tile layer for the map and store it in the file system
    TMXGenerator* gen = [[TMXGenerator alloc] init];
    [gen setDelegate:gameMap];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL fileExists = [fileManager fileExistsAtPath:[gameMap mapFilePath]];
    if (fileExists)
    {
        BOOL success = [fileManager removeItemAtPath:[gameMap mapFilePath] error:&error];
        if (!success){
            NSLog(@"Error: %@", [error localizedDescription]);
        }
    }
    
    [gen generateAndSaveTMXMap:&error];
    [gen release], gen = nil;
    
    zoomableLayer = [CCLayerPanZoom node];
    [zoomableLayer setDelegate:self];
    [zoomableLayer setMode:kCCLayerPanZoomModeSheet];
    [self addChild:zoomableLayer z:MAP_LEVEL];
    
    mapAndFriendsLayer = [CCLayer node];
    [zoomableLayer addChild:mapAndFriendsLayer];
    
    //Screen shot layer used
    screenShotLayer = [CCLayer node];
    
    //Setup the Map by reading the saved file back into a tile layer
    mapLayer = [[[CCTMXTiledMap alloc] initWithTMXFile:[gameMap mapFilePath]] autorelease];
    
    //Scale for retina display if necessary
    if(CC_CONTENT_SCALE_FACTOR() == 2){
        mapLayer.scale = 2.0;
    }

    //Whole window is the frame
    [zoomableLayer setPanBoundsRect:CGRectMake(0, 0, winSize.width, winSize.height)];
    
    //Only do this for new maps
    CGSize mapSize = [mapLayer boundingBox].size;
    [zoomableLayer setContentSize:mapSize];

    if(winSize.width == 568)
    {
        [mapLayer setPosition:ccp([Tools getShiftAmount],0)];
    }
    
    mapTiles = [mapLayer layerNamed:kTerritoryLayerName];
    [screenShotLayer addChild:mapLayer z: MAP_LEVEL];
    
    //Set up the Layer which will hold the territory numbers
    territoryValues = [CCLayer node];
    [screenShotLayer addChild:territoryValues z:TERRITORY_LABEL_LEVEL];
    
    [mapAndFriendsLayer addChild:screenShotLayer];
    
    //For each territory add the number of people that are on the territory over the start point of the territory
    for(TerritoryElement* territory in [gameMap territories]){
        CCLabelTTF* label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",[territory units]] fontName:@"Verdana" fontSize:12];
        CGPoint location = [Tools mapToWorld:[territory labelLocation]];
        CGPoint correctedLocation = ccp(location.x + 8, location.y + 8);
        [label setPosition:correctedLocation];
        [territoryValues addChild:label z:TERRITORY_LABEL_LEVEL tag:[territory tId]];
        
        CCSprite* unitBackground = [CCSprite spriteWithFile:@"Unit-Background.png"];
        [unitBackground setPosition:correctedLocation];
        [territoryValues addChild:unitBackground z:TERRITORY_LABEL_BACKGROUND_LEVEL];
    }
    
    //Add the picker to the map
    picker = [[NumberPicker alloc] initWithNSRange:NSMakeRange(0, 0) startValue:0 position:ccp(85,15) scene:self];
    [self addChild:picker z:PICKER_LEVEL];
    
    controlLayer = [[ControlLayer alloc]initWithGameScene:self];
    [controlLayer setDelegate:self];
    [self addChild:controlLayer z:STATS_LEVEL];
    
    //Handle the white attack lines
    attackLines = [AttackLines node];
    [mapAndFriendsLayer addChild:attackLines z:5];
    
    //Handle the border lines between continents
    borderLines = [BorderLines nodeWithMap:gameMap];
    [mapAndFriendsLayer addChild:borderLines z:BORDER_LEVEL];
    
    //Update the screen as necessary
    [self updateTileMap];
    [self updateTerritoryLabels];
    
    //Tells the scene to handle touches
    [self setTouchEnabled:YES];
    
    #if TARGET_IPHONE_SIMULATOR
    CCButton* victory = [CCButton spriteWithFile:@"victory.png" withPressedFile:@"victory-Pressed.png" target:self function:@selector(playerWins)];
    [victory setScale:.2];
    [victory setPosition:ccp(50,50)];
    //[self addChild:victory];
    #endif
    
    [zoomableLayer recoverPositionAndScale];
}

#pragma mark -
#pragma mark touches

-(void) registerWithTouchDispatcher
{
    //[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:NO];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
    //Swipper no swipping
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView: [touch view]];
    
    //Translate into COCOA coordinates
    touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    
    NSLog(@"Map Touch at (%f,%f)",touchLocation.x,touchLocation.y);
    
    //Handle the touch
    [self userClickedAtPoint: touchLocation];
	
}

-(void)attack
{
    attackedATerritory = YES;
    
    //FIGHT - highlighted territory attacks targeted territory
    int attackingWith = [picker currentValue];
    
    AttackResult result = [mode attackFromTerritory:highlightedTerritory toTerritory:targetedEnemy withUnits:attackingWith];
    NSLog(@"Attack Result:%d",result);
    
    [mode capturedTerritory:targetedEnemy withEmpousId:[thisPlayer empousId]];
    [controlLayer updatePlayerLabels];
    
    switch (result) {
        case WIN:
        {
            //Remove the territory from the losing player
            Player* losingPlayer = [playerLookup objectForKey:[NSString stringWithFormat:@"%d",[targetedEnemy empousId]]];
            [[losingPlayer territories] removeObject:targetedEnemy];
            
            //Set the empousId of the territory to the winning player and add it to the players territories
            [targetedEnemy setEmpousId:[thisPlayer empousId]];
            [[thisPlayer territories] addObject:targetedEnemy];
            
            //Update the map colors and unit labels
            [self updateTileMap];
            [self updateTerritoryLabels];
            
            //Check to see if the winning play now controls all the territories
            if([gameMap numberOfTerritories] == [[thisPlayer territories] count])
            {
                [self playerWins];
                return;
            }
            
            //Only get here if you didn't win
            currentPhase = MOVE_VICTORY;
            [controlLayer hideAttackButtons];
            [attackLines clearLines];
            
            //Set the picker to be the correct numbers
            int minimumUnits = 1;
            
            //Move the units automatically if the win leaves the attacker with 2 units
            if(([highlightedTerritory units] - minimumUnits) == 1){
                minimumUnits = [highlightedTerritory units] - 1;
                
                //Just move them for the player
                [targetedEnemy setUnits:minimumUnits];
                [highlightedTerritory setUnits:1];
                
                [self nextPhase];
                
                break;
            }
            
            [self updateTerritoryLabels];
            
            //Add one white line between the two territories
            [attackLines addLineFrom:[highlightedTerritory labelLocation] toEnd:[targetedEnemy labelLocation]];
            
            //Re-highlight the two territories
            [self highlightTerritory:highlightedTerritory];
            [self highlightTerritory:targetedEnemy];
            
            [controlLayer setMessage:@"Move Units"];
            
            //Update the picker
            [picker updatePickerValues:NSMakeRange(minimumUnits, ([highlightedTerritory units] - minimumUnits)) startValue:minimumUnits];
            
            //Show the checkButton to confirm the number of moved over units
            [controlLayer showCheckButton];
            
            break;
        }
            
        case LOSE:
        {
            [self resetMap];
            [controlLayer setMessage:@"Attack or touch next"];
            break;
        }
        default:
            break;
    }
    
    //Prevent cheating
    [self uploadGameAsync];
}

-(void)playerWins
{
    //Game won by thisPlayer!!
    [self resetMap]; //Resets in attack phase...then switch the game over phase
    currentPhase = GAME_OVER;
    
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    CCLayerColor* overlay = [CCLayerColor layerWithColor:ccc4(0,0,0,180)];
    [overlay changeHeight:winSize.height];
    [overlay changeWidth:winSize.width];
    [self addChild:overlay z:CONFIRMBOX_LEVEL];
    
    victoryButton = [CCButton spriteWithFile:@"victory.png" withPressedFile:@"victory-Pressed.png" touchAreaScale:2.0 target:self function:@selector(startToSendEndGame)];
    [victoryButton setPosition:center];
    [self addChild:victoryButton z:LOADING_LEVEL];
    
    [[SimpleAudioEngine sharedEngine]playEffect:@"victory.aif"];
    
    [controlLayer setMessage:@"Touch to continue"];
}

-(void)startToSendEndGame
{
    spinner = [CCLoadingOverlay nodeWithMessage:@"Saving Victory" withFont:@"Armalite Rifle"];
    [self addChild:spinner z:LOADING_LEVEL];
    [victoryButton disable];
    
    [self schedule:@selector(sendEndGame)];
}

-(void)moveUnits
{
    //Handle the reinforcements moved
    int movingUnits = [picker currentValue];
    
    [highlightedTerritory setUnits:[highlightedTerritory units] - movingUnits];
    [targetedEnemy setUnits:movingUnits];
    [self nextPhase];
}

-(void)cancelAttack
{
    [self resetMap];
}

//Respond to a touch on the Map
- (void) userClickedAtPoint:(CGPoint) point
{
    //Check to see if the point is within the bounding rectange if not return
    CGRect mapRect = [mapLayer boundingBox];
    if (!CGRectContainsPoint(mapRect, point)){
        NSLog(@"Touch not within Map.");
        return;
    }
    
    CGPoint territoryPoint = [Tools worldToMap:point];
    NSLog(@"Territory Point (%f,%f)",territoryPoint.x,territoryPoint.y);
    
    //Get the territory that the user clicked on
    TerritoryElement* territoryTouched = [gameMap getTerritoryAt:territoryPoint];
    
    switch (currentPhase) {
        case REINFORCEMENTS:
        {
            //If there is a highlighted territory unlight it
            if(highlightedTerritory != NULL){
                [self resetMap];
            }
            
            //If Territory Touched
            if(territoryTouched != NULL){
                
                //Current Territory Clicked again
                if([territoryTouched empousId] == [thisPlayer empousId]){
                    [self stopPulsePlayerTerritories];
                    [self updateTileMap];
                    
                    //Highlight Self
                    [self highlightTerritory:highlightedTerritory];
                    [self highlightTerritory:territoryTouched];
                    highlightedTerritory = territoryTouched;
                    [picker updatePickerValues:NSMakeRange(0, [territoryTouched additionalUnits] + [reinforcementLayer reinforcementsLeft] + 1) startValue:[territoryTouched additionalUnits]];
                    break;
                }
            }
            break;
        }
        case ATTACK:
        {
            //If there is a highlighted territory
            if(highlightedTerritory != NULL){
                
                //See if this territory is an enemy of the highlighted territory ie ATTACK!
                if([[highlightedTerritory enemyTerritories] containsObject:territoryTouched]){
                    
                    //Remove any existing red lines
                    [attackLines clearRedLines];
                    
                    targetedEnemy = territoryTouched;
                    
                    //Selecting an enemy territory from the highlighted territory
                    [attackLines addRedLineFrom:[territoryTouched labelLocation] toEnd:[highlightedTerritory labelLocation]];
                    
                    [controlLayer disableNextButton];
                    
                    [controlLayer setMessage:@"Pick units to attack with"];
                    
                    if([picker currentValue] > 0){
                        [controlLayer showAttackButtons];
                    }
                    
                }
                
                //Another territory has been touched...clear everything
                else{
                    [self resetMap];
                    
                    //Hide the buttons only if the buttons aren't clicked
                    if(!CGRectContainsPoint([[controlLayer attackButton] boundingBox], point) && !CGRectContainsPoint([[controlLayer cancelButton ]boundingBox], point)){
                        [controlLayer hideAttackButtons];
                    }
                    
                    //Remove the white lines
                    [attackLines clearLines];
                    
                    //Adjust the amount of reinforcements left and update picker
                    [picker updatePickerValues:NSMakeRange(0,0) startValue:0];
                }
            }
            
            //Highlight territory and enemies if clicked
            if(territoryTouched != NULL){
                int attackUnits = [mode unitsAllowedInAttack:territoryTouched];
                if([territoryTouched empousId] == [thisPlayer empousId] && attackUnits > 0){
                    [self stopPulsePlayerTerritories];

                    [controlLayer setMessage:@"Select enemy to attack"];
                    
                    //Highlight New territory and enemies
                    [self highlightTerritory:territoryTouched];
                    for(TerritoryElement* enemy in [territoryTouched enemyTerritories]){
                        [self highlightTerritory:enemy];
                        [attackLines addLineFrom:[territoryTouched labelLocation] toEnd:[enemy labelLocation]];
                    }
                    highlightedTerritory = territoryTouched;
                    
                    //Set the picker using the game mode
                    attackUnits = [mode unitsAllowedInAttack:territoryTouched];
                    [picker updatePickerValues:NSMakeRange(0, attackUnits + 1) startValue:0];
                    
                    break;
                }
            }
            break;
            
        }
        case MOVE_VICTORY:
        {
            //Handled elsewhere in attack touched method
            break;
        }
        case FORTIFY:
            //See if the clicked territory is the players and connected to the first territory
            if(highlightedTerritory != NULL){
                
                if(territoryTouched != NULL){
                    
                    //If they are connected then...(We know they belong to the same player)
                    if([self isFirstTerritoryConnected:highlightedTerritory toSecondTerritory:territoryTouched]){
                        
                        //Check to see if there is a targetedTerritory
                        if(targetedEnemy == NULL){
                            //Highlight the touched territory
                            [self highlightTerritory:territoryTouched];
                            targetedEnemy = territoryTouched;
                        }else{
                            //Clear the reinforcement layer
                            [mapAndFriendsLayer removeChild:reinforcementLayer cleanup:YES];
                            
                            //Unhighlight the old and highlight the new
                            [self highlightTerritory:targetedEnemy];
                            targetedEnemy = territoryTouched;
                            [self highlightTerritory:territoryTouched];
                        }
                        
                        //Add the reinforcement layer
                        reinforcementLayer = [[[ReinforcementLabelsLayer alloc] initWithSourceTerritory:highlightedTerritory toSinkTerritory:targetedEnemy] autorelease];
                        [mapAndFriendsLayer addChild:reinforcementLayer z:REINFORCEMENT_LABEL_LEVEL];
                        
                        //Activate the picker
                        [picker updatePickerValues:NSMakeRange(0, [highlightedTerritory units]) startValue:0];
                        break;
                    }
                }
            }
            
            //Clear the fortify values and forti
            fortifyPlaced = NO;
            
            //Clear everything if the territory is null or not connected to the highlighted territory
            [self resetMap];
            
            //Highlight the territory and all the connected territories in a BFS fashion if it exists
            if(territoryTouched != NULL){
                if([territoryTouched empousId] == [thisPlayer empousId]){
                    [self stopPulsePlayerTerritories];

                    [self highlightTerritory:territoryTouched];
                    highlightedTerritory = territoryTouched;
                    [self highlightConnectedFriendlyTerritories:territoryTouched];
                }
            }
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Game Functions

//Go through the players and update the colors of the tiles to match
-(void)updateTileMap{
    for(id key in playerLookup)
    {
        Player* player = [playerLookup objectForKey:key];
        for(TerritoryElement* territory in [player territories]){
            [territory setHighlighted:NO];
            NSMutableSet* controlledTiles = [territory controlledCoordinates];
            
            //Color all the tiles that territory controls
            for(NSMutableArray* tileLocation in controlledTiles){
                int xLoc = [(NSNumber*)[tileLocation objectAtIndex:0] intValue];
                int yLoc = [(NSNumber*)[tileLocation objectAtIndex:1] intValue];
                CCSprite* tile = [mapTiles tileAt:[Tools mapToTileMap:gameMap point:CGPointMake(xLoc, yLoc)]];
                ccColor4B playerColor = [player color];
                ccColor3B color = ccc3(playerColor.r,playerColor.g,playerColor.b);
                [tile setColor:color];
            }
        }
    }
}

//Updates the labels which represent the
-(void)updateTerritoryLabels
{
    NSLog(@"Updating Territories");
    for(TerritoryElement* territory in [gameMap territories]){
        NSLog(@"Territory Units: %d", [territory units]);
        CCLabelTTF* text = (CCLabelTTF*)[territoryValues getChildByTag:[territory tId]];
        [text setString:[NSString stringWithFormat:@"%d",[territory units]]];
    }
}

/*
 * Resets the map depending on the currentPhase
 */
-(void)resetMap
{
    [self stopPulsePlayerTerritories];

    switch (currentPhase) {
        case REINFORCEMENTS:
        {
            if(highlightedTerritory != NULL){
                [self highlightTerritory:highlightedTerritory];
                highlightedTerritory = NULL;
                
                //Adjust the amount of reinforcements left and update picker
                [picker updatePickerValues:NSMakeRange(0,[reinforcementLayer reinforcementsLeft] + 1) startValue:0];
            }
            break;
        }
        case ATTACK:
        {
            [controlLayer setMessage:@"Attack"];
            
            if(highlightedTerritory){
                [self highlightTerritory:highlightedTerritory];
                for(TerritoryElement* enemy in [highlightedTerritory enemyTerritories]){
                    [self highlightTerritory:enemy];
                }
                highlightedTerritory = NULL;
                targetedEnemy = NULL;
                
                //Remove the white lines
                [attackLines clearLines];
                
                //Adjust the amount of reinforcements left and update picker
                [picker updatePickerValues:NSMakeRange(0,0) startValue:0];
                
                [controlLayer hideAttackButtons];
            }
            
            break;
        }
        case MOVE_VICTORY:
        {
            [self highlightTerritory:highlightedTerritory];
            [self highlightTerritory:targetedEnemy];
            
            highlightedTerritory = NULL;
            targetedEnemy = NULL;
            
            [attackLines clearLines];
            
            //Adjust the amount of reinforcements left and update picker
            [picker updatePickerValues:NSMakeRange(0,0) startValue:0];
            
            [controlLayer hideCheckButton];
            break;
        }
        case FORTIFY:
        {
            if(reinforcementLayer != NULL){
                [zoomableLayer removeChild:reinforcementLayer cleanup:YES];
            }
            //Remove the white lines
            [attackLines clearLines];
            highlightedTerritory = NULL;
            targetedEnemy = NULL;
        }
            
        default:
            //Remove the white lines
            [attackLines clearLines];
            highlightedTerritory = NULL;
            targetedEnemy = NULL;
            break;
    }
    
    //Update the colors to normal
    [self updateTileMap];
    
    //Update the labels for unit counts
    [self updateTerritoryLabels];
    
    [self pulseOnPlayerTerritories];
    
    //Reset the picker
    [picker updatePickerValues:NSMakeRange(0, 0) startValue:0];
}

/*
 * Called when the picker value changes 
 */
-(void)pickerValueChanged:(int)value
{
    if(highlightedTerritory != NULL){
        switch (currentPhase) {
            case REINFORCEMENTS:
            {
                //If ADDING: Value > additionalUnits and difference positive
                //If REMOVING: Value < additionalUnits and difference negative
                int difference = value - [highlightedTerritory additionalUnits];
                
                //Update additional units in TerritoryElement
                [highlightedTerritory setAdditionalUnits:value];
                
                //Update reinforcement label for territory
                CCLabelTTF* label = (CCLabelTTF*)[reinforcementLayer getChildByTag:[highlightedTerritory tId]];
                [label setString:[NSString stringWithFormat:@"+%d",value]];
                
                //Update reinforcement left label and number
                int reinforcementsLeft = [reinforcementLayer reinforcementsLeft] - difference;
                [reinforcementLayer setReinforcementsLeft:reinforcementsLeft];
                [controlLayer setMessage:[NSString stringWithFormat:@"%d Reinforcements Left", [reinforcementLayer reinforcementsLeft]]];
                
                if(reinforcementsLeft == 0)
                {
                    [controlLayer setMessage:@"If done, touch next"];
                }
                break;
            }
            case ATTACK:
            {
                if(value > 0){
                    if(highlightedTerritory != NULL && targetedEnemy != NULL){
                        [controlLayer showAttackButtons];
                        break;
                    }
                }
                [controlLayer hideAttackButtons];
                
                break;
            }
            case MOVE_VICTORY:
            {
                //Do Nothing...picker only is checked when done is clicked
                break;
            }
            case FORTIFY:
            {
                //Update additional units in TerritoryElement
                [targetedEnemy setAdditionalUnits:value];
                [highlightedTerritory setAdditionalUnits:-value];
                
                //Update targetTerritory
                CCLabelTTF* label = (CCLabelTTF*)[reinforcementLayer getChildByTag:[targetedEnemy tId]];
                [label setString:[NSString stringWithFormat:@"+%d",value]];
                
                //Update reinforcement left label and number
                CCLabelTTF* label2 = (CCLabelTTF*)[reinforcementLayer getChildByTag:[highlightedTerritory tId]];
                [label2 setString:[NSString stringWithFormat:@"-%d",value]];
                
                break;
            }
            default:
                break;
        }
    }
}

-(void)showMenu
{
    [self stopPulsePlayerTerritories];
    if(![[self children]containsObject:menu])
    {
        //Add the menu offscreen
        menu = [GameMenu nodeWithDelegate:self];
        [menu setOpacity:0];
        
        //Needed to get it to show over picker
        [self addChild:menu z:CONFIRMBOX_LEVEL];
        
        [menu runAction:[CCFadeIn actionWithDuration:.5]];
    }
}

-(void)hideMenu
{
    id fadeOut = [CCFadeOut actionWithDuration:.5];
    id cleanUp = [CCCallFunc actionWithTarget:self selector:@selector(cleanUpMenu)];
    [menu runAction:[CCSequence actions:fadeOut,cleanUp, nil]];
}

-(void)cleanUpMenu
{
    [self removeChild:menu cleanup:YES];
}

/**
 This method will handle any cleanup for the current phase, then advance to the next.
 */
-(void)nextPhase
{
    [self nextPhaseWithForce:NO];
}

/**
 This method will handle any cleanup for the current phase, then advance to the next
 The skipAlertChecks forces the next phase method to skip any warnings
 */
-(void)nextPhaseWithForce:(BOOL)skipAlertChecks
{
    switch (currentPhase) {
        case REINFORCEMENTS:
        {
            //Check to see if there are still reinforcements left
            if([reinforcementLayer reinforcementsLeft] != 0 && skipAlertChecks == NO)
            {
                UIAlertView* dialog = [[UIAlertView alloc] init];
                [dialog setDelegate:self];
                [dialog setTitle:@"Reinforcements Left"];
                [dialog setMessage:@"You still have reinforcements left. Are you sure you want to continue to the attack phase?"];
                [dialog addButtonWithTitle:@"Yes"];
                [dialog addButtonWithTitle:@"No"];
                [dialog show];
                [dialog release];
            }
            else
            {
                //Go through the territory elements and add the additional units to the territories
                for(TerritoryElement* territory in [thisPlayer territories])
                {
                    [territory confirmAdditionalUnits];
                }
                [mapAndFriendsLayer removeChild:reinforcementLayer cleanup:YES];
                currentPhase = ATTACK;
                [controlLayer setMessage:@"Attack"];
                [self uploadGameAsync];
                attackedATerritory = NO;
            }
            break;
        }
        case ATTACK:
        {
            if(attackedATerritory == NO && skipAlertChecks == NO){
                UIAlertView* dialog = [[UIAlertView alloc] init];
                [dialog setDelegate:self];
                [dialog setTitle:@"No Territories Attacked"];
                [dialog setMessage:@"You have not attacked a territory. Are you sure you want to continue to the fortify phase?"];
                [dialog addButtonWithTitle:@"Yes"];
                [dialog addButtonWithTitle:@"No"];
                [dialog show];
                [dialog release];
            } else {
                currentPhase = FORTIFY;
                [controlLayer setMessage:@"Fortify"];
                fortifyPlaced = NO;
                [self uploadGameAsync];
            }
            break;
        }
        case FORTIFY:
        {
            currentPhase = TURN_OVER;
            
            //Go through the territory elements and add the additional units to the territories
            for(TerritoryElement* territory in [thisPlayer territories])
            {
                [territory confirmAdditionalUnits];
            }
            [mapAndFriendsLayer removeChild:reinforcementLayer cleanup:YES];
            [controlLayer setMessage:@"Turn Over"];
            
            spinner = [CCLoadingOverlay nodeWithMessage:@"Uploading Game" withFont:@"Armalite Rifle"];
            [self addChild:spinner z:LOADING_LEVEL];
            [self schedule:@selector(sendTurnOver)];
            break;
        }
        case TURN_OVER_FAILED_SEND:
            //Try to send again
            spinner = [CCLoadingOverlay nodeWithMessage:@"Uploading Game" withFont:@"Armalite Rifle"];
            [self addChild:spinner z:LOADING_LEVEL];
            
            [self schedule:@selector(sendTurnOver)];
            break;
        case MOVE_VICTORY:
        {
            [controlLayer setMessage:@"Attack or touch next"];
            currentPhase = ATTACK;
            [self uploadGameAsync];
            break;
        }
        default:
        {
            //This is game over
            break;
        }
    }
    
    //Must be called here to reset the map properly based on the game mode
    [self resetMap];
}


//Called when the user clicks a button in an alert view
-(void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (currentPhase == FIRST_TIME)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"shownHowTo"];
        
        [self stopPulsePlayerTerritories];
        currentPhase = REINFORCEMENTS;
        if (buttonIndex == 1)
        {
            //Show How to
            [[CCDirector sharedDirector] pushScene:[CCTransitionFade transitionWithDuration:0.5f scene:[TutorialScene node]]];
        }
    }
    else
    {
        [self resetMap];
        if(buttonIndex == 0)
        {
            [self nextPhaseWithForce:YES];
        }
    }
}

- (void) layerPanZoom: (CCLayerPanZoom *) sender touchPositionUpdated: (CGPoint) newPos
{
    NSLog(@"Position (%f, %f)", newPos.x, newPos.y);
}

- (void) layerPanZoom: (CCLayerPanZoom *) sender
       clickedAtPoint: (CGPoint) aPoint
             tapCount: (NSUInteger) tapCount
{
    NSLog(@"Click (%f, %f)", aPoint.x, aPoint.y);
    [self userClickedAtPoint:aPoint];
}

- (void) layerPanZoom: (CCLayerPanZoom *) sender touchMoveBeganAtPosition: (CGPoint) aPoint
{
    NSLog(@"Touch Move (%f, %f)", aPoint.x, aPoint.y);
}

@end
