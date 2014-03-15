//
//  BorderLines.h
//  Empous
//
//  Created by Ryan Personal on 1/1/14.
//  Copyright (c) 2014 HurleyProg. All rights reserved.
//

#import "CCLayer.h"
#import "Map.h"

@interface BorderLines : CCLayer
{
    NSMutableSet* linesToDraw;
}

+ (id) nodeWithMap:(Map*)map;

@end
