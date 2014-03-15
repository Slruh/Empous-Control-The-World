//
//  AttackLines.h
//  Empous
//
//  Created by Ryan Hurley on 3/23/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "CCLayer.h"

@interface AttackLines : CCLayer{
    NSMutableArray* linesToDraw;
    NSMutableArray* redLinesToDraw;
}

-(void)addLineFrom:(CGPoint)start toEnd:(CGPoint) end;
-(void)addRedLineFrom:(CGPoint)start toEnd:(CGPoint)end;
-(void)clearLines;
-(void)clearWhiteLines;
-(void)clearRedLines;


@end
