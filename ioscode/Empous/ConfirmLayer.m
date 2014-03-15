//
//  ConfirmLayer.m
//  Empous
//
//  Created by Ryan Hurley on 8/26/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "ConfirmLayer.h"

@implementation ConfirmLayer

BOOL noPressed = false;
BOOL yesPressed = false;
ConfirmState currentState;

CCSprite* yesButton;
CCSprite* noButton;

-(id)init
{
    self = [super init];
    if (self) {
        confirmBox = [CCButton spriteWithFile:@"Confirm-Box.png"];
        confirmBox.position = ccp(240, 170);
        [self addChild:confirmBox];
    }
    
    [self setTouchEnabled:YES];
    return self;
}

-(void)setDelegate:(id)newDelegate
{
    //Set the delegate
    if(![[newDelegate class] conformsToProtocol:@protocol(ConfirmLayerDelegate)]){
        [NSException raise:@"Delegate Exception" format:@"Delegate of class %@ is invalid", [newDelegate class]];
    }else{
        if(delegate){
            [delegate release];
        }
        [newDelegate retain];
        delegate = newDelegate;
    }
}

+(id)nodeWithBonusRefinforcements:(int)numberOfReinforcements andDelegate:(id)newDelegate
{
    currentState = EXTRA_REINFORCEMENTS;
    return [[[self alloc]initWithBonusRefinforcements:numberOfReinforcements withDelegate:newDelegate]autorelease];
}

-(id)initWithBonusRefinforcements:(int)numberOfReinforcements withDelegate:(id)newDelegate
{
    self = [self init];
    if(self)
    {
        [self setDelegate:newDelegate];
        
        CCLabelTTF* confirmTitle1 = [CCLabelTTF labelWithString:@"You can claim extra" fontName:@"Armalite Rifle" fontSize:20];
        [confirmTitle1 setPosition:ccp(240,255)];
        [self addChild:confirmTitle1];
        
        CCLabelTTF* confirmTitle2 = [CCLabelTTF labelWithString:@"Reinforcements" fontName:@"Armalite Rifle" fontSize:20];
        [confirmTitle2 setPosition:ccp(240,238)];
        [self addChild:confirmTitle2];
        
        CCLabelTTF* numberOfUnits = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",numberOfReinforcements] fontName:@"Armalite Rifle" fontSize:40];
        [numberOfUnits setPosition:ccp(240,210)];
        [self addChild:numberOfUnits];
        
        CCLabelTTF* alertTest = [CCLabelTTF labelWithString:@"Would you like to claim them now?" fontName:@"Armalite Rifle" fontSize:16];
        [alertTest setPosition:ccp(240, 175)];
        [self addChild:alertTest];
        
        CCLabelTTF* postponeText1 = [CCLabelTTF labelWithString:@"If you don't, you will continue to be" fontName:@"Armalite Rifle" fontSize:16];
        [postponeText1 setPosition:ccp(240, 155)];
        [self addChild:postponeText1];
        
        CCLabelTTF* postponeText2 = [CCLabelTTF labelWithString:@"asked until you do" fontName:@"Armalite Rifle" fontSize:16];
        [postponeText2 setPosition:ccp(240, 135)];
        [self addChild:postponeText2];
        
        yesButton = [CCSprite spriteWithFile:@"Yes-Button.png"];
        [yesButton setPosition:ccp(310, 90)];
        [self addChild:yesButton];
        
        noButton = [CCSprite spriteWithFile:@"No-Button.png"];
        [noButton setPosition:ccp(170, 90)];
        [self addChild:noButton];
    }
    return self;
}

-(void) registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:1 swallowsTouches:YES];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    //Translate into COCOA coordinates
    CGPoint touchLocation = [touch locationInView: [touch view]];
    touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    
    //Make sure the touch is on the map, otherwise ignore it
    if(CGRectContainsPoint([noButton boundingBox],touchLocation)){
        [self noButtonTouched];
        return YES;
    }
    
    //Make sure the touch is on the map, otherwise ignore it
    if(CGRectContainsPoint([yesButton boundingBox],touchLocation)){
        [self yesButtonTouched];
        return YES;
    }
    
    return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
    //Swiper no swiping
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView: [touch view]];
    
    //Translate into COCOA coordinates
    touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    
    //Make sure the touch is on the map, otherwise ignore it
    if(CGRectContainsPoint([noButton boundingBox],touchLocation)){
        [self noButtonTouched];
    }
    
    //Make sure the touch is on the map, otherwise ignore it
    if(CGRectContainsPoint([yesButton boundingBox],touchLocation)){
        [self yesButtonTouched];
        
    }
}

-(void)noButtonTouched
{
    if(noPressed){
        noPressed = NO;
        [noButton setTexture:[[CCTextureCache sharedTextureCache] addImage:@"No-Button.png"]];
        
        if(delegate){
            [delegate confirmResponse:NO withState:currentState];
        }
        
    }else{
        [noButton setTexture:[[CCTextureCache sharedTextureCache] addImage:@"No-Button-Pressed.png"]];
        noPressed = YES;
    }
}

-(void)yesButtonTouched
{
    if(yesPressed){
        [yesButton setTexture:[[CCTextureCache sharedTextureCache] addImage:@"Yes-Button.png"]];
        yesPressed = NO;
        
        if(delegate){
            [delegate confirmResponse:YES withState:currentState];
        }
        
    }else{
        [yesButton setTexture:[[CCTextureCache sharedTextureCache] addImage:@"Yes-Button-Pressed.png"]];
        yesPressed = YES;
    }
}

@end
