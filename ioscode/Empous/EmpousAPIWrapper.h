//
//  EmpousAPIWrapper.h
//  Empous
//
//  Created by Ryan Hurley on 6/10/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Player.h"

extern const NSString* baseUrl;

@protocol EmpousWrapperDelegate<NSObject>
@optional
-(void)playerLoggedIn;
-(void)playerFailedLogIn:(NSString*)errorMessage;
-(void)playerFailedLogInNeedUsername;
-(void)loginNeedsRevalidation:(NSString*)error;
-(void)numberOfGamesReceived:(NSDecimalNumber*)numGames;
-(void)friendsWithApp:(NSString*)invitedUser;
-(void)tokenResponse:(NSString*)response;
-(void)passwordResetResponse:(BOOL)success message:(NSString*)errorMessage;
-(void)foundRandomPlayer:(NSDictionary*)player;
-(void)noRandomPlayersAvailable;
@end

@interface EmpousAPIWrapper : NSObject{
    id <EmpousWrapperDelegate> delegate;
    NSMutableArray *friends; //Sorted List of friends
    NSMutableDictionary *friendMap; //Used to update friends
}

@property (readonly) NSMutableArray* friends;


+(id)sharedEmpousAPIWrapper;

-(void)setDelegate:(id)newdelegate;

-(NSString*)playerName;

-(NSString*)playerUsername;

//Checks to make sure empous is reachable
-(BOOL)empousConnectionAvailable;

//Checks if the username is available
-(BOOL)checkIfUsernameAvailable:(NSString*)username;

//Creates a new empous user, using a valid Facebook access token
-(void)createEmpousUserWithFacebook:(NSString*)facebookAccessToken;

//Checks to see if the user is allowed to create a new game
-(BOOL)checkIfPlayerCanCreateAGame;

//Creates a new empous user, using a valid Facebook access token
-(void)createEmpousUserWithFacebookAndUsernameDict:(NSDictionary*)inputParams;

//Creates a new empous user, using normal info
-(void)createEmpousUserWithUsername:(NSString*)username password:(NSString*)password firstName:(NSString*)firstName lastName:(NSString*)lastName email:(NSString*)email;

//Resets the password of an empous user
-(void)resetPasswordForEmpousUserWithUsernameOrEmail:(NSString*)usernameOrEmail password:(NSString*)password token:(NSString*)token;

//Returns an empous id
-(int)createInvitedEmpousUserWithFacebookId:(int)facebookID andFirstName:(NSString*)firstName andLastName:(NSString*)lastName;

-(BOOL)loginUsingToken;

-(BOOL)loginWithEmpousUsernameOrEmail:(NSString*)usernameOrEmail password:(NSString*)password;

-(BOOL)inviteUserToGame:(NSString*)username;

//Get friends - Check callbacks
-(void)getFriends;

//Create a new empous game with players - returns the id of the game
-(int)createEmpousGame:(Player*)creatingPlayer withEnemies:(NSMutableArray*)enemyPlayers withGameState:(NSString*)jsonState withScreenShot:(NSString*)screenshotFilePath;

//The path to the game file to upload.
-(BOOL)updateEmpousGame:(int)gameId currentPlayer:(int)currentEmpousId nextPlayer:(int)nextEmpousId withGameState:(NSString*)jsonState withScreenShot:(NSString*)screenshotFilePath;

//Used to async the game between player phases like reinforcement and fortify...we really don't care if the requests makes it
//Current player is needed so the server can ignore out of order requests
-(void)updateEmpousGameAsync:(NSDictionary*)gameParams;

//Marks a game as finished with a winner
-(BOOL)empousGameFinished:(int)gameId winningPlayer:(int)empousId withGameState:(NSString*)jsonState withScreenShot:(NSString*)screenshotFilePath;

//Get the information for all your current games
-(NSArray*)getGameList;

-(NSArray*)getCompletedGames;

//Get the number of games where it is your turn
-(void)numberPlayableGames;

//Attempts to send a token for a user
-(void)sendTokenForUser:(NSString*)usernameOrEmail;

-(void)changeMatchmakingSettingForPlayer:(BOOL)matchmakingEnabled;

-(void)findRandomPlayer;

@end
