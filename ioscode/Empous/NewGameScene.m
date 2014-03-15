
//
//  NewGameScene.m
//  Empous
//
//  Created by Ryan Hurley on 1/16/12.
//  Copyright 2012 Apple. All rights reserved.
//

#import "NewGameScene.h"
#import "MainMenuScene.h"
#import "MapGenerator.h"
#import "Map.h"
#import "TMXGenerator.h"
#import "GameScene.h"
#import "GameMode.h"
#import "EmpousAPIWrapper.h"
#import <TargetConditionals.h>
#import "ClippingNode.h"
#import "SimpleAudioEngine.h"
#import "Tools.h"

#import "ScrollMenu.h"
#import "FacebookWrapper.h"

CCSprite* background;
int attemptsToFindRandomFriend = 0;
const int MAX_RANDOM_MATCHMAKING_ATTEMPTS = 5;

@implementation NewGameScene
{
    CCLayer* inviteUserModal;
    UITextField* empousUsernameField;
    CCButton* overlay;
}

+(id)nodeWasPushed:(BOOL)wasPushed
{
    return [[[self alloc]initWasPushed:wasPushed] autorelease];
}

- (id)initWasPushed:(BOOL)wasPushed
{
    self = [super init];
    if (self) {
        friendLabels = [[NSMutableArray alloc] initWithCapacity:3];
        friendRemoveLabels = [[NSMutableArray alloc] initWithCapacity:3];
        friendsForFriendLabels = [[NSMutableDictionary alloc]initWithCapacity:3];
        menuNameToFriendData = [[NSMutableDictionary alloc] init];
        friendChoosers = [[NSMutableArray alloc]initWithCapacity:3];
        [self setTouchEnabled:YES];
        [self addUIElements:wasPushed];
        
        spinner = [CCLoadingOverlay nodeWithMessage:@"Loading Friends" withFont:@"Armalite Rifle"];
        [self addChild:spinner z:10];
    }
    return self;
}

-(void)dealloc
{
    [friendLabels release];
    [friendRemoveLabels release];
    [friendsForFriendLabels release];
    [menuNameToFriendData release];
    [friendChoosers release];
    
    [super dealloc];
}

- (void)onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];
    [self schedule:@selector(loadFriends)];
}

-(void)onExit
{
    if (empousUsernameField)
    {
        [empousUsernameField removeFromSuperview];
    }
    [super onExit];
}

-(void)loadFriends
{
    [self unschedule:@selector(loadFriends)];
    //Handle facebook delegate for menu items
    
    //Get friends from Empous server
    [[EmpousAPIWrapper sharedEmpousAPIWrapper]setDelegate:self];
    [[EmpousAPIWrapper sharedEmpousAPIWrapper] getFriends];
}

-(void) addUIElements:(BOOL)wasPushed
{
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    //Add the Sprite for the background
    background = [CCSprite spriteWithFile: @"Empous-Background.png"];
    background.position = ccp(center.x, 160);
    [self addChild:background];
    
    //Add the bottom bar with play button
    BottomBar* bottomBar = [BottomBar nodeWithPlayButton:YES andDelegate:self withPush:wasPushed];
    [self addChild:bottomBar];
    
    //Menu for Friends
    menu = [[ScrollMenu alloc]initWithCGRectBoundsAndDelegate:ccp(3*winSize.width/4,178) withHeight:291 withWidth:winSize.width/2 andDelegate:self];
    [self addChild:menu z:1];
    
    //Adjust buttons
    [self adjustExtraButtons];
    
    //Help Text at Bottom
    CCLabelTTF* bottomText = [CCLabelTTF labelWithString:@"Create a game by selecting friends" fontName:@"Armalite Rifle" fontSize:16];
    [bottomText setPosition:ccp(center.x,16)];
    [self addChild:bottomText];
        
    //Add the friend choosers and all appropriate
    int labelPosition = 345;
    for(int i = 0; i < 3; i++)
    {
        labelPosition -=60;
        
        //Friend chooser sprite
        CCSprite* friendChooser = [CCSprite spriteWithFile:@"Chosen-Friend.png"];
        friendChooser.position = ccp(winSize.width/4,labelPosition);
        if (winSize.width == 568)
        {
            [friendChooser setScaleX:1.4];
        }
        [friendChoosers insertObject:friendChooser atIndex:i];
        [self addChild:friendChooser];
        
        //Add the clipping layer
        ClippingNode* friendChooserClipping = [ClippingNode node];
        CGRect friendBoundingBox = [friendChooser boundingBox];
        friendBoundingBox.size.width = friendBoundingBox.size.width - 20;
        [friendChooserClipping setClippingRegion:friendBoundingBox];
        [self addChild:friendChooserClipping];
        
        //Place the player label
        CCLabelTTF* label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Player %d", i+1] fontName:@"Helvetica Neue" fontSize:22];
        label.color = ccGRAY;
        label.position = ccp(65, labelPosition);
        label.anchorPoint = ccp(0,.5);
        [friendLabels insertObject:label atIndex:i];
        [friendChooserClipping addChild:label];
        
        //Add the remove label
        CCLabelTTF* friendRemoveLabel = [CCLabelTTF labelWithString:@" " fontName:@"Armalite Rifle" fontSize:20];
        [friendRemoveLabel setPosition:ccp(46,labelPosition)];
        if (winSize.width == 568)
        {
            [friendRemoveLabel setPosition:ccp(38,labelPosition)];
        }
        [friendRemoveLabel setColor:ccGRAY];
        [friendRemoveLabels insertObject:friendRemoveLabel atIndex:i];
        [self addChild:friendRemoveLabel];
    }
}

-(void)adjustExtraButtons
{
    CCArray* children = [self children];
    
    if([children containsObject:facebookInviteButton])
    {
        [self removeChild:facebookInviteButton];
    }
    
    if([children containsObject:randomInviteButton])
    {
        [self removeChild:randomInviteButton];
    }
    
    if([children containsObject:disableMatchmaking])
    {
        [self removeChild:disableMatchmaking];
    }
    
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    //Check to see if matchmaking is enabled
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL matchmakingEnabled = [defaults boolForKey:@"matchmakingAllowed"];
    
    int height = 100;
    if (matchmakingEnabled)
    {
        height = 113;
    }
    
    //Facebook Invite Button
    facebookInviteButton = [CCButton spriteWithFile:@"Invite.png" withPressedFile:@"Invite-Pressed.png" target:self function:@selector(inviteFriends) sound:@"button.mp3"];
    [facebookInviteButton setScale:1];
    [facebookInviteButton setPosition:ccp(winSize.width/4, height)];
    [self addChild:facebookInviteButton];
    
    height -= 30;
    
    randomInviteButton = [CCButton spriteWithFile:@"Random-Player.png" withPressedFile:@"Random-Player-Pressed.png" target:self function:@selector(findRandomFriendPrompt)];
    [randomInviteButton setPosition:ccp(winSize.width/4, height)];
    [self addChild:randomInviteButton];
    
    height -= 30;
    
    if(matchmakingEnabled)
    {
        disableMatchmaking = [CCButton spriteWithFile:@"Disable-Random.png" withPressedFile:@"Disable-Random-Pressed.png" target:self function:@selector(disableMatchmaking)];
        [disableMatchmaking setPosition:ccp(winSize.width/4, height)];
        [disableMatchmaking setScale:.65];
        [self addChild:disableMatchmaking];
    }
}

-(void)findRandomFriendPrompt
{
    attemptsToFindRandomFriend = 0;
    //Check to see if any of the friend choosers are available
    int nextPlayerIndex = [self indexOfFirstAvailableFriendChooser];
    if (nextPlayerIndex != -1)
    {
        //Check to see if we have alerted the player about random matches
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL matchmakingEnabled = [defaults boolForKey:@"matchmakingAllowed"];
        if (!matchmakingEnabled)
        {
            //Show alert to invite friends
            UIAlertView* dialog = [[UIAlertView alloc] init];
            [dialog setDelegate:self];
            [dialog setTag:1];
            [dialog setTitle:@"Empous Matchmaking"];
            [dialog setMessage:@"Empous can find you a random user to play with. By saying yes, you also allow others to play with you in random games. Do you want Empous to find you someone to play with?"];
            [dialog addButtonWithTitle:@"No"];
            [dialog addButtonWithTitle:@"Yes"];
            [dialog show];
            [dialog release];
        }
        //Find a friend
        else
        {
            [self findRandomFriend];
        }
    }
}

-(void)findRandomFriend
{
    spinner = [CCLoadingOverlay nodeWithMessage:@"Finding a random opponent..." withFont:@"Armalite Rifle"];
    [self addChild:spinner z:10];
    
    //Ask the server for a random friend
    attemptsToFindRandomFriend++;
    [[EmpousAPIWrapper sharedEmpousAPIWrapper] setDelegate:self];
    [[EmpousAPIWrapper sharedEmpousAPIWrapper] findRandomPlayer];
}

-(void)foundRandomPlayer:(NSDictionary *)player
{
    [self removeChild:spinner];

    NSString* playerFirstName = [player objectForKey:@"first_name"];
    NSString* playerLastName = [player objectForKey:@"last_name"];
    NSString* username = [player objectForKey:@"username"];
    NSString* name = [NSString stringWithFormat:@"%@ %@ (%@)", playerFirstName, playerLastName, username];
    
    //Check to see if the player is already in the list of assigned players
    BOOL playerAlreadyAssigned = NO;
    for(int i = 0; i < 3; i++){
        CCLabelTTF* friendLabel = [friendLabels objectAtIndex:i];
        if([[friendLabel string] isEqualToString:name]){
            playerAlreadyAssigned = YES;
            break;
        }
    }
    
    // Then try to get another name if we haven't exceeded our attempt limit
    if (playerAlreadyAssigned)
    {
        attemptsToFindRandomFriend++;
        if (attemptsToFindRandomFriend < MAX_RANDOM_MATCHMAKING_ATTEMPTS)
        {
            [self findRandomFriend];
        }
        else
        {
            [self noRandomPlayersAvailable];
        }
    }
    
    //Assign the random player to the menu
    else
    {
        int nextPlayerIndex = [self indexOfFirstAvailableFriendChooser];
        if (nextPlayerIndex != -1)
        {
            CCLabelTTF* friendLabel = [friendLabels objectAtIndex:nextPlayerIndex];
            [friendLabel setString:name];
            
 
            [friendsForFriendLabels setValue:player forKey:name];
            [friendLabel setColor:ccWHITE];
            
            [[friendRemoveLabels objectAtIndex:nextPlayerIndex] setString:@"X"];
        }
    }
}

-(void)disableMatchmaking
{
    //Show an alert warning them
    UIAlertView* dialog = [[UIAlertView alloc] init];
    [dialog setDelegate:self];
    [dialog setTitle:@"Disable Random Games"];
    [dialog setMessage:@"By tapping yes, no one will be able to create random games with you. Are you sure you want to remove yourself from future random games?"];
    [dialog addButtonWithTitle:@"No"];
    [dialog addButtonWithTitle:@"Yes"];
    [dialog setTag:2];
    [dialog show];
    [dialog release];
    
}

-(void)noRandomPlayersAvailable
{
    [self removeChild:spinner];
    
    //Too bad, show error message
    UIAlertView* dialog = [[UIAlertView alloc] init];
    [dialog setDelegate:self];
    [dialog setTitle:@"Could Not Find a Match"];
    [dialog setMessage:@"Empous could not find a match at this time. Try again later."];
    [dialog addButtonWithTitle:@"Ok"];
    [dialog show];
    [dialog release];
}

-(void)loadMainMenu
{
    [[CCDirector sharedDirector] replaceScene:
     [CCTransitionFade transitionWithDuration:0.5f scene:[MainMenuScene node]]];
}

//Called when friends list is returned when the menu is first loaded
-(void)friendsWithApp:(NSString*)invitedUser
{
    [self removeChild:spinner cleanup:YES];
    [self redrawMenu];
    if (invitedUser != nil)
    {
        [self menuItemTouched:invitedUser];
    }
    
    //Check to see if the player knows about continents!
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL shownContinentNotice = [defaults boolForKey:@"shownContinentNotice"];
    if (!shownContinentNotice)
    {
        //Tell them about it!
        UIAlertView* dialog = [[UIAlertView alloc] init];
        [dialog setDelegate:self];
        [dialog setTitle:@"Continent Conquest"];
        [dialog setMessage:@"Empous now supports maps with continents. Your friends who can play 'Continent Conquest' will have a 'C' next to their name. If you select only friends who are eligble, then you will be able to select 'Continent Conquest' or 'Empous Classic' when you hit Play. Otherwise, you will be forced to play 'Empous Classic'"];
        [dialog addButtonWithTitle:@"Ok"];
        [dialog show];
        [dialog release];
        
        [defaults setBool:YES forKey:@"shownContinentNotice"];
    }
}

-(void)redrawMenu
{
    //Clear out the menu
    [menu clearMenu];
    
    [menuNameToFriendData release];
    menuNameToFriendData = [[NSMutableDictionary alloc]init];
    
    NSMutableArray* friends = [[EmpousAPIWrapper sharedEmpousAPIWrapper] friends];
    if ([friends count] == 0)
    {
        //Display the invite friends text
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp(winSize.width/2,winSize.height/2);
        
        noFriendsText = [CCSprite spriteWithFile:@"No-Friends-Menu.png"];
        [noFriendsText setPosition:ccp(3*winSize.width/4,center.y)];
        [self addChild:noFriendsText z:2];
        return;
    }
    
    //There are friends so remove the no friends text
    if (noFriendsText != nil)
    {
        [self removeChild:noFriendsText];
        noFriendsText = nil;
    }
    
    for(NSMutableDictionary* empousFriend in friends){
        
        //Get the name of the facebook friend
        NSString* menuName = [NSString stringWithFormat:@"%@ %@ (%@)", [empousFriend objectForKey:@"first_name"], [empousFriend objectForKey:@"last_name"], [empousFriend objectForKey:@"username"]];
               
        //Add the friend to the dictionary for use later
        [menuNameToFriendData setObject:empousFriend forKey:menuName];
        [menu addItem:menuName doesSupportContinents:[[empousFriend objectForKey:@"can_play_with_continents"] boolValue]];
        
        //Disable the button menu item if they can't play a game
        if (![[empousFriend objectForKey:@"can_play_more"] boolValue])
        {
            [menu disableItemForNoMoreGames:menuName];
        }
        
        if(nil != [friendsForFriendLabels objectForKey:menuName])
        {
            [menu disableItem:menuName];
        }
    }
}
         
-(void) registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:2 swallowsTouches:YES];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    //Translate into COCOA coordinates
    CGPoint touchLocation = [touch locationInView: [touch view]];	
    touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    
    for(int i = 0; i < [friendChoosers count]; i++){
        CCSprite* friendChooser = [friendChoosers objectAtIndex:i];
        if(CGRectContainsPoint([friendChooser boundingBox], touchLocation)){
            return YES;
        }
    }
	return NO;
}

//For now we can assume that the next button has been pressed
-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView: [touch view]];	
    touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];


    for(int i = 0; i < [friendChoosers count]; i++){
        CCSprite* friendChooser = [friendChoosers objectAtIndex:i]; 
        CCLabelTTF* disableX = [friendRemoveLabels objectAtIndex:i];
        if(disableX != nil){
            if(CGRectContainsPoint([friendChooser boundingBox], touchLocation)){
                [self removeFriendAtIndex:i];
            }
        }
    }
}

-(void)removeFriendAtIndex:(int)index
{
    //Change the friend name label back
    CCLabelTTF* friendNameLabel = [friendLabels objectAtIndex:index];
    NSString* friendName = [[friendNameLabel string] copy];
    [friendNameLabel setColor:ccGRAY];
    [friendNameLabel setString:[NSString stringWithFormat:@"Player %d", index + 1]];
    
    //Remove the x label
    [[friendRemoveLabels objectAtIndex:index]setString:@" "];
    
    //Renable the menu option
    [menu enableItem:friendName];
    [friendName release];
}
         
- (void)handleReturnToMain
{
    [[CCDirector sharedDirector] replaceScene:
	 [CCTransitionFade transitionWithDuration:0.5f scene:[MainMenuScene node]]];
}

-(void)playButtonTouched
{
    [self promptIfEligibleForContinentConquest];
}

-(void)inviteFriends
{
    //Show a prompt for an Empous Username
    if(inviteUserModal == nil)
    {
        [menu setTouchEnabled:NO];
        
        //Get screensize
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp(winSize.width/2,winSize.height/2);
        
        //Create overlay
        overlay = [CCButton spriteWithFile:@"Notification.png" withPressedFile:@"Notification.png" target:self function:@selector(closeInviteModal)];
        overlay.scaleX = CC_CONTENT_SCALE_FACTOR() * winSize.width;
        overlay.scaleY = CC_CONTENT_SCALE_FACTOR() * winSize.height;
        overlay.position = center;
        [self addChild:overlay z:2];
        
        inviteUserModal = [CCLayer node];
        [self addChild:inviteUserModal z:3];

        CCButton* modalbox = [CCButton spriteWithFile:@"Confirm-Box.png"];
        [modalbox setPosition:center];
        [modalbox setScaleY:.45];
        [inviteUserModal addChild:modalbox];
        
        CCButton* closeButton = [CCButton spriteWithFile:@"CloseX.png" withPressedFile:@"CloseX-Pressed.png" target:self function:@selector(closeInviteModal) sound:@"button.mp3"];
        [closeButton setPosition:ccp(center.x + 185,210)];
        [inviteUserModal addChild:closeButton];
        
        //Add the text field
        empousUsernameField = [[UITextField alloc] initWithFrame: CGRectMake((center.x - 150), 130, 300, 35)];
        
        // NOTE: UITextField won't be visible by default without setting backGroundColor & borderStyle
        empousUsernameField.backgroundColor = [UIColor colorWithRed:.23 green:.39 blue:.23 alpha:1.0];
        empousUsernameField.textColor = [UIColor whiteColor];
        empousUsernameField.borderStyle = UITextBorderStyleRoundedRect;
        empousUsernameField.font = [UIFont fontWithName:@"Helvetica" size:24];
        empousUsernameField.placeholder = @"Username or Email";
        
        empousUsernameField.delegate = self; // set this layer as the UITextFieldDelegate
        empousUsernameField.returnKeyType = UIReturnKeyDone; // add the 'done' key to the keyboard
        empousUsernameField.autocorrectionType = UITextAutocorrectionTypeNo; // switch of auto correction
        empousUsernameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        
        // add the textField to the main game openGLVview
        [[[CCDirector sharedDirector] view] addSubview: empousUsernameField];

        CCButton* invitePlayer = [CCButton spriteWithFile:@"Invite.png" withPressedFile:@"Invite-Pressed.png" target:self function:@selector(addPlayer) sound:@"button.mp3"];
        [invitePlayer setPosition:ccp(center.x, 135)];
        [inviteUserModal addChild:invitePlayer];
    }
}

-(void)closeInviteModal
{
    if(inviteUserModal != nil){
        [self removeChild:overlay cleanup:YES];
        
        [self removeChild:inviteUserModal cleanup:YES];
        inviteUserModal = nil;
        
        [empousUsernameField removeFromSuperview];
        [menu setTouchEnabled:YES];
    }
}

-(void)addPlayer
{
    //Get the username and see if its an Empous user
    NSString* username = [empousUsernameField text];
    [[EmpousAPIWrapper sharedEmpousAPIWrapper] setDelegate:self];
    
    if([[EmpousAPIWrapper sharedEmpousAPIWrapper] inviteUserToGame:username])
    {
        //The menu should automatically be reloaded by the delegate call
        [self closeInviteModal];
    }
    else
    {
        if([inviteUserModal getChildByTag:0] == nil)
        {
            //Get screensize
            CGSize winSize = [[CCDirector sharedDirector] winSize];
            CGPoint center = ccp(winSize.width/2,winSize.height/2);
            
            //Show an error message
            CCLabelTTF* errorMessage = [CCLabelTTF labelWithString:@"No User exists with the username or email" fontName:@"Armalite Rifle" fontSize:12];
            [errorMessage setPosition:ccp(center.x, 198)];
            [errorMessage setColor:ccRED];
            [inviteUserModal addChild:errorMessage z:0 tag:0];
        }
    }
}

-(void)promptIfEligibleForContinentConquest
{
    BOOL continentEligible = YES;
    
    for(CCLabelTTF* friend in friendLabels)
    {
        NSMutableDictionary* friendDict = [friendsForFriendLabels objectForKey:[friend string]];
        if (friendDict != nil && ![[friendDict objectForKey:@"can_play_with_continents"] boolValue])
        {
            continentEligible = NO;
            break;
        }
    }
    
    if (continentEligible)
    {
        //Ask if they want to play
        UIAlertView* dialog = [[UIAlertView alloc] init];
        [dialog setDelegate:self];
        [dialog setTitle:@"Select A Game Type"];
        [dialog setMessage:@"Empous now has two game types. You can still play 'Empous Classic' or the new type called 'Continent Conquest'. Which would you like to play?"];
        [dialog addButtonWithTitle:@"Classic"];
        [dialog addButtonWithTitle:@"Continents"];
        [dialog setTag:3];
        [dialog show];
        [dialog release];
        
        return;
    }
    
    [self createMap:NO];
    
}

/**
 * Called when the game should be created
 */
- (void) createMap:(BOOL)playingWithContinents
{
    //Create a player for this player
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int empousId = [[defaults objectForKey:@"empous_id"] intValue];
    NSString* name = [defaults objectForKey:@"first_name"];
    Player* creatingPlayer = [[[Player alloc]initWithEmpousId:empousId playerName:name] autorelease];
    
    //Create an Array of enemy players
    NSMutableArray* enemyPlayers = [[[NSMutableArray alloc]initWithCapacity:[friendLabels count]] autorelease];
    
    //Go through the dictionary 
    for(CCLabelTTF* friend in friendLabels)
    {
        //We can invite all the users since the invite Empous users will
        NSMutableDictionary* friendDict = [friendsForFriendLabels objectForKey:[friend string]];
        if(friendDict != nil){
            //Use the information from the label to create a empous user, or find one
            int empousId = [[friendDict valueForKey:@"empous_id"]intValue];
            NSString* first_name = [friendDict valueForKey:@"first_name"];
            Player* enemy = [[Player alloc] initWithEmpousId:empousId playerName:first_name];
            [enemyPlayers addObject:enemy];
            [enemy release];
        }
    }
    
    if([enemyPlayers count] == 0)
    {
        UIAlertView* dialog = [[UIAlertView alloc] init];
        [dialog setDelegate:self];
        [dialog setTitle:@"Not Enough Players"];
        [dialog setMessage:@"You must have at least one enemy."];
        [dialog addButtonWithTitle:@"Ok"];
        [dialog show];
        [dialog release];
    }
    else
    {
        //Create a new GameScene with the creatingPlayer and enemyPlayers
        [[CCDirector sharedDirector] replaceScene:
         [CCTransitionFade transitionWithDuration:0.5f scene:
          (CCScene*)[[[GameScene alloc]initWithPlayer:creatingPlayer withEnemies:enemyPlayers andMode:[GameMode class] withContinents:(BOOL)playingWithContinents]autorelease]]];
    }
}

/**
 * Tries to assign the touched friend to a label
 */
-(void)menuItemTouched:(NSString*)menuItemText
{
    int nextPlayerIndex = [self indexOfFirstAvailableFriendChooser];
    if (nextPlayerIndex != -1)
    {
        CCLabelTTF* friendLabel = [friendLabels objectAtIndex:nextPlayerIndex];
        [friendLabel setString:menuItemText];
        
        //Look up the facebook information
        NSMutableDictionary* facebookData = [menuNameToFriendData objectForKey:menuItemText];
        
        [friendsForFriendLabels setValue:facebookData forKey:menuItemText];
        [friendLabel setColor:ccWHITE];
        
        [[friendRemoveLabels objectAtIndex:nextPlayerIndex] setString:@"X"];
        
        [menu disableItem:menuItemText];
    }
}

/**
 * Gets the index of the first friend chooser without an assigned player
 * or -1 if there isn't one available.
 */
-(int)indexOfFirstAvailableFriendChooser
{
    for(int i = 0; i < 3; i++){
        CCLabelTTF* friendLabel = [friendLabels objectAtIndex:i];
        if([[friendLabel string] hasPrefix:@"Player"]){
            return i;
        }
    }
    return -1;
}

/**
 The centering effect is accomplished by sliding the whole UIView up
 */
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //Get the y location of the center of the text field
    double centerYOfField = textField.frame.origin.y - (textField.frame.size.height/2);
    
    //Translate to cocos2d coordinates (0,0 is the top left of Apple coordinates).
    double centerYOfFieldCocos = 320 - centerYOfField;
    
    //This is the distance we need to move the UIView
    double moveDistance = (4*320/5) - centerYOfFieldCocos;
    
    if(moveDistance > 0)
    {
        //Perform the move animation
        UIView* cocosView = [[CCDirector sharedDirector] view];
        [UIView beginAnimations: @"anim" context: nil];
        [UIView setAnimationBeginsFromCurrentState: YES];
        [UIView setAnimationDuration: .2f];
        cocosView.frame = CGRectOffset(cocosView.frame, 0, -moveDistance);
        [UIView commitAnimations];
    }
}

/**
 Slide the UIView back down to (0,0)
 */
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    UIView* cocosView = [[CCDirector sharedDirector] view];
    
    //Get the current location of the UIView and determine how far off it is from the origin
    double moveDistance = 0 - cocosView.frame.origin.y;
    
    //Slide it back down
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: .2f];
    cocosView.frame = CGRectOffset(cocosView.frame, 0, moveDistance);
    [UIView commitAnimations];
}

/**
 Resigns the keyboard when the 'Done' key is pressed
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([alert tag] == 1)
    {
        //Mark that the user was prompted
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        //If the index was 1, then random matchmaking is a go
        if (buttonIndex == 1)
        {
            [defaults setBool:YES forKey:@"matchmakingAllowed"];
            
            //Enable matchmaking
            [[EmpousAPIWrapper sharedEmpousAPIWrapper] changeMatchmakingSettingForPlayer:YES];
            
            //Adjust buttons
            [self adjustExtraButtons];
            
            //Send request to server saying this user allows for matchmaking
            [self findRandomFriend];
        }
        else
        {
            [defaults setBool:NO forKey:@"matchmakingAllowed"];
        }
        [defaults synchronize];
    }
    else if([alert tag] == 2)
    {
        //Mark that the user was prompted
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        //If the index was 1, then random matchmaking is a no
        if (buttonIndex == 1)
        {
            [defaults setBool:NO forKey:@"matchmakingAllowed"];
            
            //Enable matchmaking
            [[EmpousAPIWrapper sharedEmpousAPIWrapper] changeMatchmakingSettingForPlayer:NO];
            
            //Adjust buttons
            [self adjustExtraButtons];
        }
        [defaults synchronize];
    }
    else if([alert tag] == 3)
    {
        if (buttonIndex == 0)
        {
            [self createMap:NO];
        }
        else
        {
            [self createMap:YES];
        }
    }
}

@end
