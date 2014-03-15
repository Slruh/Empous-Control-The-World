//
//  ReinforcementLabelsLayer.h
//  Empous
//
//  Created by Ryan Hurley on 3/21/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "CCLayer.h"
#import "Player.h"

@interface ReinforcementLabelsLayer : CCLayer{
    Player* currentPlayer;
    int reinforcementsLeft;
}

@property int reinforcementsLeft;

-(id)initWithPlayer:(Player*)player;
-(id)initWithSourceTerritory:(TerritoryElement*)fortifyFrom toSinkTerritory:(TerritoryElement*)fortifyTo;

@end
