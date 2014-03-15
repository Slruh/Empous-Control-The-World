//
//  MainMenuScene+FacebookAuth.m
//  Empous
//
//  Created by Ryan Personal on 4/29/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "MainMenuScene+FacebookAuth.h"
#import "CCButton.h"
#import "MainMenuScene.h"

@implementation MainMenuScene (FacebookAuth)

/**
 Called when we have an access code for a user and we know they are a user already
 */
-(void)facebookAuthorize
{
    [self removeChild:loginOptions cleanup:YES];
    loginOptions = nil;
    
    //Do this in background because FB auth needs the main thread
    notification = [[NotificationLayer alloc]initWithText:@"Gathering info from Facebook..." andHeight:15];
    [self addChild:notification z:3];
    
    //Facebook will prompt for login if necessary
    FacebookWrapper* facebook = [FacebookWrapper sharedFacebookWrapper];
    [facebook setDelegate:self];
    [facebook authorize];
}

/**
 Sends an access token along with a desired username. If the username isn't taken then it will attempt to create a new facebook user on empous.
 */
-(void)facebookAuthorizeWithUsername
{
    //Hide the text field
    [fbUsernameTextField setHidden:YES];
    overlay = [CCLoadingOverlay nodeWithMessage:@"Creating Account" withFont:@"Armalite Rifle"];
    [self addChild:overlay z:INT_MAX -1];
    
    NSString* desiredUsername = [fbUsernameTextField text];
    
    //Check if the desiredUsername is available
    if([[EmpousAPIWrapper sharedEmpousAPIWrapper] checkIfUsernameAvailable:desiredUsername])
    {
        //Facebook will prompt for login if necessary
        FacebookWrapper* facebook = [FacebookWrapper sharedFacebookWrapper];
        [facebook setDelegate:self];
        [facebook authorizeWithUsername:desiredUsername];
    }
    else
    {
        [fbUsernameTextField setHidden:NO];
        [self removeChild:overlay cleanup:YES];
        
        if([fbUsernameModel getChildByTag:0] == nil)
        {
            //Get screensize
            CGSize winSize = [[CCDirector sharedDirector] winSize];
            CGPoint center = ccp(winSize.width/2,winSize.height/2);
            
            //Display an error so the user can retry to enter a username.
            CCLabelTTF* errorMessage = [CCLabelTTF labelWithString:@"Username already taken" fontName:@"Armalite Rifle" fontSize:12];
            [errorMessage setPosition:ccp(center.x, 126)];
            [errorMessage setColor:ccRED];
            [fbUsernameModel addChild:errorMessage z:0 tag:0];
        }
    }
}

//Can mean that Facebook login failed or Empous login failed
-(void)fbUserLoggedIn
{
    //Record that facebook is the preferred login method
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"facebook" forKey:@"login"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self loginSuccess];
}

//Can mean that Facebook login failed or Empous login failed
-(void)fbUserLogInFailed:(NSString*)message
{
    NSLog(@"Login Failed");
    [self backToLoginOptions];
    
    [self removeChild:notification cleanup:YES];

    UIAlertView* dialog = [[UIAlertView alloc] init];
    [dialog setDelegate:self];
    [dialog setTitle:@"Error With Login"];
    [dialog setMessage:message];
    [dialog addButtonWithTitle:@"Ok"];
    [dialog show];
    [dialog release];
}

/**
 Shows a modal dialog to get a username for user creation.
 */
-(void)fbuserLoginFailedNeedUsername
{
    [self removeChild:notification cleanup:YES];
    
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    //Create overlay
    modalOverlay = [CCButton spriteWithFile:@"Notification.png" withPressedFile:@"Notification.png" target:self function:@selector(backToLoginOptions)];
    modalOverlay.scaleX = CC_CONTENT_SCALE_FACTOR() * winSize.width;
    modalOverlay.scaleY = CC_CONTENT_SCALE_FACTOR() * winSize.height;
    modalOverlay.position = center;
    [self addChild:modalOverlay z:2];
    
    fbUsernameModel = [CCLayer node];
    CCButton* modelBackground = [CCButton spriteWithFile:@"Confirm-Box.png"];
    [modelBackground setPosition:center];
    [modelBackground setScaleY:.75];
    [fbUsernameModel addChild:modelBackground];
    
    CCButton* closeButton = [CCButton spriteWithFile:@"CloseX.png" withPressedFile:@"CloseX-Pressed.png" target:self function:@selector(backToLoginOptions) sound:@"button.mp3"];
    [closeButton setPosition:ccp(center.x + 184,238)];
    [fbUsernameModel addChild:closeButton];
    
    CCLabelTTF* message = [CCLabelTTF labelWithString:@"Supply a username" fontName:@"Armalite Rifle" fontSize:24];
    [message setPosition:ccp(center.x, 215)];
    [fbUsernameModel addChild:message];
    
    CCLabelTTF* subMessage = [CCLabelTTF labelWithString:@"It is used to find other players" fontName:@"Armalite Rifle" fontSize:20];
    [subMessage setPosition:ccp(center.x, 190)];
    [fbUsernameModel addChild:subMessage];
    
    CCButton* createAccount = [CCButton spriteWithFile:@"CreateAccount.png" withPressedFile:@"CreateAccount-Pressed.png" target:self function:@selector(facebookAuthorizeWithUsername) sound:@"button.mp3"];
    [createAccount setPosition:ccp(center.x, 103)];
    [fbUsernameModel addChild:createAccount];
    
    //Add the text field
    fbUsernameTextField = [[UITextField alloc] initWithFrame: CGRectMake((center.x - 150), 152, 300, 35)];
    
    // NOTE: UITextField won't be visible by default without setting backGroundColor & borderStyle
    fbUsernameTextField.backgroundColor = [UIColor colorWithRed:.23 green:.39 blue:.23 alpha:1.0];
    fbUsernameTextField.textColor = [UIColor whiteColor];
    fbUsernameTextField.borderStyle = UITextBorderStyleRoundedRect;
    fbUsernameTextField.font = [UIFont fontWithName:@"Helvetica" size:24];
    
    fbUsernameTextField.delegate = self; // set this layer as the UITextFieldDelegate
    fbUsernameTextField.returnKeyType = UIReturnKeyDone; // add the 'done' key to the keyboard
    fbUsernameTextField.autocorrectionType = UITextAutocorrectionTypeNo; // switch of auto correction
    fbUsernameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    // add the textField to the main game openGLVview
    [[[CCDirector sharedDirector] view] addSubview: fbUsernameTextField];
    
    [self addChild:fbUsernameModel z:3];
}

-(void)cleanUpFacebookAuthElements
{
    if(fbUsernameModel != nil)
    {
        [self removeChild:fbUsernameModel cleanup:YES];
    }
    
    [fbUsernameTextField removeFromSuperview];
}

@end
