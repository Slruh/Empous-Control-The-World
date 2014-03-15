//
//  CurrentGamesScene.m
//  Empous
//
//  Created by Ryan Personal on 3/4/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "CurrentGamesScene.h"
#import "MainMenuScene.h"
#import "EmpousAPIWrapper.h"
#import "ASIHTTPRequest.h"
#import "GameScene.h"
#import "Tools.h"

@implementation CurrentGamesScene

+(id)nodeWasPushed:(BOOL)wasPushed
{
    return [super nodeWithTitle:@"Current Games" target:[EmpousAPIWrapper sharedEmpousAPIWrapper] selector:@selector(getGameList) pushed:wasPushed showCompleted:NO];
}

-(void)playButtonTouched
{
    if([[scrollGames children] count] == 0)
    {
        return;
    }
    //Get the current index for the slider
    int gameIndex = [scrollGames currentScreen];
    
    //Get the game from the array
    NSDictionary* selectedGame = [gameList objectAtIndex:gameIndex];
    
    NSString* gameId = [selectedGame objectForKey:@"id"];
    NSString* gameState = [selectedGame objectForKey:@"json_state"];
    
    //Check to see if there is a json state file on the local system
    //If there is use that as the game state
    NSString* localModPath = [Tools areLocalModsToGame:gameId];
    if(localModPath != nil && ![[selectedGame objectForKey:@"isTurn"] boolValue])
    {
        gameState = [NSString stringWithContentsOfFile:localModPath encoding:NSUTF8StringEncoding error:nil];
    }
    
    NSError *e = nil;
    NSMutableDictionary* gameStateDict = [NSJSONSerialization JSONObjectWithData:[gameState dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&e];
    if (e != nil)
    {
        NSLog(@"Error parsing: %@", e);
    }
    NSLog(@"%@", [gameStateDict description]);
    
    GameScene* gameScene = [[[GameScene alloc] initWithJsonData:gameStateDict] autorelease];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:1.0 scene:(CCScene*)gameScene]];
}

@end
