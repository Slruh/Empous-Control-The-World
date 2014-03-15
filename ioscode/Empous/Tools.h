//
//  Tools.h
//  Empous
//
//  Created by Shane Guineau on 1/29/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Map.h"
#import "cocos2d.h"
#import "Extras.h"

@interface Tools : NSObject

#pragma mark - Max/Min Problem
+ (int) chooseMaxIntOf:(int)a and:(int)b;
+ (int) chooseMinIntOf:(int)a and:(int)b;

#pragma mark - Insert Primitives into NSStructure
+ (void) insertIntIntoNSMutableArray:(NSMutableArray*)array row:(int)x col:(int)y value:(int)num;
+ (void) insertIntIntoNSMutableArray:(NSMutableArray*)array index:(int)x value:(int)num;
+ (CGPoint) convertCoordinateArrayToCGPoint:(NSMutableArray*)coordinate;

#pragma mark - Map Conversion Methods
+ (CGPoint) mapToWorld:(CGPoint)mapPoint;
+ (CGPoint) worldToMap:(CGPoint)worldPoint;
+ (CGPoint) mapToTileMap:(Map*)map point:(CGPoint)mapPoint;
+ (CGPoint) tileMapToMap:(Map*)map point:(CGPoint)mapPoint;
+ (CGPoint) mapLabelLocationToWorld:(CGPoint)mapPoint;

+ (float) getShiftAmount;

#pragma mark - Game/Screenshot Archive Functions

+(NSString*)gameArchivePathWithGameId:(NSString*)gameId deleteIfExists:(BOOL)shouldDelete;
+(NSString*)jsonGameArchivePathWithGameId:(NSString*)gameId deleteIfExists:(BOOL)shouldDelete;
+(NSString*)areLocalModsToGame:(NSString*)gameId;
+(BOOL)screenshotAvailable:(NSString*)gameId;
+(NSString*)screenshotArchivePathWithGameId:(NSString*)gameId deleteIfExists:(BOOL)shouldDelete;
+(NSString*)screenshotArchiveFilename:(NSString*)gameId deleteIdExists:(BOOL)shouldDelete;
+(CCRenderTexture*)createStroke:(CCLabelTTF*)label size:(float)size color:(ccColor3B)cor;

+(void)playEmpousThemeIfNotSilenced;
+(void)toggleAudioEngineFromDefaults;
+(BOOL)isEmpousLite;

+(CGLine) CGLineMakeWithStart:(CGPoint)point1 andEnd:(CGPoint) point2;


@end
