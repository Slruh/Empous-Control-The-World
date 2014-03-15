//
//  EmpousAPIWrapper.m
//  Empous
//
//  Created by Ryan Hurley on 6/10/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "EmpousAPIWrapper.h"
#import "FBSBJSON.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "Reachability.h"
#import "MainMenuScene.h"
#import "EmpousAPIWrapper+Http.h"


EmpousAPIWrapper* api;

#if TARGET_IPHONE_SIMULATOR
const NSString* baseUrl = @"http://127.0.0.1:8000/";
#else
const NSString* baseUrl = @"http://127.0.0.1:8000/";
#endif

@implementation EmpousAPIWrapper

@synthesize friends;

- (id)init
{
    self = [super init];
    if (self)
    {
        friends = [[NSMutableArray alloc]init];
        friendMap = [[NSMutableDictionary alloc]init];
    }
    return self;
}

+(id)sharedEmpousAPIWrapper;
{
    if(api == nil)
    {
        api = [[EmpousAPIWrapper alloc]init];
    }
    return api;
}

-(void)setDelegate:(id)newdelegate
{
    if(![[newdelegate class] conformsToProtocol:@protocol(EmpousWrapperDelegate)]){
        [NSException raise:@"Delegate Exception" format:@"Delegate of class %@ is invalid", [newdelegate class]];
    }else{
        if(delegate){
            [delegate release];
        }
        [newdelegate retain];
        delegate = newdelegate;
    }
}

-(NSString*)playerName
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"first_name"];
}

-(NSString*)playerUsername
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"username"];
}

-(BOOL)empousConnectionAvailable
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseUrl, @"health/"]];
    
    int numberOfTries = 0;
    while (numberOfTries < 3)
    {
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request startSynchronous];
        NSError *error = [request error];
        if (!error) {
            return YES;
        }
        [NSThread sleepForTimeInterval:1.0];
        numberOfTries++;
    }

    return NO;
}

-(BOOL)checkIfUsernameAvailable:(NSString*)username
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:username,@"username", nil];
    NSDictionary* result = [self sendPOSTRequest:@"api/check/" withParams:params];
    int status = [[result objectForKey:@"result"] intValue];
    
    if(status == 8)
    {
        return YES;
    }
    return NO;
}

-(BOOL)checkIfPlayerCanCreateAGame
{
    NSDictionary* result = [self sendPOSTRequest:@"api/cancreategame/"];
    int status = [[result objectForKey:@"result"] intValue];
    return (status == 0);
}

-(void)createEmpousUserWithFacebook:(NSString*)facebookAccessToken
{
    [self createEmpousUserWithFacebookAndUsernameDict:[NSDictionary dictionaryWithObjectsAndKeys:facebookAccessToken,@"token", nil]];
}

-(void)createEmpousUserWithFacebookAndUsernameDict:(NSDictionary*)inputParams
{
    NSString* facebookAccessToken = [inputParams objectForKey:@"token"];
    NSString* username = [inputParams objectForKey:@"username"];
    
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:facebookAccessToken,@"facebookToken", nil];
    if (username != nil)
    {
        [params setObject:username forKey:@"username"];
    }
    [self sendAsyncPOSTRequest:@"api/join/" withParams:params callback:@selector(handlePlayerLogin:)];
}

-(void)createEmpousUserWithUsername:(NSString*)username password:(NSString*)password firstName:(NSString*)firstName lastName:(NSString*)lastName email:(NSString*)email
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   username,@"username",
                                   password,@"password",
                                   firstName,@"first_name",
                                   lastName,@"last_name",
                                   email,@"email",
                                   nil];
    [self sendAsyncPOSTRequest:@"api/join/" withParams:params callback:@selector(handlePlayerLogin:)];
}

//Resets the password of an empous user
-(void)resetPasswordForEmpousUserWithUsernameOrEmail:(NSString*)usernameOrEmail password:(NSString*)password token:(NSString*)token
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   usernameOrEmail,@"username_or_email",
                                   password,@"password",
                                   token,@"token",
                                   nil];
    [self sendAsyncPOSTRequest:@"api/resetpassword/" withParams:params callback:@selector(handleResetPassword:)];
}

-(void)handleResetPassword:(NSMutableDictionary*)result
{
    int status = [[result objectForKey:@"result"] intValue];
    BOOL success = false;
    NSString* message = nil;
    switch (status)
    {
        case 0:
            success = true;
            break;
        case 10:
            message = [result objectForKey:@"message"];
            break;
        case 11:
            message = [result objectForKey:@"message"];
            break;
    }
    if (delegate && [delegate respondsToSelector:@selector(passwordResetResponse:message:)])
    {
        [delegate passwordResetResponse:success message:message];
    }
}

-(BOOL)loginUsingToken
{
    //Add the empous token and user id
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* token = [defaults objectForKey:@"token"];
    
    if (token == nil)
    {
        return NO;
    }
    
    NSMutableDictionary* result = [self sendPOSTRequest:@"api/login/"];
    if(result == nil || [[result objectForKey:@"result"] intValue] != 0)
    {
        return NO;
    }
    else
    {
        [self saveUserInfoFromResult:result];
        return YES;
    }
}

-(BOOL)loginWithEmpousUsernameOrEmail:(NSString*)usernameOrEmail password:(NSString*)password
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:usernameOrEmail,@"username_or_email",password,@"password", nil];
    NSMutableDictionary* result = [self sendPOSTRequest:@"api/login/" withParams:params];
    if(result == nil || [[result objectForKey:@"result"] intValue] != 0)
    {
        return NO;
    }
    else
    {
        [self saveUserInfoFromResult:result];
        return YES;
    }
}

-(void)handlePlayerLogin:(NSMutableDictionary*)result
{
    //Get the status for the request
    int resultCode = [[result objectForKey:@"result"] intValue];
    NSString* message = [result objectForKey:@"message"];
    
    switch (resultCode) {
        case 0:
            [self saveUserInfoFromResult:result];
            if(delegate != nil && [delegate respondsToSelector:@selector(playerLoggedIn)])
            {
                [delegate performSelector:@selector(playerLoggedIn)];
                break;
            }
            break;
        case 4:
            if (delegate != nil && [delegate respondsToSelector:@selector(playerFailedLogIn:)])
            {
                [delegate performSelector:@selector(playerFailedLogIn:) withObject:message];
                break;
            }
            break;
        case 2:
            // Don't call any delegate method
            break;
        case 1:
            if (delegate != nil && [delegate respondsToSelector:@selector(playerFailedLogInNeedUsername)])
            {
                [delegate performSelector:@selector(playerFailedLogInNeedUsername) withObject:nil];
                break;
            }
        default:
            NSLog(@"UNEXPECTED ERROR - %@", result);
            if (delegate != nil && [delegate respondsToSelector:@selector(loginNeedsRevalidation:)])
            {
                [delegate performSelector:@selector(loginNeedsRevalidation:) withObject:[result objectForKey:@"message"]];
            }
            return;
    }
}

-(void)saveUserInfoFromResult:(NSDictionary*)userDict
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[userDict objectForKey:@"empous_id"] forKey:@"empous_id"];
    [defaults setObject:[userDict objectForKey:@"username"] forKey:@"username"];
    [defaults setObject:[userDict objectForKey:@"first_name"] forKey:@"first_name"];
    [defaults setObject:[userDict objectForKey:@"token"] forKey:@"token"];
    [defaults setObject:[userDict objectForKey:@"matchmaking_enabled"] forKey:@"matchmakingAllowed"];
    [defaults synchronize];
}

-(void)handleLoginFailed:(NSError*)error
{
    if(delegate != nil && [delegate respondsToSelector:@selector(playerFailedLogIn:)])
    {
        if(error != nil)
        {
            [delegate performSelector:@selector(playerFailedLogIn:) withObject:[error description]];

        }
        else
        {
            [delegate performSelector:@selector(playerFailedLogIn:) withObject:@"An unknown error occurred. Try again later."];
        }
    }
    return;
}

-(BOOL)inviteUserToGame:(NSString*)username
{
    NSMutableDictionary* result = [self sendPOSTRequest:@"api/invite/" withParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:username,@"username", nil]];
    if(result != nil)
    {
        if([result objectForKey:@"error"])
        {
            return NO;
        }
        else
        {
            [self handleFriends:result];
            return YES;
        }
    }
    else
    {
        return NO;
    }
}

-(int)createInvitedEmpousUserWithFacebookId:(int)facebookID andFirstName:(NSString*)firstName andLastName:(NSString*)lastName
{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] initWithCapacity:3];
    [params setObject:[NSString stringWithFormat:@"%d",facebookID] forKey:@"facebook_id"];
    [params setObject:firstName forKey:@"first_name"];
    [params setObject:lastName forKey:@"last_name"];
    NSMutableDictionary* result = [self sendPOSTRequest:@"api/invite/" withParams:params];
    [params release];
    if(result != nil)
    {
        return [[result objectForKey:@"empous_id"] intValue];
    }
    else
    {
        return -1;
    }
}

-(void)getFriends
{
    [self sendAsyncPOSTRequest:@"api/friends/" callback:@selector(handleFriends:)];
}

-(void)handleFriends:(NSMutableDictionary*)result
{
    [friends release];
    [friendMap release];
    
    friends = [[NSMutableArray alloc]init];
    friendMap = [[NSMutableDictionary alloc]init];
    
    NSDictionary* allFriends = [[(NSDictionary*)result objectForKey:@"success"]retain];
    for(NSDictionary* player in allFriends){
        [friends addObject:[allFriends objectForKey:player]];
    }
    [allFriends release];
    
    //Sort the Friends for the menu
    [self sortFriends];
    
    for(NSMutableDictionary* friend in friends){
        //Create a hashmap for all the friends for updating later
        [friendMap setValue:friend forKey:[friend objectForKey:@"empous_id"]];
    }
    
    if(delegate && [delegate respondsToSelector:@selector(friendsWithApp:)])
    {
        NSString* invitedFriend = [result objectForKey:@"invited_user"];
        [delegate performSelector:@selector(friendsWithApp:) withObject:invitedFriend];
    }
}

/* Sorts the friends list by putting 'installed' friends first then others
 Both groups are in alphabetical order.
 */
-(void)sortFriends{
    
    [friends sortUsingComparator:^(id a, id b) {
        NSDictionary *objA = (NSDictionary*)a;
        NSDictionary *objB = (NSDictionary*)b;

        NSString* aFirstName = (NSString*)[objA objectForKey:@"first_name"];
        NSString* bFirstName = (NSString*)[objB objectForKey:@"first_name"];
            
        //Compare the first names. If the same compare last.
        NSComparisonResult firstNameComparisonResult = [aFirstName caseInsensitiveCompare:bFirstName];
        if(firstNameComparisonResult == NSOrderedSame){
                
            NSString* aLastName = (NSString*)[objA objectForKey:@"last_name"];
            NSString* bLastName = (NSString*)[objB objectForKey:@"last_name"];
                
            return [aLastName caseInsensitiveCompare:bLastName];
                
        }else{
            return firstNameComparisonResult;
        }
    }];
}

-(int)createEmpousGame:(Player*)creatingPlayer withEnemies:(NSMutableArray*)enemyPlayers withGameState:(NSString*)jsonState withScreenShot:(NSString*)screenshotFilePath
{
    //Add the players to the array in the post params
    NSMutableDictionary* params = [[NSMutableDictionary alloc]initWithCapacity:4];
    NSMutableArray* players = [[NSMutableArray alloc] init];
    [players addObject:[NSString stringWithFormat:@"%d",[creatingPlayer empousId]]];
    for(id player in enemyPlayers)
    {
        [players addObject:[NSString stringWithFormat:@"%d",[player empousId]]];
    }
    
    [params setObject:players forKey:@"players"];
    [params setObject:jsonState forKey:@"json_state"];
    
    NSDictionary* result = [self sendPOSTRequest:@"api/create/" withParams:params withScreenShot:screenshotFilePath];
    [params release];
    [players release];
    if(result != nil)
    {
        return [[result objectForKey:@"game_id"] intValue];
    }
    else
    {
        return -1;
    }
}

-(BOOL)updateEmpousGame:(int)gameId currentPlayer:(int)currentEmpousId nextPlayer:(int)nextEmpousId withGameState:(NSString*)jsonState withScreenShot:(NSString*)screenshotFilePath;
{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] initWithCapacity:3];
    [params setObject:[NSString stringWithFormat:@"%d",gameId] forKey:@"game_id"];
    [params setObject:[NSString stringWithFormat:@"%d",currentEmpousId] forKey:@"player"];
    [params setObject:[NSString stringWithFormat:@"%d",nextEmpousId] forKey:@"next_player"];
    [params setObject:jsonState forKey:@"json_state"];
    
    NSDictionary* result = [self sendPOSTRequest:@"api/update/" withParams:params withScreenShot:screenshotFilePath];
    [params release];
    if(nil != result)
    {
        //Check for a success message in the response
        if(nil != [result objectForKey:@"success"])
        {
            return YES;
        }
        
        if(nil != [result objectForKey:@"error"])
        {
            [NSException raise:@"Error when updating game" format:@"The error returned was %@", [result objectForKey:@"error"]];
        }
    }
    return NO;
}
-(void)updateEmpousGameAsync:(NSDictionary*)gameParams
{
    int gameId = [[gameParams objectForKey:@"gameId"] intValue];
    int empousId = [[gameParams objectForKey:@"empousId"] intValue];
    NSString* jsonState = [gameParams objectForKey:@"jsonState"];
    NSString* screenshotFilePath = [gameParams objectForKey:@"screenshotFilePath"];
    
    NSMutableDictionary* params = [[NSMutableDictionary alloc] initWithCapacity:3];
    [params setObject:[NSString stringWithFormat:@"%d",gameId] forKey:@"game_id"];
    [params setObject:[NSString stringWithFormat:@"%d",empousId] forKey:@"player"];
    [params setObject:[NSString stringWithFormat:@"%@",jsonState] forKey:@"json_state"];
    
    [self sendPOSTRequest:@"api/update/" withParams:params withScreenShot:screenshotFilePath callback:nil useAsync:YES];
    [params release];
}

//Marks a game as finished with a winner
-(BOOL)empousGameFinished:(int)gameId winningPlayer:(int)empousId withGameState:(NSString*)jsonState withScreenShot:(NSString*)screenshotFilePath
{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] initWithCapacity:3];
    [params setObject:[NSString stringWithFormat:@"%d",gameId] forKey:@"game_id"];
    [params setObject:[NSString stringWithFormat:@"%d",empousId] forKey:@"winning_player"];
    [params setObject:[NSString stringWithFormat:@"%@",jsonState] forKey:@"json_state"];
    
    NSDictionary* result = [self sendPOSTRequest:@"api/complete/" withParams:params withScreenShot:screenshotFilePath];
    [params release];
    if(nil != result)
    {
        //Check for a success message in the response
        if(nil != [result objectForKey:@"success"])
        {
            return YES;
        }
    }
    
    return NO;
}

-(NSArray*)getGameList
{
    NSMutableArray* gamelist = [[NSMutableArray alloc]init];
    NSDictionary* result = [self sendPOSTRequest:@"api/gamelist/"];

    if(nil != result)
    {
        NSDictionary* games = [result objectForKey:@"gamelist"];
        for(id key in games)
        {
            [gamelist addObject:[games objectForKey:key]];
        }
    }
    
    //Sort so the games where the player has a move are first
    [gamelist sortUsingComparator:^(id a, id b) {
        NSDictionary *objA = (NSDictionary*)a;
        NSDictionary *objB = (NSDictionary*)b;
        
        BOOL aIsTurn = [[objA objectForKey:@"isTurn"] isEqualToString:@"yes"];
        BOOL bIsTurn = [[objB objectForKey:@"isTurn"] isEqualToString:@"yes"];
        
        if((aIsTurn && bIsTurn) || (!aIsTurn && !bIsTurn))
        {
            return (NSComparisonResult)NSOrderedSame;
        }
        
        if(aIsTurn && !bIsTurn)
        {
            return (NSComparisonResult)NSOrderedAscending;
        }
    
        return (NSComparisonResult)NSOrderedDescending;
    }];
    
    return gamelist;

}

-(NSArray*)getCompletedGames
{
    NSMutableArray* gamelist = [[[NSMutableArray alloc] init] autorelease];
    NSDictionary* result = [self sendPOSTRequest:@"api/completelist/"];
    
    if(nil != result)
    {
        NSDictionary* games = [result objectForKey:@"gamelist"];
        for(id key in games)
        {
            [gamelist addObject:[games objectForKey:key]];
        }
    }
    
    return gamelist;
}

-(void)numberPlayableGames
{
    [self sendAsyncPOSTRequest:@"api/numplayablegames/" callback:@selector(handleNumberPlayableGames:)];
}

-(void)handleNumberPlayableGames:(NSMutableDictionary*)result
{
    
    if(delegate != nil && [delegate respondsToSelector:@selector(numberOfGamesReceived:)])
    {
        [delegate performSelector:@selector(numberOfGamesReceived:) withObject:[result objectForKey:@"num_games"]];
    }
}

-(void)sendTokenForUser:(NSString*)usernameOrEmail
{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] initWithCapacity:1];
    [params setObject:usernameOrEmail forKey:@"username_or_email"];
    
    [self sendAsyncPOSTRequest:@"api/generatetoken/" withParams:params callback:@selector(handleTokenResponse:)];
    [params release];
}

-(void)handleTokenResponse:(NSMutableDictionary*)result
{
    NSString* response = [result objectForKey:@"response_message"];
    if (delegate != nil && [delegate respondsToSelector:@selector(tokenResponse:)])
    {
        [delegate performSelector:@selector(tokenResponse:) withObject:response];
    }
}

-(void)changeMatchmakingSettingForPlayer:(BOOL)matchmakingEnabled
{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] initWithCapacity:1];
    [params setObject:[NSNumber numberWithBool:matchmakingEnabled] forKey:@"matchmaking_enabled"];
    
    [self sendAsyncPOSTRequest:@"api/changematchmaking/" withParams:params callback:nil];
}

-(void)findRandomPlayer
{
    [self sendAsyncPOSTRequest:@"api/randomplayer/" callback:@selector(handleRandomPlayerResponse:)];
}

-(void)handleRandomPlayerResponse:(NSMutableDictionary*)result
{
    int status = [[result objectForKey:@"result"] intValue];
    
    /* Could not find a match */
    if (status != 11)
    {
        if (delegate != nil && [delegate respondsToSelector:@selector(foundRandomPlayer:)])
        {
            [delegate performSelector:@selector(foundRandomPlayer:) withObject:result];
        }
    }
    else
    {
        if (delegate != nil && [delegate respondsToSelector:@selector(noRandomPlayersAvailable)])
        {
            [delegate performSelector:@selector(noRandomPlayersAvailable)];
        }
    }
}

@end
