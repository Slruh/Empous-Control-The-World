//
//  NumberPicker.h
//  Empous
//
//  Created by Ryan Hurley on 3/20/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "CCLayer.h"
#import "cocos2d.h"
#import "CCButton.h"

@class GameScene;

@interface NumberPicker : CCLayer{
    CCSprite* background;
    CCButton* addButton;
    CCButton* minusButton;
    NSMutableArray* itemsForPicker;
    NSRange acceptableValues;
    int currentValue;
    GameScene* gameScene;
}

@property (readonly) CCSprite* addButton;
@property (readonly) CCSprite* minusButton;
@property int currentValue;

-(id)initWithNSRange:(NSRange)range startValue:(int)start position:(CGPoint)position scene:(GameScene*)scene;
-(void)updatePickerValues:(NSRange)values startValue:(int)startValue;

@end
