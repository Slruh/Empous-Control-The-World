//
//  BottomBar.h
//  Empous
//
//  Created by Ryan Hurley on 4/10/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "CCLayer.h"

@protocol BottomBarDelegate <NSObject>
@optional
-(void)playButtonTouched;

@end

@interface BottomBar : CCLayer

+(id)nodeWithPlayButton:(BOOL)showPlayButton andDelegate:(id)delegate;
+(id)nodeWithPlayButton:(BOOL)showPlayButton andDelegate:(id)delegate withPush:(BOOL)pushed;

@end
