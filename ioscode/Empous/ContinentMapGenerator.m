//
//  ContinentMapGenerator.m
//  Empous
//
//  Created by Ryan Personal on 12/30/13.
//  Copyright (c) 2013 HurleyProg. All rights reserved.
//

#import "ContinentMapGenerator.h"

@implementation ContinentMapGenerator


- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (Map*) createMapWithWidth:(int)width andHeight:(int)height withNumberOfTerritories:(int) numberOfTerritories
{
    Map* map = [super createMapWithWidth:width andHeight:height withNumberOfTerritories:numberOfTerritories];
    
    if (map == nil)
    {
        return nil;
    }
    
    //Check to see if we have at least two continents
    NSMutableArray* continents = [self findContinentsInMap:map];
    
    //There must be atleast two continents and
    int numberOfContinents = [continents count];
    if (numberOfContinents < 2 || numberOfContinents > 5)
    {
        return nil;
    }
    
    //Order the continents by the number of territories in them (least to most)
    NSArray *sortedContinents = [continents sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSNumber* continentASize = [NSNumber numberWithInt:[(NSMutableSet*)a count]];
        NSNumber* continentBSize = [NSNumber numberWithInt:[(NSMutableSet*)b count]];
        return [continentASize compare:continentBSize];
    }];
    
    //Connect the continents by joining close territories to each other
    [self joinContinents:sortedContinents];
    
    return map;
}

+(NSMutableArray*)findContinentsInMap:(Map*)map
{
    //Get all the territories and start with one
    NSMutableSet* territories = [NSMutableSet setWithSet:[map territories]];
    
    //Create the array the will hold the sets of territories that are continents
    NSMutableArray* continents = [[[NSMutableArray alloc] init] autorelease];
    
    while ([territories count] != 0)
    {
        //Get the next territory to start with
        TerritoryElement* nextTerritory = [territories anyObject];
        [territories removeObject:nextTerritory];
        
        //Next continent
        NSMutableSet* continent = [NSMutableSet setWithObject:nextTerritory];
        [continents addObject:continent];
        
        //Find the connected neighbors of this territory to create a continent
        [self getContinentFromTerritory:nextTerritory withUnvisitedTerritories:territories currentContinent:continent];
    }

    return continents;
}

//Creates a continent by starting at a given territory
+(void)getContinentFromTerritory:(TerritoryElement*)currentTerritory withUnvisitedTerritories:(NSMutableSet*)remainingTerritories currentContinent:(NSMutableSet*)continent
{
    for (TerritoryElement* territory in [currentTerritory borders])
    {
        if ([remainingTerritories containsObject:territory])
        {
            [continent addObject:territory];
            [remainingTerritories removeObject:territory];
            [self getContinentFromTerritory:territory withUnvisitedTerritories:remainingTerritories currentContinent:continent];
        }
    }
}

//Joins continents to each other so players can actually attack other continents
//This methods assumes the the continents in the NSArray are sorted from smallest to largest
+(void)joinContinents:(NSArray*)sortedContinents
{
    int numberOfContinents = [sortedContinents count];
    
    //This is used to keep track of the number of mapped territories for each continent
    NSMutableArray* mappedTerritories = [[[NSMutableArray alloc] initWithCapacity:numberOfContinents] autorelease];
    
    //For each territory in a continent, find the closest territory in each other continent
    for (int i = 0; i < numberOfContinents; i++)
    {
        //Get the territories for this continent
        NSMutableSet* territories = [sortedContinents objectAtIndex:i];
        
        //Initialize the mapped territory array
        NSMutableArray* mappedTerritoriesForContinent = [[[NSMutableArray alloc] init] autorelease];
        [mappedTerritories addObject:mappedTerritoriesForContinent];
        
        //Find the closest territory on another continent for each territory
        for (TerritoryElement* territory in territories)
        {
            NSDictionary* matchingTerritory = [self findClosestTerritoryToTerritory:territory withMapContinents:sortedContinents skippingContinentAtIndex:i mappedTerritories:mappedTerritories];
            
            //Create a new dictionary with the original territory and matching territory
            NSDictionary* matchedTerritories = [NSMutableDictionary dictionaryWithDictionary:matchingTerritory];
            [matchedTerritories setValue:territory forKey:@"territory"];
            
            [mappedTerritoriesForContinent addObject:matchedTerritories];
        }
    }
    
    //Use the mappings join continents using the sortest distance
    for (int i = 0; i < numberOfContinents; i++)
    {
        //Get the mapped territories
        NSMutableArray* mappedTerritoriesForContinent = [mappedTerritories objectAtIndex:i];
        
        //Sort by distance so we map by smallest distance
        NSArray *sortedTerritories = [mappedTerritoriesForContinent sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSNumber* distanceA = [NSNumber numberWithInt:[[(NSDictionary*)a objectForKey:@"distance"] floatValue]];
            NSNumber* distanceB = [NSNumber numberWithInt:[[(NSDictionary*)b objectForKey:@"distance"] floatValue]];
            return [distanceA compare:distanceB];
        }];
        
        //Get the first two from the sorted list and make them neighbors
        for (NSMutableDictionary* mappedTerritories in [sortedTerritories subarrayWithRange:NSMakeRange(0, min([sortedTerritories count], 2))])
        {
            //For each mapping add the territories as borders
            TerritoryElement* first = [mappedTerritories objectForKey:@"territory"];
            TerritoryElement* second = [mappedTerritories objectForKey:@"matchedTerritory"];
            
            [[first borders] addObject:second];
            [[second borders] addObject:first];
        }
    }
}

+(NSDictionary*)findClosestTerritoryToTerritory:(TerritoryElement*)territory withMapContinents:(NSArray*)continents skippingContinentAtIndex:(int)continentIndex mappedTerritories:(NSArray*)mappedTerritories
{
    //Variables needed to track which is the best match
    TerritoryElement* mappedTerritory = nil;
    int continentTerritoryBelongsTo = -1;
    CGFloat currentDistance = CGFLOAT_MAX;
    
    //Get the label location of the current territory
    CGPoint labelLocation = [territory labelLocation];
    
    //Loop through the other continents and find the closest other territory using the label location
    for (int i = 0; i < [continents count]; i++)
    {
        //Skip the current continent
        if (i != continentIndex)
        {
            NSMutableSet* continentTerritories = [continents objectAtIndex:i];
            
            for (TerritoryElement* continentTerritory in continentTerritories)
            {
                CGPoint continentTerritoryLabelLocation = [continentTerritory labelLocation];
                CGFloat distance = [self distanceBetweenPoint:labelLocation pointB:continentTerritoryLabelLocation];
                
                if (distance < currentDistance)
                {
                    mappedTerritory = continentTerritory;
                    currentDistance = distance;
                    continentTerritoryBelongsTo = i;
                }
            }
        }
    }
    
    //Now we have a match so bundle it in a pretty dicitonary so we know the details
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:currentDistance], @"distance", mappedTerritory, @"matchedTerritory", [NSNumber numberWithInt:continentTerritoryBelongsTo], @"continent", nil];
}

//This does not use the square root because we are just comparing
+(CGFloat)distanceBetweenPoint:(CGPoint)p1 pointB:(CGPoint)p2
{
    CGFloat xDist = (p2.x - p1.x);
    CGFloat yDist = (p2.y - p1.y);
    return (xDist * xDist) + (yDist * yDist);
}

@end
