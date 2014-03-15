//
//  ScrollMenu.m
//  Empous
//
//  Created by Ryan Hurley on 5/6/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "ScrollMenu.h"

#define SCROLL_THRESHOLD  2.0
float cum_dif = 0.0;
float last_dif = 0.0;
bool isDragging,touched = NO;
double menuHeight = 0.0;
double padding = 10.0;

@implementation ScrollMenu

-(id)init{
    self = [super init];
    if(self){
        
    }
    return self;
}

-(id)initWithCGRectBoundsAndDelegate:(CGPoint)center withHeight:(int)height withWidth:(int)width andDelegate:(id)newDelegate
{
    self = [self init];
    if(self){
        
        if(![[newDelegate class] conformsToProtocol:@protocol(ScrollMenuDelegate)]){
            [NSException raise:@"Delegate Exception" format:@"Delegate of class %@ is invalid", [newDelegate class]];
        }else{
            [newDelegate retain];
            delegate = newDelegate;
        }
        
        menuHeightBounds = height;
        menuWidthBounds = width;
        menuCenterBounds = center;
        
        menuItemAttributes = [[NSMutableDictionary alloc] init];
        
        //Set the background of the menu
        //TODO: Make this more generic, listen to the bounds method might need more params...
        menuBackground = [CCSprite spriteWithFile:@"Notification.png"];
        [menuBackground setPosition:center];
        [self addChild:menuBackground z:0];
        
        [menuBackground setScaleX:width * CC_CONTENT_SCALE_FACTOR()];
        [menuBackground setScaleY:height * CC_CONTENT_SCALE_FACTOR()];
        
        clippingNode = [ClippingNode node];
        [clippingNode setClippingRegion:[menuBackground boundingBox]];
        [self addChild:clippingNode z:1];
        
        [self setTouchEnabled:YES];
    }
    return self;
}

-(void)clearMenu
{
    if(mainMenu != nil){
        [clippingNode removeChild:mainMenu cleanup:YES];
    }
    
    menuHeight = 10;
    mainMenu = [CCMenu menuWithItems:nil];

    [menuItemAttributes release];
    menuItemAttributes = [[NSMutableDictionary alloc]init];

    //TODO make this more generic for positioning
    [mainMenu setPosition:ccp(menuCenterBounds.x,menuCenterBounds.y+(menuHeightBounds/2)-padding)];

    //[mainMenu setPosition:menuCenterBounds];
    [mainMenu alignItemsVertically];
    [mainMenu setTouchEnabled:NO];
    [clippingNode addChild:mainMenu];
}


#pragma mark -
#pragma mark touches

-(void) registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    //Translate into COCOA coordinates
    CGPoint touchLocation = [touch locationInView: [touch view]];	
    touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    
    if(CGRectContainsPoint([menuBackground boundingBox], touchLocation)){
        //NSLog(@"Touch");
        touched = YES;
        return YES;
    }
    
    return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
    //Only scroll if touched first and menu larger than screen size
    if(touched == NO || menuHeight < menuHeightBounds){
        //NSLog(@"NO SCROLL");
        return;
    }
    
    CGPoint prevPoint = [[CCDirector sharedDirector] convertToGL:[touch previousLocationInView:touch.view]];
    CGPoint curPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
    
    float diff = (prevPoint.y - curPoint.y);
    cum_dif += diff;
    
    if(abs(diff) > SCROLL_THRESHOLD){
        cum_dif = diff;
        isDragging = YES;
        [self scrollMenu];
    }

}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    //NSLog(@"End");
    if(touched){
        //Tapped in the Menu instead of dragging
        if((isDragging == NO) && [touch tapCount] == 1){
            
            CCMenuItemLabel* menuItem = (CCMenuItemLabel*)[mainMenu itemForTouch:touch];
            //This does happen
            if(menuItem == nil){
                return;
            }
            NSString* menuLabel = [[menuItem label]string];
            NSMutableDictionary* itemAttributes = [menuItemAttributes objectForKey:menuLabel];
            
            if (nil != [itemAttributes objectForKey:@"noMoreGames"])
            {
                UIAlertView* dialog = [[UIAlertView alloc] init];
                [dialog setDelegate:self];
                [dialog setTitle:@"Can Not Add Friend"];
                [dialog setMessage:@"Your friend has Empous Lite and is already playing the maximum number of games."];
                [dialog addButtonWithTitle:@"OK"];
                [dialog show];
                [dialog release];
            }

            else if(nil == [itemAttributes objectForKey:@"isDisabled"]){
                [delegate menuItemTouched:menuLabel];
            }
            
        }else{
            //Only scroll if touched first and menu larger than screen size
            if(touched == NO || menuHeight < menuHeightBounds){
                return;
            }
            
            CGPoint currentPosition = mainMenu.position;

            //Limit the movement to the size of the menu
            if(currentPosition.y < menuCenterBounds.y+(menuHeightBounds/2)-padding){
                currentPosition.y = menuCenterBounds.y+(menuHeightBounds/2)-padding;
            }
            
            if((menuHeight - (currentPosition.y - menuCenterBounds.y) -padding ) < menuHeightBounds/2){
                currentPosition.y = menuCenterBounds.y + (menuHeight - menuHeightBounds/2) - padding;
            }
            
            [mainMenu runAction:[CCMoveTo actionWithDuration:0.1f position:currentPosition]];
        }
    }
    
    touched = isDragging = NO;
    last_dif = 0.0;
}

-(void)scrollMenu
{
    float moveBy = 0.0;
    
    if(abs(cum_dif) > SCROLL_THRESHOLD){
        moveBy = cum_dif;
        cum_dif = 0.0;
    }

    if(moveBy != 0.0){
        CGPoint currentPosition = mainMenu.position;
        currentPosition.y -= moveBy;
        
        CCAction *moveMenu = [CCPlace actionWithPosition:currentPosition];
        [mainMenu runAction:moveMenu];
    }
}

-(void)addItem:(NSString*)menuItemText doesSupportContinents:(BOOL)supportsContinents;
{
    //Create the label and add it to the menu item
    CCLabelTTF* label = [CCLabelTTF labelWithString:menuItemText fontName:@"Helvetica Neue" fontSize:20];
    [label setPosition:ccp(30,0)];
   
    //Create the menu item using the label
    CCMenuItemLabel *menuItem = [CCMenuItemLabel itemWithLabel:label];
    [menuItem setAnchorPoint:ccp(0.0f,0.5f)];
    menuItem.position = ccp(-menuWidthBounds/2,0-menuHeight);
    
    //Create an icon if they support continents
    if (supportsContinents)
    {
        CCSprite* icon = [CCSprite spriteWithFile:@"Continent.png"];
        [icon setAnchorPoint:ccp(0.0,0)];
        [icon setPosition:ccp(5,0)];
        [menuItem addChild:icon];
    }
    
    //Add the menu item
    [mainMenu addChild:menuItem];
    menuHeight += [menuItem contentSize].height;
    
    //
    
    //Add the label to the dictionary
    NSMutableDictionary* itemAttributes = [[NSMutableDictionary alloc]init];
    [itemAttributes setObject:menuItem forKey:@"menuItem"];
    [menuItemAttributes setObject:itemAttributes forKey:menuItemText];
    [itemAttributes release];
}

-(void)removeItem:(NSString *)menuItemText
{
    //Get the entry out of the attributes dictionary
    NSMutableDictionary* itemAttributes = [menuItemAttributes objectForKey:menuItemText];
    if(nil != itemAttributes)
    {
        //Remove from menu
        CCMenuItemLabel* menuItem = [itemAttributes objectForKey:@"menuItem"];
       
        [mainMenu removeChild:menuItem cleanup:YES];
        
        //Remove from attributes list
        [itemAttributes removeObjectForKey:menuItemText];
    }
}

-(void)disableItemForNoMoreGames:(NSString *)menuItemText
{
    NSMutableDictionary* itemAttributes = [menuItemAttributes objectForKey:menuItemText];
    [itemAttributes setValue:@"1" forKey:@"noMoreGames"];
    [self disableItem:menuItemText];
}

-(void)disableItem:(NSString*)menuItemText
{
    NSMutableDictionary* itemAttributes = [menuItemAttributes objectForKey:menuItemText];
    if(nil != itemAttributes)
    {
        CCMenuItemLabel* menuItem = [itemAttributes objectForKey:@"menuItem"];
        [[menuItem label]setColor:ccGRAY];
        
        [[menuItemAttributes objectForKey:menuItemText] setValue:@"1" forKey:@"isDisabled"];
    }
}

-(void)enableItem:(NSString*)menuItemText
{    
    NSMutableDictionary* itemAttributes = [menuItemAttributes objectForKey:menuItemText];
    if(nil != itemAttributes)
    {
        CCMenuItemLabel* menuItem = [itemAttributes objectForKey:@"menuItem"];
        [[menuItem label]setColor:ccWHITE];
        
        [[menuItemAttributes objectForKey:menuItemText] removeObjectForKey:@"isDisabled"];
    }
}

-(int)numberOfItems
{
    return [[mainMenu children] count];
}

-(CGRect)getMenuBackgroundBounds
{
    return [menuBackground boundingBox];
}
@end
