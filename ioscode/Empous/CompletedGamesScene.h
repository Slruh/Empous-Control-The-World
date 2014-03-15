//
//  CurrentGamesScene.h
//  Empous
//
//  Created by Ryan Personal on 3/4/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "CCScene.h"
#import "cocos2d.h"
#import "GameViewingMenu.h"

@interface CompletedGamesScene : GameViewingMenu

+(id)nodeWasPushed:(BOOL)wasPushed;

@end
