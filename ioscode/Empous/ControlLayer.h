//
//  StatsLayer.h
//  Empous
//
//  Created by Ryan Hurley on 3/18/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "CCLayer.h"
#import "cocos2d.h"
#import "CCButton.h"

@class GameScene;

@protocol ControlLayerDelegate
@optional
-(void)attack;
-(void)cancelAttack;
-(void)moveUnits;
-(void)nextPhase;
-(void)showMenu;
@end

@interface ControlLayer : CCLayer{
    CCLabelTTF* textMessage;
    CCButton* nextButton;
    CCButton* menuButton;
    CCButton* attackButton;
    CCButton* cancelButton;
    CCButton* checkButton;
    
    CCLabelTTF* returnToHome;
    
    NSMutableDictionary* playerLabels;
    
    GameScene* gameScene;
    id <ControlLayerDelegate> controlDelegate;
}

@property (readonly) CCSprite* attackButton;
@property (readonly) CCSprite* cancelButton;
@property (assign) GameScene* gameScene;

-(id)initWithGameScene:(GameScene*)scene;
-(void)setDelegate:(id)delegate;
-(void)setMessage:(NSString*)message;
-(void)updatePlayerLabels;
-(void)disableNextButton;
-(void)showAttackButtons;
-(void)hideAttackButtons;
-(void)showCheckButton;
-(void)hideCheckButton;

@end
