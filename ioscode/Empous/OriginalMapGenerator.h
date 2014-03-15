//
//  OriginalMapGenerator.h
//  Empous
//
//  Created by Ryan Personal on 12/29/13.
//  Copyright (c) 2013 HurleyProg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapGenerator.h"

@interface OriginalMapGenerator : MapGenerator

+ (Map*) createMapWithWidth:(int)width andHeight:(int)height withNumberOfTerritories:(int) numberOfTerritories;

@end
