//
//  GameSceneArchive.h
//  Empous
//
//  Created by Ryan Hurley on 4/9/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "GameScene.h"

/**
 A category which contains the methods necessary for archiving a Empous game.
 */
@interface GameScene (ArchiveHttpUtils)

/**
 Creates a screen shot of the current empous game.
 @returns the path to the screen shot.
 */
-(NSString*)createScreenShot;

/**
 Creates an archive of the current empous game.
 @return the path to the archive file
 */
-(NSString*)archiveCurrentGame;

/**
 Sends an archive of the game and screen shot when the turn is over
 */
-(void)sendTurnOver;

/**
 Sends an archive of the game and screen shot when thisPlayer has won the game
 */
-(void)sendEndGame;

/**
 Sends an archive of the game and screen shot whenever a play performs an action. Used as an anticheating measure.
 */
-(void)uploadGameAsync;





@end
