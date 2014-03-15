//
//  NotificationLayer.m
//  Empous
//
//  Created by Ryan Hurley on 3/15/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "NotificationLayer.h"

@implementation NotificationLayer
@synthesize notificationBox;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(id) initWithText:(NSString*)text andHeight:(int)height{
    self = [self init];
    if(self){
        //Get screensize
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp(winSize.width/2,winSize.height/2);
        
        int fontSize = winSize.height * .063;
        
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            height = (height/320.0) * winSize.height;
            
        }
        
        notificationBox = [CCSprite spriteWithFile:@"Notification.png"];
        [notificationBox setPosition:ccp(center.x,height)];
        [self addChild:notificationBox];
        
        textCaption = [CCLabelTTF labelWithString:text fontName:@"Armalite Rifle" fontSize:fontSize];
        [textCaption setPosition:ccp(center.x,height)];
        [self addChild:textCaption];
        
        [notificationBox setScaleX:(winSize.width * CC_CONTENT_SCALE_FACTOR())];
        [notificationBox setScaleY:([textCaption boundingBox].size.height + (.33 *[textCaption boundingBox].size.height)) * CC_CONTENT_SCALE_FACTOR()];
    }
    return self;
}


@end
