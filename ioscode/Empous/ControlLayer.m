//
//  StatsLayer.m
//  Empous
//
//  Created by Ryan Hurley on 3/18/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "ControlLayer.h"
#import "GameScene.h"
#import "MainMenuScene.h"
#import "Colors.h"
#import "GameMenu.h"

@implementation ControlLayer
{
    GameMenu* menu;
    
    //Controls the swallowing of touches
    BOOL controlsVisible;
    BOOL menuVisible;
}

@synthesize attackButton;
@synthesize cancelButton;
@synthesize gameScene;

- (id)init
{
    [NSException raise:@"MBMethodNotSupportedException" format:@"\"- (id)init\" is not supported. Please use the designated initializer \"- (id)initWithGameScene:scene:\""];
    return nil;
}

-(id)initWithGameScene:(GameScene*)scene
{
    self = [super init];
    if (self) {
        self.gameScene = scene;
        
        //Set BOOLS
        controlsVisible = NO;
        menuVisible = NO;
        
        //Get screensize
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp(winSize.width/2,winSize.height/2);
        
        //Add the top bar
        CCSprite* topBar = [CCSprite spriteWithFile:@"Top-Green.png"];
        [topBar setPosition:ccp(center.x,308)];
        [self addChild:topBar];
        
        menuButton = [CCButton spriteWithFile:@"Menu-Button.png" withPressedFile:@"Menu-Button-Pressed.png" touchAreaScale:2.0 target:self function:@selector(menuButtonTouched) sound:@"button.mp3"];
        [menuButton setPosition:ccp(center.x,310)];
        [self addChild:menuButton];
        
        CCSprite* bottomBar = [CCSprite spriteWithFile:@"Bottom-Black.png"];
        [bottomBar setPosition:ccp(center.x,16)];
        [self addChild:bottomBar];

        textMessage = [CCLabelTTF labelWithString:@"0" fontName:@"Helvetica Neue" fontSize:16];
        [textMessage setAnchorPoint:ccp(0.0f,0.5f)];
        [textMessage setPosition:ccp(185,15)];
        [self addChild:textMessage];
        
        nextButton = [CCButton spriteWithFile:@"Next-Button.png" withPressedFile:@"Next-Button-Pressed.png" touchAreaScale:2.0 target:self.gameScene function:@selector(nextPhase) sound:@"button.mp3"];
        [nextButton setPosition:ccp(winSize.width - 37,14)];
        [self addChild:nextButton];
        
        int iphone5Scale = 22;
        playerLabels = [[NSMutableDictionary alloc] init];
        int textBoxX = 4;
        //Set up the 
        for (int i = 0; i < 4; i++)
        {
            //Background for the player labels
            CCSprite* background = [CCSprite spriteWithFile:@"Player-Text-Box.png"];
            background.anchorPoint = ccp(0,.5);
            if(winSize.width == 568)
            {
                background.scaleX = 1.25;
            }
            [background setPosition:ccp(textBoxX,309)];
            [self addChild:background];
            
            textBoxX += 100;
            if(winSize.width == 568)
            {
                textBoxX += iphone5Scale;
            }
            
            if(i == 1)
            {
                if(winSize.width == 568)
                {
                    textBoxX -= iphone5Scale;
                    textBoxX += 21;
                }
                textBoxX += 77;
            }
        }
        
        int playerLabelX = 20;
        int colorLabelX = playerLabelX - 12;
        int i = 0;
        for(id key in [gameScene playerLookup])
        {
            Player* player = [[gameScene playerLookup]objectForKey:key];
            
            //Player name
            CCLabelTTF* label = [CCLabelTTF labelWithString:[player description] fontName:@"Helvetica Neue" fontSize:12];
            label.anchorPoint = ccp(0,.5);
            [label setPosition:ccp(playerLabelX,309)];
            [self addChild:label z:1];
            
            //Add the label for future use
            [playerLabels setObject:label forKey:[NSString stringWithFormat:@"%d",[player empousId]]];
            
            //Player color
            CCLayerColor* playerColorBox = [CCLayerColor layerWithColor:[player color]];
            [playerColorBox changeHeight:8.0];
            [playerColorBox changeWidth:8.0];
            [playerColorBox setPosition:ccp(colorLabelX,305)];
            [self addChild:playerColorBox];
            
            colorLabelX += 100;
            playerLabelX += 100;
            
            if(winSize.width == 568)
            {
                colorLabelX += iphone5Scale;
                playerLabelX += iphone5Scale;
            }
            
            if(i == 1)
            {
                colorLabelX += 77;
                playerLabelX += 77;
            }
            i++;
        }
    }
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

-(void)setDelegate:(id)delegate
{
    if(![[delegate class] conformsToProtocol:@protocol(ControlLayerDelegate)]){
        [NSException raise:@"Delegate Exception" format:@"Delegate of class %@ is invalid", [delegate class]];
    }else{
        controlDelegate = delegate;
    }
}

-(void)setMessage:(NSString*)message
{
    [textMessage setString:message];
}

- (void)handleReturnToMain
{
    [[CCDirector sharedDirector] replaceScene:
	 [CCTransitionFade transitionWithDuration:0.5f scene:[MainMenuScene node]]];
}

-(void)updatePlayerLabels
{
    for(id key in [gameScene playerLookup]){
        Player* player = [[gameScene playerLookup]objectForKey:key];
        CCLabelTTF* label = [playerLabels objectForKey:[NSString stringWithFormat:@"%d",[player empousId]]];
        [label setString:[player description]];
    }
}

-(void)disableNextButton
{
    [nextButton disable];
}

-(void)enableNextButton
{
    [nextButton enable];
}

-(void)showAttackButtons
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    if(attackButton == NULL && cancelButton == NULL){
        //Show the attack and cancel buttons
        attackButton = [CCButton spriteWithFile:@"Attack-Button.png" withPressedFile:@"Attack-Button-Pressed.png" target:self.gameScene function:@selector(attack) sound:@"button.mp3"]; 
        cancelButton = [CCButton spriteWithFile:@"Cancel-Button.png" withPressedFile:@"Cancel-Button-Pressed.png" target:self function:@selector(cancelButtonTouched) sound:@"button.mp3"];
        [attackButton setPosition:ccp(center.x - 50, 270)];
        [cancelButton setPosition:ccp(center.x + 50, 270)];
        [self addChild:attackButton z:ATTACK_BUTTON_LEVEL];
        [self addChild:cancelButton z:ATTACK_BUTTON_LEVEL];
        
        //Tells the control layer to swallow touches
        controlsVisible = YES;
    }
}

-(void)cancelButtonTouched
{
    [gameScene resetMap];
    [self hideAttackButtons];
}

-(void)hideAttackButtons
{
    if(attackButton != NULL && cancelButton != NULL){
        //Hide the attack and cancel buttons
        [self removeChild:attackButton cleanup:YES];
        [self removeChild:cancelButton cleanup:YES];
    }
    
    [self enableNextButton];
        
    attackButton = NULL;
    cancelButton = NULL;
    controlsVisible = NO;
}

-(void)showCheckButton
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    if(checkButton == NULL){
        //Show the attack and cancel buttons
        checkButton = [CCButton spriteWithFile:@"Check-Button.png" withPressedFile:@"Check-Button-Pressed.png" target:self function:@selector(checkButtonTouched) sound:@"button.mp3"];
        [checkButton setPosition:ccp(center.x, 270)];
        [self addChild:checkButton z:ATTACK_BUTTON_LEVEL];
        controlsVisible = YES;
        [self disableNextButton];
    }
}

-(void)hideCheckButton
{
    if(checkButton != NULL){
        [self removeChild:checkButton cleanup:YES];
    }
    [self enableNextButton];
    checkButton = NULL;
    controlsVisible = NO;
}

-(void)checkButtonTouched
{
    [self hideCheckButton];
    [self.gameScene moveUnits];
}

-(void)menuButtonTouched
{
    [controlDelegate showMenu];
}

@end
