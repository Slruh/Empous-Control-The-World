//
//  GameMenu.h
//  Empous
//
//  Created by Ryan Hurley on 4/8/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "CCLayer.h"

@protocol MenuDelegate
-(void)hideMenu;
@end

@interface GameMenu : CCLayer
{
    id <MenuDelegate> menuDelegate;
}

+(id)nodeWithDelegate:(id)delegate;

@end
