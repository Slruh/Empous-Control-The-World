//
//  MainMenuScene.m
//  Empous
//
//  Created by Ryan Hurley on 1/15/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "MainMenuScene.h"
#import "NewGameScene.h"
#import <Foundation/Foundation.h>
#import "SimpleAudioEngine.h"
#import "GameScene.h"
#import "CurrentGamesScene.h"
#import "CompletedGamesScene.h"
#import "TutorialScene.h"
#import "TestFlight.h"
#import "CCButton.h"
#import "MainMenuScene+EmpousAuth.h"
#import "MainMenuScene+FacebookAuth.h"
#import "AboutScene.h"
#import "Tools.h"

static MessageOption messageOption = NO_MESSAGE;

@implementation MainMenuScene
{
    CCButton* reconnectButton;
}

- (void)onEnterTransitionDidFinish
{
    //Check to see if the menu is visible...if it is
    if(mainMenu != nil && [mainMenu opacity] > 0.0)
    {
        [[EmpousAPIWrapper sharedEmpousAPIWrapper] setDelegate:self];
        [[EmpousAPIWrapper sharedEmpousAPIWrapper] performSelectorInBackground:@selector(numberPlayableGames) withObject:nil];
    }
    
    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
    
    if (messageOption == NO_MESSAGE)
    {
        [self schedule:@selector(authorize)];
    }
    
    [self setVolumeIcon];
    
    [super onEnterTransitionDidFinish];

}

-(void)setVolumeIcon
{
    //Set the volume icon
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isSilenced = [defaults boolForKey:@"isSilenced"];
    
    if ([[self children] containsObject:questionMark])
    {
        [self removeChild:questionMark];
    }
    
    if (isSilenced)
    {
        [[SimpleAudioEngine sharedEngine] setEnabled:NO];
    }
    else
    {
        [[SimpleAudioEngine sharedEngine] setEnabled:YES];
        if (![[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying])
        {
            [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"empous_theme.mp3"];
        }
    }
    
    questionMark = [CCButton spriteWithFile:@"Volume.png" withPressedFile:@"Volume-Pressed.png" target:self function:@selector(toggleVolume)];
    [questionMark setPosition:ccp(20, 17)];
    [self addChild:questionMark z:2];
}

+(id)nodeWithMessage:(MessageOption)message
{
    return [[[self alloc]initWithMessage:message] autorelease];
}

+(id)node
{
    return [[[self alloc]initWithMessage:NO_MESSAGE] autorelease];
}

- (id)initWithMessage:(MessageOption)message
{
    self = [super init];
    if (self)
    {
        messageOption = message;
        
        //Get screensize
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp(winSize.width/2,winSize.height/2);

        //Add the Sprite for the background
        CCSprite* background = [CCSprite spriteWithFile: @"Empous-Background.png"];
        compass = [CCSprite spriteWithFile:@"Compass.png"];
        CCSprite* logo = [CCSprite spriteWithFile:@"Empous-Logo.png"];
        
        //Set to 0,0
        background.position = center;
        compass.position = ccp(center.x-(.90 * ([logo boundingBox].size.width/2)),3*winSize.height/4);
        logo.position = ccp(center.x,3*winSize.height/4);
        
        //Add the background to the scene
        [self addChild:background];
        [self addChild:compass];
        [self addChild:logo];
        
        //Menu Stuff
        // Create some menu items
        CCMenuItemImage * menuItem1 = [CCMenuItemImage itemWithNormalImage:@"New-Game.png"
                                                             selectedImage: @"New-Game-Pressed.png"
                                                                    target:self
                                                                  selector:@selector(handleNewGame)];

        CCMenuItemImage * menuItem2 = [CCMenuItemImage itemWithNormalImage:@"Current-Games.png"
                                                             selectedImage: @"Current-Games-Pressed.png"
                                                                    target:self
                                                                  selector:@selector(loadGame)];
        CCMenuItemImage * menuItem3 = [CCMenuItemImage itemWithNormalImage:@"Completed-Games.png"
                                                             selectedImage: @"Completed-Games-Pressed.png"
                                                                    target:self
                                                                  selector:@selector(loadFinishedGame)];
        CCMenuItemImage* menuItem4 = [CCMenuItemImage itemWithNormalImage:@"How-To-Play.png"
                                                            selectedImage:@"How-To-Play-Pressed.png"
                                                            target:self selector:@selector(loadTutorial)];
        
        CCMenuItemImage* menuItem5 = [CCMenuItemImage itemWithNormalImage:@"Logout.png"
                                                            selectedImage:@"Logout-Pressed.png"
                                                            target:self selector:@selector(logout)];
        
        
        // Create a menu and add your menu items to it
        mainMenu = [CCMenu menuWithItems:menuItem1,menuItem2,menuItem3,menuItem4,menuItem5, nil];
        mainMenu.position = ccp(center.x,.32*winSize.height);
        
        CCButton* aboutMenu = [CCButton spriteWithFile:@"About.png" withPressedFile:@"About-Pressed.png" target:self function:@selector(showAboutMenu) sound:@"button.mp3"];
        [aboutMenu setPosition:ccp(.97 * winSize.width, .05 * winSize.height)];
        [self addChild:aboutMenu z:2];

        // Arrange the menu items vertically
        [mainMenu alignItemsVerticallyWithPadding:2.0];
        
        // add the menu to your scene
        [self addChild:mainMenu z:2];
        [mainMenu setTouchEnabled:NO];
        [mainMenu setOpacity:0];
        
        playableGameBackground = nil;
        playableGames = nil;
        
        //Compass spin
        [compass runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:.7 angle:(((int)[compass rotation]) + 8)%360]]];
        
        switch (message) {
            case NO_MESSAGE:
                break;
            case CONNECTION_ERROR:
                [self showNoConnection];
                break;
            case OUTDATED_APP:
                [self showOutdatedNotice];
                break;
        }
    }
    return self;
}

-(void)onExitTransitionDidStart
{
    if([[self children] containsObject:overlay])
    {
        [self removeChild:overlay cleanup:YES];
    }
    [self cleanUpEmpousAuthElements];
    [self cleanUpFacebookAuthElements];
    [super onExitTransitionDidStart];
}

-(void)authorize
{
    //Prevent the game from authorizing multiple times
    [self unschedule:@selector(authorize)];
    [self unschedule:@selector(hideNotification)];
    
    //Solves a race condition when returning from background
    [self removeChild:notification cleanup:YES];
    
    //Hide the menu if necessary
    [mainMenu setOpacity:0.0];
    [mainMenu setTouchEnabled:NO];
    
    [self removeEmpousCreateAccount];
    [self removeEmpousResetPassword];
    [self cleanUpEmpousAuthElements];
    [self cleanUpFacebookAuthElements];

    [self removeChild:playableGameBackground cleanup:YES];
    [self removeChild:playableGames cleanup:YES];
    
    //Remove the bad connection text if it exists
    if([[self children] containsObject:noConnection])
    {
        [self removeChild:noConnection cleanup:YES];
        [self removeChild:noConnectionHelpText cleanup:YES];
        if([[self children]containsObject:reconnectButton])
        {
            [self removeChild:reconnectButton cleanup:YES];
        }
    }
    
    //Check to see if there is a connection
    if([[EmpousAPIWrapper sharedEmpousAPIWrapper] empousConnectionAvailable])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString* loginPreference = [defaults stringForKey:@"login"];
        if(loginPreference == nil)
        {
            [self showLoginOptions];
        }
        else
        {
            if([loginPreference isEqualToString:@"facebook"])
            {
                [self facebookAuthorize];
            }
            else
            {
                [self empousAuthorize];
            }
        }
    }
    else
    {
        [self showNoConnection];
    }
}

-(void)showLoginOptions
{
    if(loginOptions == nil)
    {
        //Get screensize
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp(winSize.width/2,winSize.height/2);
        
        loginOptions = [CCFadableLayer node];
        CCLabelTTF* label = [CCLabelTTF labelWithString:@"Choose how you would like to login" fontName:@"Armalite Rifle" fontSize:winSize.height * .0625];
        [label setPosition:ccp(center.x,.44*winSize.height)];
        [label setColor:ccBLACK];
        [loginOptions addChild:label];
        
        //fbAuthorize is in the FacebookAuth category for the MainMenuScene
        CCButton* facebookLoginButton = [CCButton spriteWithFile:@"FacebookLogin.png" withPressedFile:@"FacebookLogin-Pressed.png" target:self function:@selector(facebookAuthorize) sound:@"button.mp3"];
        [facebookLoginButton setPosition:ccp(center.x, .30 * winSize.height)];
        [loginOptions addChild:facebookLoginButton];
        
        
        CCButton* empousLoginButton = [CCButton spriteWithFile:@"EmpousLogin.png" withPressedFile:@"EmpousLogin-Pressed.png" target:self function:@selector(empousAuthorize) sound:@"button.mp3"];
        [empousLoginButton setPosition:ccp(center.x, .15 * winSize.height)];
        [loginOptions addChild:empousLoginButton];
        
        [self addChild:loginOptions];
    }
}

-(void)backToLoginOptions
{
    [self removeChild:modalOverlay cleanup:YES];
    [self cleanUpEmpousAuthElements];
    [self cleanUpFacebookAuthElements];
    [self showLoginOptions];
}

-(void)loginSuccess
{
    [self cleanUpEmpousAuthElements];
    [self cleanUpFacebookAuthElements];
    
    if([[self children] containsObject:modalOverlay])
    {
        [self removeChild:modalOverlay cleanup:YES];
    }
    
    //Remove all login views
    if(loginOptions != nil)
    {
        [self removeChild:loginOptions cleanup:YES];
        loginOptions = nil;
    }
    
    if([[self children] containsObject:overlay])
    {
        [self removeChild:overlay cleanup:YES];
    }
    
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* username = [defaults objectForKey:@"username"];

    //Activate the logged in as
    int fontSize = .05 * winSize.height;
    
    loggedInAs = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Logged In As %@", username] fontName:@"Armalite Rifle" fontSize:fontSize];
    [loggedInAs setColor:ccBLACK];
    [loggedInAs setPosition:ccp(center.x,.03 * winSize.height)];
    [self addChild:loggedInAs];
    
    //Show the notification layer
    [self removeChild:notification cleanup:YES];
    notification = [[NotificationLayer alloc]initWithText:[NSString stringWithFormat:@"Welcome %@", username] andHeight:15];
    [self addChild:notification z:3];
    [self schedule:@selector(hideNotification) interval:1.0];
}

/**
 Shown when there is no connection to Empous available
 */
-(void)showNoConnection
{
    [self removeChild:notification cleanup:YES];
    [self showMainErrorText:@"Connection to Empous Lost" subText:@"Check your connection to the internet" showReconnectMenu:YES];
}

-(void)showOutdatedNotice
{
    [self removeChild:notification cleanup:YES];
    [self showMainErrorText:@"Empous is Outdated" subText:@"You must update Empous before playing" showReconnectMenu:NO];
}

/**
 Helper method for showing connection issues
 */
-(void)showMainErrorText:(NSString*)errorText subText:(NSString*)subErrorText showReconnectMenu:(BOOL)showReconnect
{
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    noConnection = [CCLabelTTF labelWithString:errorText fontName:@"Armalite Rifle" fontSize:25];
    noConnection.position = ccp(center.x,130);
    noConnection.color = ccBLACK;
    [self addChild:noConnection];
    
    noConnectionHelpText = [CCLabelTTF labelWithString:subErrorText fontName:@"Armalite Rifle" fontSize:20];
    noConnectionHelpText.position = ccp(center.x, 100);
    noConnectionHelpText.color = ccBLACK;
    [self addChild:noConnectionHelpText];
    
    //Reconnect button
    reconnectButton = [CCButton spriteWithFile:@"Reconnect.png" withPressedFile:@"Reconnect-Pressed.png" target:self function:@selector(authorize)];
    reconnectButton.position = ccp(center.x,65);
    
    // add the menu to your scene
    if (showReconnect)
    {
        [self addChild:reconnectButton];
    }
}

-(void)hideNotification
{
    [self unschedule:@selector(hideNotification)];
    id removeNotification = [CCCallFunc actionWithTarget:self selector:@selector(removeNotificationScheduler)];
    if([[self children] containsObject:notification])
    {
        [notification runAction:[CCSequence actions:removeNotification, nil]];
    }
}

//Needed to prevent background recovery issues
-(void)removeNotificationScheduler
{
    [self schedule:@selector(removeNotification)];
}

-(void)removeNotification
{
    [self unschedule:@selector(removeNotification)];
    [self removeChild:notification cleanup:YES];
    [mainMenu setTouchEnabled:YES];
    id fadeIn = [CCFadeIn actionWithDuration:0.5];
    [mainMenu runAction:[CCSequence actions:fadeIn,nil]];
    [self getPlayableGames];
}

-(void) getPlayableGames
{
    [[EmpousAPIWrapper sharedEmpousAPIWrapper]setDelegate:self];
    [[EmpousAPIWrapper sharedEmpousAPIWrapper] performSelectorInBackground:@selector(numberPlayableGames) withObject:nil];
}

- (void)handleNewGame
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"button.mp3"];
    
    if ([Tools isEmpousLite])
    {
        overlay = [CCLoadingOverlay nodeWithMessage:@"Checking number of active games" withFont:@"Armalite Rifle"];
        [self addChild:overlay z:LOADING_LEVEL];
    }

    [self schedule:@selector(createNewGameIfAllowed)];
}

-(void)createNewGameIfAllowed
{
    [self unschedule:@selector(createNewGameIfAllowed)];
    
    //Check to see if the player can add a game
    if([Tools isEmpousLite] && ![[EmpousAPIWrapper sharedEmpousAPIWrapper] checkIfPlayerCanCreateAGame])
    {
        if (overlay != nil)
        {
            [self removeChild:overlay];
        }
        UIAlertView* dialog = [[UIAlertView alloc] init];
        [dialog setDelegate:self];
        [dialog setTitle:@"Can Not a New Game"];
        [dialog setMessage:@"You already have 3 active games which is the maximum for Empous Lite. Get the full version of Empous to play more games."];
        [dialog addButtonWithTitle:@"OK"];
        [dialog show];
        [dialog release];
    }
    else
    {
        if (overlay != nil)
        {
            [self removeChild:overlay];
        }
        [[CCDirector sharedDirector] pushScene:
         [CCTransitionFade transitionWithDuration:0.5f scene:[NewGameScene nodeWasPushed:NO]]];
    }
}

-(void)loadTutorial
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"button.mp3"];
    [[CCDirector sharedDirector] pushScene:[CCTransitionFade transitionWithDuration:0.5f scene:[TutorialScene node]]];
}

/*
 * Called when current games option is pressed
 */
-(void)loadGame
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"button.mp3"];
    [[CCDirector sharedDirector] replaceScene:
	 [CCTransitionFade transitionWithDuration:1.0f scene:[CurrentGamesScene nodeWasPushed:NO]]];
}

-(void)loadFinishedGame
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"button.mp3"];
    [[CCDirector sharedDirector] replaceScene:
	 [CCTransitionFade transitionWithDuration:1.0f scene:[CompletedGamesScene nodeWasPushed:NO]]];
}

-(void)logout
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"button.mp3"];
    //Clear logged in as
    [self removeChild:loggedInAs cleanup:YES];
    
    //hide main menu and disable it
    [mainMenu setTouchEnabled:NO];
    [mainMenu setOpacity:0];
    
    //Clear the login preference
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"login"];
    [defaults removeObjectForKey:@"token"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //Show log in options
    [self authorize];
}

-(void)showAboutMenu
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:1.0 scene:[AboutScene node]]];
}

-(void)toggleVolume
{
    //Remove the question mark then replace as necessary
    [self removeChild:questionMark];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isSilenced = [defaults boolForKey:@"isSilenced"];
    if (isSilenced)
    {
        [defaults setBool:NO forKey:@"isSilenced"];
        [[SimpleAudioEngine sharedEngine] setEnabled:YES];
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"empous_theme.mp3"];
        questionMark = [CCButton spriteWithFile:@"Volume.png" withPressedFile:@"Volume-Pressed.png" target:self function:@selector(toggleVolume)];
        [questionMark setPosition:ccp(20, 17)];
        [self addChild:questionMark z:2];
    }
    else
    {
        [defaults setBool:YES forKey:@"isSilenced"];
        [[SimpleAudioEngine sharedEngine] setEnabled:NO];
        questionMark = [CCButton spriteWithFile:@"Volume-No.png" withPressedFile:@"Volume-No-Pressed.png" target:self function:@selector(toggleVolume)];
        [questionMark setPosition:ccp(20, 17)];
        [self addChild:questionMark z:2];
    }
}

-(void)numberOfGamesReceived:(NSDecimalNumber*)numGames
{
    if([[self children] containsObject:playableGames])
    {
        [self removeChild:playableGameBackground cleanup:YES];
        [self removeChild:playableGames cleanup:YES];
    }
    
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    int offset = 110;
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        offset = 265;
    }
    
    int fontSize = winSize.height * .0625;
    
    playableGameBackground = [CCSprite spriteWithFile:@"Unit-Background.png"];
    [playableGameBackground setPosition:ccp(center.x + offset, .44 * winSize.height)];
    [self addChild:playableGameBackground z:1];
    
    playableGames = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@",numGames] fontName:@"Armalite Rifle" fontSize:fontSize];
    [playableGames setColor:ccWHITE];
    [playableGames setPosition:ccp(center.x + offset, .44 * winSize.height)];
    [self addChild:playableGames z:1];
    
    [playableGameBackground setOpacity:0];
    [playableGames setOpacity:0];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[numGames integerValue]];
    
    [self schedule:@selector(showGamesWhenMenuVisible)];
}

-(void)showGamesWhenMenuVisible
{
    [self unschedule:@selector(showGamesWhenMenuVisible)];
    if([mainMenu opacity] != 0)
    {
        id fadeIn = [CCFadeIn actionWithDuration:0.5];
        [playableGameBackground runAction:[CCSequence actions:[[fadeIn copy] autorelease],nil]];
        [playableGames runAction:[CCSequence actions:[[fadeIn copy] autorelease],nil]];
    }
}

@end
