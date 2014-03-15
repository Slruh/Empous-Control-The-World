//
//  GameSceneArchive.m
//  Empous
//
//  Created by Ryan Hurley on 4/9/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "GameScene+ArchiveHttpUtils.h"
#import "Tools.h"
#import "EmpousAPIWrapper.h"
#import "CurrentGamesScene.h"
#import "MainMenuScene.h"
#import "CCRenderTexture.h"
#import "SimpleAudioEngine.h"

@implementation GameScene (ArchiveHttpUtils)

-(NSString*)createScreenShot
{
    //Hide the controls and add black control layer
    //Hide control layer
    [controlLayer setVisible:NO];
    [picker setVisible:NO];
    BOOL spinnerActive = [[self children] containsObject:spinner];
    if(spinnerActive)
    {
        [spinner setVisible:NO];
    }
    
    CCLayerColor* colorLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 255)];
    [self addChild:colorLayer z:BACKGROUND_LEVEL];
    
    //Take the screen shot
    [CCDirector sharedDirector].nextDeltaTimeZero = YES;
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    CCRenderTexture* rtx = [CCRenderTexture renderTextureWithWidth:winSize.width height:winSize.height ];
    [rtx begin];
    [screenShotLayer visit];
    [rtx end];

    NSString* empousGameString = [NSString stringWithFormat:@"%d",empousGameId];
    BOOL success = [rtx saveToFile:[Tools screenshotArchiveFilename:empousGameString deleteIdExists:YES] format:kCCImageFormatPNG];
    NSLog(@"Image saved successfully?: %@", success ? @"YES" : @"NO");
    //Put back elements
    [controlLayer setVisible:YES];
    [picker setVisible:YES];
    if(spinnerActive)
    {
        [spinner setVisible:YES];
    }
    
    [self removeChild:colorLayer cleanup:YES];
    
    return [Tools screenshotArchivePathWithGameId:empousGameString deleteIfExists:NO];
}

-(NSString*)archiveCurrentGame
{
    NSString* path = [Tools jsonGameArchivePathWithGameId:[NSString stringWithFormat:@"%d",empousGameId] deleteIfExists:YES];
    NSString* jsonState = [self jsonArchiveCurrentGame];
    [jsonState writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"PATH %@", path);
    return jsonState;
}

-(NSString*)jsonArchiveCurrentGame
{
    NSDictionary* jsonData = [self toJSONDict];
    NSData* data = [NSJSONSerialization dataWithJSONObject:jsonData options:0 error:nil];
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

-(void)uploadGameAsync
{
    //Prevents cheating by archiving after each phase
    NSString* jsonState = [self archiveCurrentGame];
    NSString* screenshotFilePath = [self createScreenShot];
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:empousGameId], @"gameId",
                            [NSNumber numberWithInt:currentPlayerId], @"empousId",
                            jsonState, @"jsonState",
                            screenshotFilePath, @"screenshotFilePath"
                            , nil];
    
    [[EmpousAPIWrapper sharedEmpousAPIWrapper] performSelectorInBackground:@selector(updateEmpousGameAsync:) withObject:params];
}

-(void)sendTurnOver
{
    [self unschedule:@selector(sendTurnOver)];
    
    //Save the last player in case the save doesn't work
    int last_player = [self setNextPlayer];
    if (currentPlayerId == [thisPlayer empousId])
    {
        [NSException raise:@"New player id is equal to current player" format:@"The old id was %d", last_player];
    }
    
    BOOL uploaded = [[EmpousAPIWrapper sharedEmpousAPIWrapper] updateEmpousGame:empousGameId currentPlayer:last_player nextPlayer:currentPlayerId withGameState:[self archiveCurrentGame] withScreenShot:[self createScreenShot]];
    if(!uploaded)
    {
        [self removeChild:spinner cleanup:YES];
        currentPlayerId = last_player;
    }
    
    //Remove game_state json file and screenshot
    [Tools jsonGameArchivePathWithGameId:[NSString stringWithFormat:@"%d", empousGameId] deleteIfExists:YES];
    [Tools screenshotArchivePathWithGameId:[NSString stringWithFormat:@"%d", empousGameId] deleteIfExists:YES];
    
    [self removeChild:spinner cleanup:YES];
    
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:1.0f];
    
    [[CCDirector sharedDirector] replaceScene:
     [CCTransitionFade transitionWithDuration:0.5f scene:[CurrentGamesScene nodeWasPushed:NO]]];
}

-(void)sendEndGame
{
    [self unschedule:@selector(sendEndGame)];
    
    //Send the game to the server
    BOOL uploaded = [[EmpousAPIWrapper sharedEmpousAPIWrapper] empousGameFinished:empousGameId winningPlayer:currentPlayerId withGameState:[self jsonArchiveCurrentGame] withScreenShot:[self createScreenShot]];
    if(!uploaded)
    {
        [self removeChild:spinner cleanup:YES];
        NSLog(@"Unable to Upload end of turn");
        [[CCDirector sharedDirector] replaceScene:
         [CCTransitionFade transitionWithDuration:0.5f scene:[MainMenuScene node]]];
    }
    
    //Remove game_state json file and screenshot
    [Tools jsonGameArchivePathWithGameId:[NSString stringWithFormat:@"%d", empousGameId] deleteIfExists:YES];
    [Tools screenshotArchivePathWithGameId:[NSString stringWithFormat:@"%d", empousGameId] deleteIfExists:YES];
    [self removeChild:spinner cleanup:YES];
    
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:1.0f];
    
    [[CCDirector sharedDirector] replaceScene:
     [CCTransitionFade transitionWithDuration:0.5f scene:[CurrentGamesScene nodeWasPushed:NO]]];
}

//Sets the next player - but returns the last player in case it needs to be reset
-(int)setNextPlayer
{
    int last_player = currentPlayerId;
    
    //Change the current player turn to the next in the playersTurnArray
    while(true)
    {
        NSNumber* empousId = [[orderOfPlayersTurns objectAtIndex:0] retain];
        currentPlayerId = [empousId intValue];
        
        [orderOfPlayersTurns removeObjectAtIndex:0];
        [orderOfPlayersTurns addObject:empousId];
        [empousId release];
        
        //Check to make sure this player has territories
        Player* possibleNextPlayer = [playerLookup objectForKey:[NSString stringWithFormat:@"%d",currentPlayerId]];
        
        if ([[possibleNextPlayer territories]count] > 0)
        {
            return last_player;
        }
    }
}

@end
