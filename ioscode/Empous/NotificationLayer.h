//
//  NotificationLayer.h
//  Empous
//
//  Created by Ryan Hurley on 3/15/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "CCLayer.h"
#import "cocos2d.h"

@interface NotificationLayer : CCLayerColor{
    CCSprite* notificationBox;
    CCLabelTTF* textCaption;
}

@property (retain) CCSprite* notificationBox;

-(id) initWithText:(NSString*)text andHeight:(int)height;



@end
