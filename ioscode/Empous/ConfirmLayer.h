//
//  ConfirmLayer.h
//  Empous
//
//  Created by Ryan Hurley on 8/26/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "CCLayer.h"
#import "cocos2d.h"
#import "CCButton.h"

typedef enum {
    EXTRA_REINFORCEMENTS
} ConfirmState;

@protocol ConfirmLayerDelegate<NSObject>
-(void)confirmResponse:(BOOL)buttonPressed withState:(ConfirmState)currentState;
@end

@interface ConfirmLayer : CCLayer
{
    CCButton* confirmBox;
    id <ConfirmLayerDelegate> delegate;
}

+(id)nodeWithBonusRefinforcements:(int)numberOfReinforcements andDelegate:(id)newDelegate;

@end
