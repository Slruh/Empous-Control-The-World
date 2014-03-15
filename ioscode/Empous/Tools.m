//
//  Tools.m
//  Empous
//
//  Created by Shane Guineau on 1/29/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "Tools.h"
#import "Map.h"
#import "cocos2d.h"
#import "SimpleAudioEngine.h"

@implementation Tools

//Shift the map over to center on the iphone5
static float shiftAmount = (568 - 480)/2;

+ (float) getShiftAmount
{
    return shiftAmount;
}

//Returns the minimum of the two integers
+ (int) chooseMinIntOf:(int)a and:(int)b
{
    if (a > b){
        return b;
    }
    return a;
}

//Returns the maximum of the two integers
+ (int) chooseMaxIntOf:(int)a and:(int)b
{
    if (a > b){
        return a;
    }
    return b;
}

//Insert number into one dimmensional NSMutableArray
+ (void) insertIntIntoNSMutableArray:(NSMutableArray*)array index:(int)x value:(int)num
{
    NSNumber* nsNum = [[NSNumber alloc] initWithInt: num];
    [array insertObject: nsNum atIndex: x];
    [nsNum release];
}

//Insert number into two dimmensional NSMutableArray
+ (void) insertIntIntoNSMutableArray:(NSMutableArray*)array row:(int)x col:(int)y value:(int)num;
{
    NSNumber* nsNum = [[NSNumber alloc] initWithInt: num];
    [[array objectAtIndex: x] insertObject: nsNum atIndex: y];
    [nsNum release];
}

//Convert a Coordinate Array to a CGPoint
+ (CGPoint) convertCoordinateArrayToCGPoint: (NSMutableArray*) coordinate{
    return CGPointMake([[coordinate objectAtIndex:0] intValue], [[coordinate objectAtIndex:1] intValue]);
}

#pragma mark -
#pragma mark Map Conversion Methods

+ (CGPoint) mapToWorld:(CGPoint)mapPoint{
    CGPoint temp = CGPointMake((int)(mapPoint.x)*kNumPixelsPerTileSquare,(int)(mapPoint.y)*kNumPixelsPerTileSquare);
    
    //Change the x position if an iPhone 5 to center the map
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    if(winSize.width == 568)
    {
        return CGPointMake(temp.x + shiftAmount, temp.y);
    }
    
    return temp;
}

+ (CGPoint) worldToMap:(CGPoint)worldPoint{
    CGPoint temp;

    CGSize winSize = [[CCDirector sharedDirector] winSize];
    if(winSize.width == 568)
    {
        temp = CGPointMake((int)(worldPoint.x - shiftAmount),(int)(worldPoint.y));
    }
    else
    {
        temp = CGPointMake((int)(worldPoint.x),(int)(worldPoint.y));
    }
    
    return CGPointMake((int)(temp.x)/kNumPixelsPerTileSquare,(int)(temp.y)/kNumPixelsPerTileSquare);
}
+ (CGPoint) mapToTileMap:(Map*)map point:(CGPoint)mapPoint{
    return CGPointMake(mapPoint.x, [map height] - mapPoint.y - 1);
    
}
+ (CGPoint) tileMapToMap:(Map*)map point:(CGPoint)mapPoint{
    return CGPointMake(mapPoint.x, ([map height] - mapPoint.y) + mapPoint.y + 1);
}
+ (CGPoint) mapLabelLocationToWorld:(CGPoint)mapPoint
{
    
    //CGPoint temp = CGPointMake((int)(mapPoint.x)*kNumPixelsPerTileSquare,(int)(mapPoint.y)*kNumPixelsPerTileSquare);
    CGPoint temp = [Tools mapToWorld:mapPoint];
    return CGPointMake(temp.x + 8, temp.y+8);
}

#pragma mark - Game/Screenshot Archive Functions

+(NSString*)gameArchivePathWithGameId:(NSString*)gameId deleteIfExists:(BOOL)shouldDelete
{
    return [self archivePathWithGameId:gameId andFileExtension:@"em" deleteIfExists:shouldDelete];
}

+(NSString*)jsonGameArchivePathWithGameId:(NSString*)gameId deleteIfExists:(BOOL)shouldDelete
{
    return [self archivePathWithGameId:gameId andFileExtension:@"json" deleteIfExists:shouldDelete];
}

+(NSString*)areLocalModsToGame:(NSString*)gameId
{
    NSString* gameStatePath = [Tools jsonGameArchivePathWithGameId:gameId deleteIfExists:NO];
    if([[NSFileManager defaultManager] fileExistsAtPath:gameStatePath])
    {
        return gameStatePath;
    }
    else
    {
        return nil;
    }
}

+(BOOL)screenshotAvailable:(NSString*)gameId
{
    NSString* screenShotPath = [Tools screenshotArchivePathWithGameId:gameId deleteIfExists:NO];
    return [[NSFileManager defaultManager] fileExistsAtPath:screenShotPath];
}

+(NSString*)screenshotArchiveFilename:(NSString*)gameId deleteIdExists:(BOOL)shouldDelete;
{
    [self archivePathWithGameId:gameId andFileExtension:@"png" deleteIfExists:shouldDelete];
    return [NSString stringWithFormat:@"%@.%@", gameId, @"png"];

}

+(NSString*)screenshotArchivePathWithGameId:(NSString*)gameId deleteIfExists:(BOOL)shouldDelete

{
    //Deletes the file if it exists
    return [self archivePathWithGameId:gameId andFileExtension:@"png" deleteIfExists:shouldDelete];
}

+(NSString*)archivePathWithGameId:(NSString*)gameId andFileExtension:(NSString*)extension deleteIfExists:(BOOL)shouldDelete
{
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", gameId,extension]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    BOOL fileExists = [fileManager fileExistsAtPath:path];
    if (fileExists && shouldDelete)
    {
        BOOL success = [fileManager removeItemAtPath:path error:&error];
        if (!success)
        {
            NSLog(@"Error: %@", [error localizedDescription]);
            return nil;
        }
    }
    return path;
}

+(CCRenderTexture*)createStroke:(CCLabelTTF*)label size:(float)size color:(ccColor3B)cor
{
    CCRenderTexture* rt = [CCRenderTexture renderTextureWithWidth:label.texture.contentSize.width+size*2  height:label.texture.contentSize.height+size*2];
    CGPoint originalPos = [label position];
    ccColor3B originalColor = [label color];
    BOOL originalVisibility = [label visible];
    [label setColor:cor];
    [label setVisible:YES];
    ccBlendFunc originalBlend = [label blendFunc];
    [label setBlendFunc:(ccBlendFunc) { GL_SRC_ALPHA, GL_ONE }];
    CGPoint meio = ccp(label.texture.contentSize.width/2+size, label.texture.contentSize.height/2+size);
    [rt begin];
    for (int i=0; i<360; i+=30) // you should optimize that for your needs
    {
        [label setPosition:ccp(meio.x + sin(CC_DEGREES_TO_RADIANS(i))*size, meio.y + cos(CC_DEGREES_TO_RADIANS(i))*size)];
        [label visit];
    }
    [rt end];
    [label setPosition:originalPos];
    [label setColor:originalColor];
    [label setBlendFunc:originalBlend];
    [label setVisible:originalVisibility];
    [rt setPosition:originalPos];
    return rt;
}

+(void)toggleAudioEngineFromDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isSilenced = [defaults boolForKey:@"isSilenced"];
    
    if (!isSilenced)
    {
        if (![[SimpleAudioEngine sharedEngine] enabled])
        {
            [[SimpleAudioEngine sharedEngine] setEnabled:YES];
        }
    }
    else
    {
        [[SimpleAudioEngine sharedEngine] setEnabled:NO];
    }
}

+(void)playEmpousThemeIfNotSilenced
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isSilenced = [defaults boolForKey:@"isSilenced"];
    
    if (!isSilenced)
    {
        if (![[SimpleAudioEngine sharedEngine] enabled])
        {
            [[SimpleAudioEngine sharedEngine] setEnabled:YES];
        }
        
        if (![[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying])
        {
            [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"empous_theme.mp3"];
        }
    }
    else
    {
        [[SimpleAudioEngine sharedEngine] setEnabled:NO];
    }
}

+(BOOL)isEmpousLite
{
    return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"IsEmpousLite"] boolValue];
}

@end
