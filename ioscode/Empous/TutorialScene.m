//
//  TutorialScene.m
//  Empous
//
//  Created by Ryan Hurley on 4/14/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "TutorialScene.h"
#import "BottomBar.h"
#import "CCScrollLayer.h"

@implementation TutorialScene


- (id)init
{
    self = [super init];
    if (self) {
        //Get screensize
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp(winSize.width/2,winSize.height/2);
        
        //Add the Sprite for the background
        CCSprite* background = [CCSprite spriteWithFile: @"Empous-Background.png"];
        background.position = ccp(center.x, 160);
        [self addChild:background];
        
        //Add the top and bottom bars
        CCSprite* topBar = [CCSprite spriteWithFile:@"Top-Green.png"];
        [topBar setPosition:ccp(center.x,312)];
        [self addChild:topBar];
        
        //Title Label
        CCLabelTTF* createNewGameLabel = [CCLabelTTF labelWithString:@"How To Play Empous" fontName:@"Armalite Rifle" fontSize:16];
        [createNewGameLabel setPosition:ccp(center.x,312)];
        [self addChild:createNewGameLabel];
        
        //Add the bottom bar with play button
        BottomBar* bottomBar = [BottomBar nodeWithPlayButton:NO andDelegate:self withPush:YES];
        [self addChild:bottomBar];
        
        
        [self createTutorialSprites];
    }
    
    return self;
}

-(void)createTutorialSprites
{
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);

    CCLayer* introLayer = [CCLayer node];
    CCLayer* reinforceLayer = [CCLayer node];
    CCLayer* attackOneLayer = [CCLayer node];
    CCLayer* attackTwoLayer = [CCLayer node];
    CCLayer* fortifyLayer = [CCLayer node];
    
    CCSprite* introSprite = [CCSprite spriteWithFile:@"Intro.png"];
    [introSprite setPosition:ccp(center.x, 168)];
    [introLayer addChild:introSprite];
    
    CCSprite* reinforceSprite = [CCSprite spriteWithFile:@"Reinforce.png"];
    [reinforceSprite setPosition:ccp(center.x, 168)];
    [reinforceLayer addChild:reinforceSprite];
    
    CCSprite* attackOneSprite = [CCSprite spriteWithFile:@"Attack1.png"];
    [attackOneSprite setPosition:ccp(center.x, 168)];
    [attackOneLayer addChild:attackOneSprite];
    
    CCSprite* attackTwoSprite = [CCSprite spriteWithFile:@"Attack2.png"];
    [attackTwoSprite setPosition:ccp(center.x, 168)];
    [attackTwoLayer addChild:attackTwoSprite];
    
    CCSprite* fortifySprite = [CCSprite spriteWithFile:@"Fortify.png"];
    [fortifySprite setPosition:ccp(center.x, 168)];
    [fortifyLayer addChild:fortifySprite];
    
    CCScrollLayer* scrollGames = [CCScrollLayer nodeWithLayers:[NSArray arrayWithObjects:introLayer,reinforceLayer,attackOneLayer,attackTwoLayer,fortifyLayer, nil] widthOffset:0];
    scrollGames.stealTouches = NO;
    scrollGames.pagesIndicatorPosition = ccp(winSize.width * 0.5f, 12);
    [self addChild:scrollGames];

}

@end
