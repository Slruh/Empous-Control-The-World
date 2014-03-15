//
//  GameMenu.m
//  Empous
//
//  Created by Ryan Hurley on 4/8/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "GameMenu.h"
#import "cocos2d.h"
#import "CCButton.h"
#import "MainMenuScene.h"
#import "ControlLayer.h"
#import "TutorialScene.h"
#import "CompletedGamesScene.h"
#import "CurrentGamesScene.h"
#import "SimpleAudioEngine.h"

@implementation GameMenu
{
    CCButton* menuBackground;
    CCButton* returnButton;
    CCButton* overlay;
    
    CCMenu* mainMenu;
}

+(id)nodeWithDelegate:(id)delegate
{
    return [[[self alloc]initWithDelegate:delegate]autorelease];
}

-(id)initWithDelegate:(id)delegate
{
    self = [super init];
    if(self)
    {
        [self setDelegate:delegate];
        
        //Get screensize
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp(winSize.width/2,winSize.height/2);
        
        //Create overlay
        overlay = [CCButton spriteWithFile:@"Notification.png" withPressedFile:@"Notification.png" target:delegate function:@selector(hideMenu)];
        overlay.scaleX = CC_CONTENT_SCALE_FACTOR() * winSize.width;
        overlay.scaleY = CC_CONTENT_SCALE_FACTOR() * winSize.height;
        overlay.position = center;
        [self addChild:overlay];
        
        menuBackground = [CCButton spriteWithFile:@"Confirm-Box.png"];
        [menuBackground setScale:.7];
        [menuBackground setPosition:ccp(center.x, 170)];
        [self addChild:menuBackground];
        
        //Menu Stuff
        // Create some menu items
        
        CCMenuItemFont *menuItem1 = [CCMenuItemImage itemWithNormalImage:@"TitleScreen.png"
                                                           selectedImage: @"TitleScreen-Pressed.png"
                                                                  target:self
                                                                selector:@selector(returnToTitleScreen)];
        CCMenuItemImage * menuItem2 = [CCMenuItemImage itemWithNormalImage:@"Current-Games.png"
                                                             selectedImage: @"Current-Games-Pressed.png"
                                                                    target:self
                                                                  selector:@selector(returnToCurrentGames)];
        CCMenuItemImage * menuItem3 = [CCMenuItemImage itemWithNormalImage:@"Completed-Games.png"
                                                             selectedImage: @"Completed-Games-Pressed.png"
                                                                    target:self
                                                                  selector:@selector(returnToCompletedGames)];
        CCMenuItemImage* menuItem4 = [CCMenuItemImage itemWithNormalImage:@"How-To-Play.png"
                                                            selectedImage:@"How-To-Play-Pressed.png"
                                                                   target:self selector:@selector(loadTutorial)];
        
        // Create a menu and add your menu items to it
        mainMenu = [CCMenu menuWithItems:menuItem1,menuItem2,menuItem3,menuItem4, nil];
        mainMenu.position = ccp(center.x,170);
        // Arrange the menu items vertically
        [mainMenu alignItemsVertically];
        
        // add the menu to your scene
        [self addChild:mainMenu];
    
        returnButton = [CCButton spriteWithFile:@"CloseX.png" withPressedFile:@"CloseX-Pressed.png" touchAreaScale:1.0 priority:INT_MIN + 2 target:self function:@selector(dismissMenu) sound:@"button.mp3"];
                        [returnButton setPosition:ccp(center.x + 127,244)];
        [self addChild:returnButton];
        [self setTouchEnabled:YES];
    }
    return self;
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

-(void)setDelegate:(id)delegate
{
    if(![[delegate class] conformsToProtocol:@protocol(MenuDelegate)]){
        [NSException raise:@"Delegate Exception" format:@"Delegate of class %@ is invalid", [delegate class]];
    }else{
        menuDelegate = delegate;
    }
}

-(void)returnToTitleScreen
{
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:1.0f];
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"button.mp3"];
    [[CCDirector sharedDirector] replaceScene:
     [CCTransitionFade transitionWithDuration:0.5f scene:[MainMenuScene node]]];
}

-(void)returnToCurrentGames
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"button.mp3"];
    [[CCDirector sharedDirector] pushScene:
	 [CCTransitionFade transitionWithDuration:0.5f scene:[CurrentGamesScene nodeWasPushed:YES]]];
}

-(void)returnToCompletedGames
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"button.mp3"];
    [[CCDirector sharedDirector] pushScene:
	 [CCTransitionFade transitionWithDuration:0.5f scene:[CompletedGamesScene nodeWasPushed:YES]]];
}

-(void)loadTutorial
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"button.mp3"];
    [[CCDirector sharedDirector] pushScene:[CCTransitionFade transitionWithDuration:0.5f scene:[TutorialScene node]]];
}

-(void)dismissMenu
{
    [menuDelegate hideMenu];
}


@end
