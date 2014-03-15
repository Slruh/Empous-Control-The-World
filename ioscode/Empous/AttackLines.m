//
//  AttackLines.m
//  Empous
//
//  Created by Ryan Hurley on 3/23/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "AttackLines.h"
#import "cocos2d.h"
#import "Tools.h"

@implementation AttackLines

- (id)init
{
    self = [super init];
    if (self) {
        linesToDraw = [[NSMutableArray alloc]init];
        redLinesToDraw = [[NSMutableArray alloc]init];
    }
    
    return self;
}

-(void)dealloc
{    
    [linesToDraw release];
    [super dealloc];
}

-(void)draw
{
    //Set color and line width
    glLineWidth(1.0f);

    for(NSMutableArray* line in linesToDraw){
        CGPoint start, end;
        
        [[line objectAtIndex:0]getValue:&start];
        [[line objectAtIndex:1]getValue:&end];
        
        CGPoint startCorrected = [Tools mapLabelLocationToWorld:start];
        CGPoint endCorrected = [Tools mapLabelLocationToWorld:end];
        ccDrawColor4F(1.0,1.0,1.0,1.0);
        ccDrawLine(startCorrected, endCorrected);
    }
    
    glLineWidth(2.0f);
    for(NSMutableArray* line in redLinesToDraw){
        CGPoint start, end;
        
        [[line objectAtIndex:0]getValue:&start];
        [[line objectAtIndex:1]getValue:&end];
        
        CGPoint startCorrected = [Tools mapLabelLocationToWorld:start];
        CGPoint endCorrected = [Tools mapLabelLocationToWorld:end];
        ccDrawColor4F(1.0,0.0,0.0,1.0);
        ccDrawLine(startCorrected, endCorrected);
    }
}

-(void)addLineFrom:(CGPoint)start toEnd:(CGPoint)end
{
    NSMutableArray* line = [[NSMutableArray alloc]initWithCapacity:2];
    [line addObject:[NSValue valueWithBytes:&start objCType:@encode(CGPoint)]];
    [line addObject:[NSValue valueWithBytes:&end objCType:@encode(CGPoint)]];
    
    [linesToDraw addObject:line];
    [line release];
}

-(void)addRedLineFrom:(CGPoint)start toEnd:(CGPoint)end
{
    NSMutableArray* line = [[NSMutableArray alloc]initWithCapacity:2];
    [line addObject:[NSValue valueWithBytes:&start objCType:@encode(CGPoint)]];
    [line addObject:[NSValue valueWithBytes:&end objCType:@encode(CGPoint)]];
    
    [redLinesToDraw addObject:line];
    [line release];
}

-(void)clearLines
{
    [linesToDraw removeAllObjects];
    [redLinesToDraw removeAllObjects];
}

-(void)clearWhiteLines
{
    [linesToDraw removeAllObjects];
}

-(void)clearRedLines{
    [redLinesToDraw removeAllObjects];
}

@end
