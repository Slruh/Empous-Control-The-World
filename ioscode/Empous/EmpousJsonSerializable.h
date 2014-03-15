//
//  EmpousJsonSerializable.h
//  Empous
//
//  Created by Ryan Personal on 11/30/13.
//  Copyright (c) 2013 HurleyProg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@protocol EmpousSerializable <NSObject>

/**
 * Turns the given object into a dictionary so NSJSONSerialization can be used.
 * All values must be turned into Foundation objects e.g. NSNumber, NSString, etc
 */
-(NSDictionary*)toJSONDict;
-(id)initWithJsonData:(NSDictionary*)jsonData;

@end

@interface EmpousJsonSerializable : NSObject

+(NSDictionary*)colorAsDict:(ccColor4B)color;

+(ccColor4B)colorFromDict:(NSDictionary*)dict;

+(NSDictionary*)pointAsDict:(CGPoint)point;

+(NSArray*)setOfCoordinatesToArray:(NSSet*)set;

+(NSMutableSet*)arrayOfCoordinatesToSet:(NSArray*)array;

@end
