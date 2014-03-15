//
//  BottomBar.m
//  Empous
//
//  Created by Ryan Hurley on 4/10/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "BottomBar.h"
#import "cocos2d.h"
#import "CCButton.h"
#import "MainMenuScene.h"
#import "CCTransition.h"
#import "CCDirector+PopTransition.h"

@implementation BottomBar
{
    CCSprite* backButton;
    CCSprite* playButton;
    
    id<BottomBarDelegate> barDelegate;
    BOOL wasPushed;
}


+(id)nodeWithPlayButton:(BOOL)showPlayButton andDelegate:(id)delegate
{
    return [[[self alloc] initWithPlayButton:showPlayButton andDelegate:delegate withPush:NO]autorelease];
}

+(id)nodeWithPlayButton:(BOOL)showPlayButton andDelegate:(id)delegate withPush:(BOOL)pushed
{
    return [[[self alloc] initWithPlayButton:showPlayButton andDelegate:delegate withPush:pushed]autorelease];
}


-(id)initWithPlayButton:(BOOL)showPlayButton andDelegate:(id)delegate withPush:(BOOL)pushed
{
    self = [super init];
    if(self)
    {
        //Get screensize
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp(winSize.width/2,winSize.height/2);
        
        CCSprite* bottomBar = [CCSprite spriteWithFile:@"Bottom-Green.png"];
        [bottomBar setPosition:ccp(center.x,16)];
        [self addChild:bottomBar];
        
        //Buttons (back and play)
        backButton = [CCButton spriteWithFile:@"Back.png" withPressedFile:@"Back-Pressed.png" touchAreaScale:2.0 target:self function:@selector(handleReturnToMain) sound:@"button.mp3"];
        [backButton setPosition:ccp(38,15)];
        [self addChild:backButton];
        
        [delegate retain];
        barDelegate = delegate;
        
        if(showPlayButton)
        {
            playButton = [CCButton spriteWithFile:@"Play.png" withPressedFile:@"Play-Pressed.png" touchAreaScale:2.0 target:self function:@selector(playButtonTouched) sound:@"button.mp3"];
            [playButton setPosition:ccp(winSize.width - 38,15)];
            [self addChild:playButton];
        }
        
        wasPushed = pushed;

    }
    return self;
}

-(void)dealloc
{
    [barDelegate release];
    [super dealloc];
}

- (void) handleReturnToMain
{
    if(wasPushed)
    {
        [[CCDirector sharedDirector] popScene];
    }
    else
    {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:1.0 scene:[MainMenuScene node]]];
    }
}

-(void)playButtonTouched
{
    if ([barDelegate respondsToSelector:@selector(playButtonTouched)])
    {
        [barDelegate playButtonTouched];
    }
}


@end
