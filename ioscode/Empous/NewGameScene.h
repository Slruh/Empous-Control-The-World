//
//  NewGameScene.h
//  Empous
//
//  Created by Ryan Hurley on 1/16/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "cocos2d.h"
#import "CCButton.h"
#import "FacebookWrapper.h"
#import "ScrollMenu.h"
#import "CCLoadingOverlay.h"
#import "BottomBar.h"

@interface NewGameScene : CCLayer<ScrollMenuDelegate,BottomBarDelegate, EmpousWrapperDelegate, UITextFieldDelegate>
{
    
    NSMutableArray* friendLabels; //Shows the highlighted friends for the create game
    NSMutableArray* friendRemoveLabels; //Shows the x next to a friends name
    NSMutableArray* friendChoosers;
    NSMutableDictionary* friendsForFriendLabels; //The facebook data for the highlighted players
    NSMutableDictionary* menuNameToFriendData;
    ScrollMenu* menu;
    CCButton* facebookInviteButton;
    CCSprite* playButton;
    CCSprite* backButton;
    CCSprite* noFriendsText;
    CCButton* randomInviteButton;
    CCButton* disableMatchmaking;
    
    CCLoadingOverlay* spinner;
}

+(id)nodeWasPushed:(BOOL)wasPushed;

@end
