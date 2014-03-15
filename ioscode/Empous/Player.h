//
//  Player.h
//  Empous
//
//  Created by Ryan Hurley on 3/10/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TerritoryElement.h"
#import "Colors.h"
#import "cocos2d.h"
#import "EmpousJsonSerializable.h"

@interface Player : NSObject <NSCoding, EmpousSerializable>{
    NSMutableSet* territories;
    int pId;
    int empousId;
    ccColor4B color;
    NSString* name;
    int chanceBonusReinforcements;
}

@property (assign) ccColor4B color;
@property int chanceBonusReinforcements;
@property int empousId;
@property (retain) NSString* name;
@property (retain) NSMutableSet* territories;

-(id)initWithEmpousId:(int)theEmpousId playerName:(NSString*)playerName;
-(void)addTerritory:(TerritoryElement*) territory;

@end
