//
//  ScrollMenu.h
//  Empous
//
//  Created by Ryan Hurley on 5/6/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "CCLayer.h"
#import "FacebookWrapper.h"
#import "cocos2d.h"
#import "ClippingNode.h"

@protocol ScrollMenuDelegate <NSObject>
-(void)menuItemTouched:(NSString*)menuItemText;

@end

@interface ScrollMenu : CCLayer{
    CCSprite* menuBackground;
    CCMenu* mainMenu;
    ClippingNode* clippingNode;
    
    int menuHeight;
    int menuHeightBounds;
    int menuWidthBounds;
    CGPoint menuCenterBounds;
    
    //Holds attributed like disabled
    NSMutableDictionary* menuItemAttributes;
    id <ScrollMenuDelegate> delegate;
}

-(id)initWithCGRectBoundsAndDelegate:(CGPoint)center withHeight:(int)height withWidth:(int)width andDelegate:(id)newDelegate;

-(void)addItem:(NSString*)menuItemText doesSupportContinents:(BOOL)supportsContinents;

-(void)removeItem:(NSString*)menuItemText;

//Removes all items from a menu
-(void)clearMenu;

//Restores the opacity of an item
-(void)enableItem:(NSString*)menuItemText;

//Lowers the opacity of an item
-(void)disableItem:(NSString*)menuItemText;

//Displays an alert when a button with this feature is touched
-(void)disableItemForNoMoreGames:(NSString *)menuItemText;

-(int)numberOfItems;

@end
