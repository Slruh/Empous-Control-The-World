//
//  GameViewingMenu.m
//  Empous
//
//  Created by Ryan Hurley on 6/22/13.
//  Copyright (c) 2013 HurleyProg. All rights reserved.
//

#import "GameViewingMenu.h" 
#import "cocos2d.h"
#import "MainMenuScene.H"
#import "CCLoadingOverlay.h"
#import "BottomBar.h"
#import "Tools.h"
#import "ASIHTTPRequest.h"
#import "SimpleAudioEngine.h"

static NSDictionary* _lastReturnedGames = nil;

@implementation GameViewingMenu
{

    CCLoadingOverlay* _spinner;
    BOOL _showCompleted;
}

@synthesize target = _target;
@synthesize selector = _selector;

+(id)nodeWithTitle:(NSString*)title target:(id)object selector:(SEL)function pushed:(BOOL)wasPushed showCompleted:(BOOL)onlyCompletedText
{
    return [[[self alloc]initWithTitle:title target:object selector:function pushed:wasPushed showCompleted:(BOOL)onlyCompletedText]autorelease];
}

-(id)initWithTitle:(NSString*)title target:(id)object selector:(SEL)function pushed:(BOOL)wasPushed showCompleted:(BOOL)onlyCompletedText
{
    if(self = [super init])
    {
        [Tools playEmpousThemeIfNotSilenced];
        
        //Assign the target and delegates
        _target = object;
        _selector = function;
        
        //Get screensize
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp(winSize.width/2,winSize.height/2);
        
        //Add the Sprite for the background
        CCSprite* background = [CCSprite spriteWithFile: @"Empous-Background.png"];
        background.position = ccp(center.x, 160);
        [self addChild:background];
        
        //Add the bottom bar with play button
        BottomBar* bottomBar = [BottomBar nodeWithPlayButton:(!onlyCompletedText) andDelegate:self withPush:wasPushed];
        [self addChild:bottomBar z:1];
        
        //Title Label
        CCLabelTTF* createNewGameLabel = [CCLabelTTF labelWithString:title fontName:@"Armalite Rifle" fontSize:20];
        [createNewGameLabel setPosition:ccp(center.x,15)];
        [self addChild:createNewGameLabel z:2];
        
        _showCompleted = onlyCompletedText;
        
        //Clear the texture caches, otherwise the maps won't refresh
        [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFrames];
        [[CCTextureCache sharedTextureCache] removeAllTextures];
        
        _spinner = [CCLoadingOverlay nodeWithFont:@"Armalite Rifle"];
        [self addChild:_spinner z:3];
    }
    return self;
}

- (void)onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];
    [self schedule:@selector(loadGames)];
}

-(void) onExit{
    [self unscheduleAllSelectors];
    [self removeAllChildrenWithCleanup:YES];
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [super onExit];
}

+(NSDictionary*)getLastGames
{
    if(_lastReturnedGames == nil)
    {
        _lastReturnedGames = [[NSMutableDictionary alloc] init];
    }
    
    NSString* key = NSStringFromClass([self class]);
    
    if([_lastReturnedGames objectForKey:key] == nil)
    {
        [_lastReturnedGames setValue:[NSMutableDictionary dictionary] forKey:key];
    }
    
    return [_lastReturnedGames objectForKey:key];
}

-(void)reloadGames
{
    //Add a spinner
    _spinner = [CCLoadingOverlay nodeWithFont:@"Armalite Rifle"];
    [self addChild:_spinner z:3];
    
    //If there is already a scroll menu, remove it (used when app returns to current game)
    if([[self children] containsObject:scrollGames])
    {
        [self removeChild:scrollGames cleanup:YES];
    }
    
    [self schedule:@selector(loadGames)];
}

-(void)loadGames
{
    [self unschedule: @selector(loadGames)];
    
    //Get the game list from the server and download the images for preview...files can be downloaded later. This array is already sorted with playable games first
    gameList = [self.target performSelector:self.selector withObject:self];
    
    NSDictionary* lastReturnedGames = [GameViewingMenu getLastGames];
    
    NSMutableArray* layersForScrolling = [[NSMutableArray alloc] init];
    
    int numberPlayableGames = 0;
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    for(id game in gameList)
    {
        //Create a layer for each game
        CCLayer* gameLayer = [CCLayer node];
        
        NSDictionary* gameDict = (NSDictionary*)game;
        NSString* gameId = [gameDict objectForKey:@"id"];
        NSDictionary* lastGameDict = [lastReturnedGames objectForKey:gameId];
        
        //Download the screenshot
        NSString* screenshotUrl = [gameDict objectForKey:@"screenshot_url"];
        NSString* downloadPath = [Tools screenshotArchivePathWithGameId:gameId deleteIfExists:NO];
        
        //Check to see if we are missing a screen shot
        if(nil == lastGameDict || ![Tools screenshotAvailable:gameId] || ![screenshotUrl isEqualToString:[lastGameDict objectForKey:@"screenshot_url"]] || [[gameDict objectForKey:@"isTurn"] boolValue])
        {            
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:screenshotUrl]];
            [request setDownloadDestinationPath:downloadPath];
            [request startSynchronous];
        }
        
        //Get the map as a sprite
        CCSprite* thumbnail = [CCSprite spriteWithFile:downloadPath];
        float scale = .5f;
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]
            && [[UIScreen mainScreen] scale] == 2.0)
        {
            // Retina
            scale *= 2;
        }
        thumbnail.scaleX = scale;
        thumbnail.scaleY = scale;
        thumbnail.position =  ccp( screenSize.width /2 , screenSize.height/2);
        if(thumbnail != nil)
        {
            [gameLayer addChild:thumbnail];
        }
        else
        {
            CCLabelTTF* noImageMessage = [CCLabelTTF labelWithString:@"(No Image Available)" fontName:@"Armalite Rifle" fontSize:20];
            [noImageMessage setColor:ccWHITE];
            [noImageMessage setPosition:ccp( screenSize.width /2,screenSize.height/2 - 20)];
            
            [gameLayer addChild:[Tools createStroke:noImageMessage size:1 color:ccBLACK]];
            [gameLayer addChild:noImageMessage];
        }
        
        if (_showCompleted)
        {
            BOOL isVictor = [[gameDict objectForKey:@"isVictor"] isEqualToString:@"yes"];
            if(isVictor)
            {
                [self addTextOverMap:@"Victor" layer:gameLayer];
            }
            else
            {
                [self addTextOverMap:@"Loser" layer:gameLayer];
            }
        }
        else
        {
            BOOL isYourTurn = [[gameDict objectForKey:@"isTurn"] isEqualToString:@"yes"];
            if(isYourTurn)
            {
                numberPlayableGames ++;
                [self addTextOverMap:@"Your Move" layer:gameLayer];
            }
            else
            {
                [self addTextOverMap:[NSString stringWithFormat:@"%@'s Turn",[gameDict objectForKey:@"current_player"]] layer:gameLayer];
            }
        }
        
        NSString* enemies = @"Enemies:";
        NSArray* enemyPlayers = [gameDict objectForKey:@"enemies"];
        int numEnemies = [enemyPlayers count];
        for (id player in enemyPlayers)
        {
            numEnemies--;
            if(numEnemies == 0 && [enemyPlayers count] > 1)
            {
                enemies = [enemies stringByAppendingFormat:@" and %@", player];
            }
            else if(numEnemies == 0 && [enemyPlayers count] == 1)
            {
                enemies = [enemies stringByAppendingFormat:@" %@", player];
            }
            else if(numEnemies == 1 && [enemyPlayers count] == 2)
            {
                enemies = [enemies stringByAppendingFormat:@" %@ ", player];
            }
            else
            {
                enemies = [enemies stringByAppendingFormat:@" %@,", player];
            }
        }
        
        CCLabelTTF* players = [CCLabelTTF labelWithString:enemies fontName:@"Armalite Rifle" fontSize:20];
        [players setColor:ccWHITE];
        [players setPosition:ccp(screenSize.width /2, 305)];
        
        [gameLayer addChild:[Tools createStroke:players size:1 color:ccBLACK]];
        [gameLayer addChild:players];
        
        //Add the game Id, useful for debugging
        CCLabelTTF* gameIdLabel = [CCLabelTTF labelWithString:[gameId description] fontName:@"Armalite Rifle" fontSize:15];
        [gameIdLabel setColor:ccWHITE];
        [gameIdLabel setPosition:ccp(20, 50)];
        [gameLayer addChild:gameIdLabel];
        
        //Replace the dictionary
        [lastReturnedGames setValue:gameDict forKey:gameId];
        
        [layersForScrolling addObject:gameLayer];
    }
    
    //Display no games when there aren't any
    if([layersForScrolling count] == 0 ){
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint point = ccp(winSize.width/2, winSize.height/2);
        CCLabelTTF* noGameLabel = [CCLabelTTF labelWithString:@"No Games Found" fontName:@"Armalite Rifle" fontSize:30];
        [noGameLabel setPosition:point];
        [self addChild:noGameLabel];
    }
    else
    {
        scrollGames = [CCScrollLayer nodeWithLayers:layersForScrolling widthOffset:0];
        scrollGames.stealTouches = NO;
        scrollGames.pagesIndicatorPosition = ccp(screenSize.width * 0.5f, 45);
        [self addChild:scrollGames];
    }
    
    [layersForScrolling release];
    
    //Update the badge
    if(!_showCompleted)
    {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:numberPlayableGames];
    }
    
    //Cleanup spinner
    [self removeChild:_spinner cleanup:YES];
}

-(void) addTextOverMap:(NSString*)text layer:(CCLayer*)layer
{
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    
    CCLabelTTF* labelForground = [CCLabelTTF labelWithString:text fontName:@"Armalite Rifle" fontSize:30];
    [labelForground setColor:ccWHITE];
    [labelForground setPosition:ccp(screenSize.width /2, screenSize.height/2 + 10)];
    [layer addChild:[Tools createStroke:labelForground size:1 color:ccBLACK]];
    [layer addChild:labelForground];
}

- (void) handleReturnToMain
{
    [[CCDirector sharedDirector] replaceScene:
	 [CCTransitionFade transitionWithDuration:0.5f scene:[MainMenuScene node]]];
}

@end
