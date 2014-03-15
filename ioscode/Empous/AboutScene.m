//
//  AboutScene.m
//  Empous
//
//  Created by Ryan Personal on 7/19/13.
//  Copyright (c) 2013 HurleyProg. All rights reserved.
//

#import "AboutScene.h"
#import "cocos2d.h"
#import "BottomBar.h"
#import "CCButton.h"
#import "CCScrollLayer.h"
#import "Tools.h"

@implementation AboutScene

-(id)init
{
    if(self = [super init])
    {
        [Tools playEmpousThemeIfNotSilenced];
        
        //Initialize scroll layer
        NSMutableArray* layersForScrolling = [[NSMutableArray alloc] init];

        //Get screensize
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp(winSize.width/2,winSize.height/2);
        
        CCSprite* background = [CCSprite spriteWithFile: @"Empous-Background.png"];
        background.position = ccp(center.x, 160);
        [self addChild:background];
        
        //Add the bottom bar with play button
        BottomBar* bottomBar = [BottomBar nodeWithPlayButton:NO andDelegate:self withPush:NO];
        [self addChild:bottomBar z:1];
        
        [self addEmpousSupportLayer:layersForScrolling];
        [self addEmpousDevLayer:layersForScrolling];
        
        CCScrollLayer* scrollLayer = [CCScrollLayer nodeWithLayers:layersForScrolling widthOffset:0];
        scrollLayer.stealTouches = NO;
        scrollLayer.pagesIndicatorPosition = ccp(winSize.width * 0.5f, 15);
        
        [layersForScrolling release];
        [self addChild:scrollLayer z:5];
    }
    return self;
}

-(void)addEmpousSupportLayer:(NSMutableArray*)layers
{
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    CCLayer* aboutLayer = [CCLayer node];
    
    CCButton* logo = [CCButton spriteWithFile:@"Empous-Logo.png" withPressedFile:@"Empous-Logo.png" target:self function:@selector(openEmpousWebsite)];
    [logo setPosition:ccp(center.x,3*winSize.height/4)];
    [aboutLayer addChild:logo];
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [NSString stringWithFormat:@"Version %@", [infoDict objectForKey:@"CFBundleShortVersionString"]];
    NSString *builderNumber = [NSString stringWithFormat:@"Build Number %@", [infoDict objectForKey:@"CFBundleVersion"]];
    
    CCLabelTTF* versionLabel = [CCLabelTTF labelWithString:version fontName:@"Armalite Rifle" fontSize:24];
    [versionLabel setColor:ccBLACK];
    [versionLabel setPosition:ccp(center.x, 165)];
    [aboutLayer addChild:versionLabel];
    
    CCLabelTTF* buildLabel = [CCLabelTTF labelWithString:builderNumber fontName:@"Armalite Rifle" fontSize:24];
    [buildLabel setColor:ccBLACK];
    [buildLabel setPosition:ccp(center.x, 135)];
    [aboutLayer addChild:buildLabel];
    
    CCLabelTTF* emailLabel = [CCLabelTTF labelWithString:@"problems or feedback?" fontName:@"Armalite Rifle" fontSize:24];
    [emailLabel setColor:ccBLACK];
    [emailLabel setPosition:ccp(center.x, 90)];
    [aboutLayer addChild:emailLabel];
    
    CCButton* email = [CCButton spriteWithFile:@"Support.png" withPressedFile:@"Support-Pressed.png" target:self function:@selector(showEmailDialog)];
    [email setPosition:ccp(center.x, 60)];
    [aboutLayer addChild:email];
    
    [layers addObject:aboutLayer];
}

-(void)addEmpousDevLayer:(NSMutableArray*)layers
{
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    CCLayer* devLayer = [CCLayer node];
    
    CCLabelTTF* developerLabel = [CCLabelTTF labelWithString:@"Developer" fontName:@"Armalite Rifle" fontSize:24];
    [developerLabel setColor:ccBLACK];
    [developerLabel setPosition:ccp(center.x, 295)];
    [devLayer addChild:developerLabel];
    
    CCButton* hurleyProgLaunch = [CCButton spriteWithFile:@"RyanHurley.png" withPressedFile:@"RyanHurley-Pressed.png" target:self function:@selector(openHurleyProgWebsite) sound:@"button.mp3"];
    [hurleyProgLaunch setPosition:ccp(center.x, 270)];
    [devLayer addChild:hurleyProgLaunch];
    
    CCLabelTTF* composerLabel = [CCLabelTTF labelWithString:@"Composer" fontName:@"Armalite Rifle" fontSize:24];
    [composerLabel setColor:ccBLACK];
    [composerLabel setPosition:ccp(center.x, 235)];
    [devLayer addChild:composerLabel];
    
    CCButton* composerLaunch = [CCButton spriteWithFile:@"JonnieDredge.png" withPressedFile:@"JonnieDredge-Pressed.png" target:self function:@selector(openComposerWebsite) sound:@"button.mp3"];
    [composerLaunch setPosition:ccp(center.x, 210)];
    [devLayer addChild:composerLaunch];
    
    CCLabelTTF* testersLabel = [CCLabelTTF labelWithString:@"Special Thanks To" fontName:@"Armalite Rifle" fontSize:24];
    [testersLabel setColor:ccBLACK];
    [testersLabel setPosition:ccp(center.x, 175)];
    [devLayer addChild:testersLabel];
    
    NSArray* betaTestersLeftColumn = [NSArray arrayWithObjects:@"Dan Anthony",@"Richard Cabral",@"Jacob Carroll", @"Andrew Dimarco", @"Shane Guineau", nil];
    
    NSArray* betaTestersRightColumn = [NSArray arrayWithObjects:@"Alex Lee",@"Beq Lendvay",@"Erik Orndorff", @"Nathan Ray", @"Darrell Troie", nil];
    
    int height = 170;
    for (NSString* name in betaTestersLeftColumn)
    {
        height -= 25;
        CCLabelTTF* testerName = [CCLabelTTF labelWithString:name fontName:@"Armalite Rifle" fontSize:15];
        [testerName setColor:ccBLACK];
        [testerName setPosition:ccp(center.x-100,height)];
        [devLayer addChild:testerName];
    }
    
    height = 170;
    for (NSString* name in betaTestersRightColumn)
    {
        height -= 25;
        CCLabelTTF* testerName = [CCLabelTTF labelWithString:name fontName:@"Armalite Rifle" fontSize:15];
        [testerName setColor:ccBLACK];
        [testerName setPosition:ccp(center.x+100,height)];
        [devLayer addChild:testerName];
    }
    
    [layers addObject:devLayer];
}

-(void)showEmailDialog
{
    NSString *subject = [NSString stringWithFormat:@"Empous Feedback"];
    NSString *mail = [NSString stringWithFormat:@"support@empous.com"];
    
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"mailto:?to=%@&subject=%@",
                                                [mail stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                                                [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
    
    if(![[UIApplication sharedApplication] openURL:url])
    {
        UIAlertView* dialog = [[UIAlertView alloc] init];
        [dialog setDelegate:self];
        [dialog setTitle:@"Could Not Open Mail"];
        [dialog setMessage:@"If you would like to leave feedback, send an email to support@empous.com"];
        [dialog addButtonWithTitle:@"Ok"];
        [dialog show];
        [dialog release];
    }
    [url release];
}

-(void)openEmpousWebsite
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.empous.com"]];
}

-(void)openHurleyProgWebsite
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.hurleyprog.com"]];
}

-(void)openComposerWebsite
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://jonniedredge.com"]];
}


@end
