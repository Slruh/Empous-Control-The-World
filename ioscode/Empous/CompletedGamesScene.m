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
#import "CompletedGamesScene.h"
#import "Tools.h"
#import "BottomBar.h"
#import "SimpleAudioEngine.h"

CCSprite* background;

@implementation CompletedGamesScene

+(id)nodeWasPushed:(BOOL)wasPushed
{
    return [super nodeWithTitle:@"Last 5 Completed Games" target:[EmpousAPIWrapper sharedEmpousAPIWrapper] selector:@selector(getCompletedGames) pushed:wasPushed showCompleted:YES];
}

@end
