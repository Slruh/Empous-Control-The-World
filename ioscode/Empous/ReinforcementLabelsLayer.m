//
//  ReinforcementLabelsLayer.m
//  Empous
//
//  Created by Ryan Hurley on 3/21/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "ReinforcementLabelsLayer.h"
#import "Colors.h"
#import "Tools.h"

@implementation ReinforcementLabelsLayer
@synthesize reinforcementsLeft;

- (id)init
{
    [NSException raise:@"MBMethodNotSupportedException" format:@"\"- (id)init\" is not supported. Please use the designated initializer \"- (id)initWithGameMap:player:\""];
    return nil;
}

-(id)initWithPlayer:(Player*)player
{
    self = [super init];
    if(self){
        currentPlayer = player;
        
        for(TerritoryElement* territory in [player territories]){
            CCLabelTTF* label = [CCLabelTTF labelWithString:@"+0" fontName:@"Armalite Rifle" fontSize:12];
            [label setColor:ccGREEN];
            CGPoint point = [Tools mapToWorld:[territory labelLocation]];
            [label setPosition:ccp(point.x+16,point.y)];
            [self addChild:label z:0 tag:[territory tId]];
        }
    }
    return self;
}

-(id)initWithSourceTerritory:(TerritoryElement *)fortifyFrom toSinkTerritory:(TerritoryElement *)fortifyTo{
    self = [super init];
    if(self){
        CCLabelTTF* fromLabel = [CCLabelTTF labelWithString:@"-0" fontName:@"Armalite Rifle" fontSize:12];
        [fromLabel setColor:ccRED];
        CGPoint point = [Tools mapToWorld:[fortifyFrom labelLocation]];
        [fromLabel setPosition:ccp(point.x+16,point.y)];
        [self addChild:fromLabel z:0 tag:[fortifyFrom tId]];
        
        CCLabelTTF* toLabel = [CCLabelTTF labelWithString:@"+0" fontName:@"Armalite Rifle" fontSize:12];
        [toLabel setColor:ccGREEN];
        point = [Tools mapToWorld:[fortifyTo labelLocation]];
        [toLabel setPosition:ccp(point.x+16,point.y)];
        [self addChild:toLabel z:0 tag:[fortifyTo tId]];
    }
    return self;
}

@end
