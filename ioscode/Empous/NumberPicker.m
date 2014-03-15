//
//  NumberPicker.m
//  Empous
//
//  Created by Ryan Hurley on 3/20/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "NumberPicker.h"
#import "GameScene.h"

@implementation NumberPicker
@synthesize addButton;
@synthesize minusButton;
@synthesize currentValue;

- (id)init
{
    [NSException raise:@"MBMethodNotSupportedException" format:@"\"- (id)init\" is not supported. Please use the designated initializer \"- (id)initWithNSRangeAndCurrentIndex:range:start:\""];
    return nil;
}

-(id)initWithNSRange:(NSRange)range startValue:(int)start position:(CGPoint)position scene:(GameScene*)scene
{
    //pointsize must be multiple of 25
    self = [super init];
    if (self) {
        //Hold a reference to the scene
        gameScene = scene;
        
        background = [CCSprite spriteWithFile: @"Slider-Background.png"];
        [background setPosition:position];
        [self addChild:background z:-5];
        
        CCSprite* front = [CCSprite spriteWithFile: @"Slider-Front.png"];
        [front setPosition:position];
        [self addChild:front z:10];
        
        addButton = [CCButton spriteWithFile:@"Add-Button.png" withPressedFile:@"Add-Button-Pressed.png" touchAreaScale:2.0 target:self function:@selector(incrementTicker) sound:@"button.mp3"];
        [addButton setPosition:ccp(154,14)];
        [self addChild:addButton z:5];
        
        minusButton = [CCButton spriteWithFile:@"Minus-Button.png" withPressedFile:@"Minus-Button-Pressed.png" touchAreaScale:2.0 target:self function:@selector(decrementTicker) sound:@"button.mp3"];
        [minusButton setPosition:ccp(16,14)];
        [self addChild:minusButton z:5];
        
        itemsForPicker = [[NSMutableArray alloc] initWithCapacity:5]; //Number of eliments to show
        
        [self updatePickerValues:range startValue:start];
    }
    
    return self;
}

-(void)updatePickerValues:(NSRange)values startValue:(int)startValue
{
    //Remove the existing text from the ticker on the screen 
    for(CCLabelTTF* label in itemsForPicker){
        [self removeChild:label cleanup:YES];
    }
    
    //Releases all the objects
    [itemsForPicker removeAllObjects];
    
    //Put the new range in the class and remove the old 
    acceptableValues = values;
    
    if(values.length > 1){
        int textXLoc = 45;
        
        //We have a start value that should be the center value in the picker. This means we need two 
        //values before and two after
        int tickerValues[] = {startValue-2, startValue-1,startValue, startValue + 1, startValue +2};
        
        //Iterate through the values and replace them in the ticker 
        for(int i = 0; i < sizeof(tickerValues)/sizeof(int); i++){
            
            int valueToAdd = [self correctedValue:tickerValues[i]];
            
            CCLabelTTF* msg = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", valueToAdd] fontName:@"Armalite Rifle" fontSize:16];
            [msg setColor:ccc3(0,0,0)];
            [msg setPosition:ccp(textXLoc,15)];
            [self addChild:msg z:0];
            [itemsForPicker addObject:msg];
            
            textXLoc += 20;
            
        }
        
        //Get the new current value
        currentValue = [[[itemsForPicker objectAtIndex:2] string] intValue];
        [gameScene pickerValueChanged:currentValue];
    }
    
}

-(int)correctedValue:(int)value
{
    int upperBound = acceptableValues.location + (acceptableValues.length -1);
    int lowerBound = acceptableValues.location;
    
    //Out of the acceptable limits lower bound
    if(value < lowerBound){
        //Ex. If valueToAdd = -1 and the range starts at 0 then I really want the value of location+length
        int numberBelow = lowerBound - value;
        value = acceptableValues.location + (acceptableValues.length - 1) - (numberBelow - 1);
    }
    //Out of the acceptable limits upper bound
    else if(value > upperBound){
        int numberAbove = value - upperBound;
        value = acceptableValues.location + (numberAbove - 1);
    }
    
    return value;
}

-(void)decrementTicker
{
    if(acceptableValues.length <=1)
        return;
    
    //Get the first element 
    CCLabelTTF* currentFirst = [itemsForPicker objectAtIndex:0];
    
    //Calculate the value to add
    int valueToAdd = [[currentFirst string]intValue];
    valueToAdd = [self correctedValue:--valueToAdd];
    
    //Add a new first element 
    CCLabelTTF* newText = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", valueToAdd] fontName:@"Armalite Rifle" fontSize:16];
    [newText setColor:ccc3(0,0,0)];
    [newText setPosition:ccp(25,15)];
    [self addChild:newText z:0];
    [itemsForPicker insertObject:newText atIndex:0];
    
    //Animate all the elements to the right
    for(int i = 0; i < [itemsForPicker count]; i++){
        CCLabelTTF* text = [itemsForPicker objectAtIndex:i];
        id moveRight = [CCMoveBy actionWithDuration:.08 position:ccp(20,0)];
        if(i==5){
            id remove = [CCCallFunc actionWithTarget:self selector:@selector(removeLast)];
            id removeSeq = [CCSequence actions:moveRight,remove, nil];
            [text runAction:removeSeq];
            
        }else{
            [text runAction:moveRight];
        }
    }
}

-(void)incrementTicker
{
    if(acceptableValues.length <=1)
        return;

    //Get the last element 
    CCLabelTTF* currentlast = [itemsForPicker objectAtIndex:4];
    
    //Calculate the value to add
    int valueToAdd = [[currentlast string]intValue];
    valueToAdd = [self correctedValue:++valueToAdd];
    
    //Add a new first element 
    CCLabelTTF* newText = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", valueToAdd] fontName:@"Armalite Rifle" fontSize:16];
    [newText setColor:ccc3(0,0,0)];
    [newText setPosition:ccp(145,15)];
    [self addChild:newText z:0];
    [itemsForPicker addObject:newText];
    
    //Animate all the elements to the right
    for(int i = 0; i < [itemsForPicker count]; i++){
        CCLabelTTF* text = [itemsForPicker objectAtIndex:i];
        id moveLeft = [CCMoveBy actionWithDuration:.08 position:ccp(-20,0)];
        if(i==5){
            id remove = [CCCallFunc actionWithTarget:self selector:@selector(removeFirst)];
            id removeSeq = [CCSequence actions:moveLeft,remove, nil];
            [text runAction:removeSeq];
            
        }else{
            [text runAction:moveLeft];
        }
    }
}
 
-(void)removeLast{
    //Remove the last element from screen and list
    CCLabelTTF* text = [itemsForPicker objectAtIndex:5];
    [self removeChild:text cleanup:YES];
    [itemsForPicker removeObject:text];
    
    //Get the new current value
    currentValue = [[[itemsForPicker objectAtIndex:2] string] intValue];
    [gameScene pickerValueChanged:currentValue];
}

-(void)removeFirst{
    //Remove the last element from screen and list
    CCLabelTTF* text = [itemsForPicker objectAtIndex:0];
    [self removeChild:text cleanup:YES];
    [itemsForPicker removeObject:text];
    
    //Get the new current value
    currentValue = [[[itemsForPicker objectAtIndex:2] string] intValue];
    [gameScene pickerValueChanged:currentValue];
}

@end
