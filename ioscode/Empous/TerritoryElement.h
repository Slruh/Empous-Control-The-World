//
//  Territory.h
//  Empous
//
//  Created by Ryan Hurley on 1/19/12.
//  Copyright 2012 Apple. All rights reserved.
//

#include "MapElement.h"
#import "cocos2d.h"
#import "EmpousJsonSerializable.h"

@interface TerritoryElement : MapElement <NSCoding, EmpousSerializable>
{
    @public
        int tId;
        int empousId; //Player Id
        int units;
        int additionalUnits;
        BOOL highlighted;
        CGPoint originalLocation;
        CGPoint labelLocation;
        NSMutableSet* borders; //The bordering TerritoryElements
        NSMutableSet* borderCoordinates; //The coordinates of the borders
        NSMutableSet* controlledCoordinates; //Contains an array of NSNumbers where the first index represents x then y 
}

@property (assign) int tId;
@property (assign) int empousId;
@property (assign) int units;
@property (assign) int additionalUnits;
@property (assign) BOOL highlighted;
@property (nonatomic, retain) NSMutableSet* controlledCoordinates;
@property CGPoint originalLocation;
@property CGPoint labelLocation;
@property (retain) NSMutableSet* borders;

- (id)initWithId:(int)_tId xLoc:(int)x yLoc:(int) y;
- (NSMutableSet*) enemyTerritories;
- (NSMutableSet*) friendlyTerritories;
- (NSMutableSet*) unhighlightedfriendlyTerritories;
-(void)confirmAdditionalUnits;

@end
