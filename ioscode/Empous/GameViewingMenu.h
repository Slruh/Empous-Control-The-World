//
//  GameViewingMenu.h
//  Empous
//
//  Created by Ryan Hurley on 6/22/13.
//  Copyright (c) 2013 HurleyProg. All rights reserved.
//

#import "CCScene.h"
#import "CCScrollLayer.h"

@interface GameViewingMenu : CCScene
{
    SEL _selector;
    id<NSObject> _target;
    CCScrollLayer* scrollGames;
    NSArray* gameList;
}

@property (nonatomic, assign) id<NSObject> target;
@property (nonatomic, assign) SEL selector;


+(id)nodeWithTitle:(NSString*)title target:(id)object selector:(SEL)function pushed:(BOOL)wasPushed showCompleted:(BOOL)onlyCompletedText;

-(void)reloadGames;
-(void)loadGames;

@end
