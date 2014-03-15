//
//  MapElement.h
//  Empous
//
//  Created by Ryan Hurley on 1/19/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EmpousJsonSerializable.h"

@interface MapElement : NSObject <NSCoding, EmpousSerializable>
{
    @public
        int kind;
        int xloc;
        int yloc;
}

@property int kind;


#define WATER 0
#define TERRITORY 1


-(id)initWithXLoc:(int)x andYLoc:(int)y;


@end
