//
//  MainMenuScene.h
//  Empous
//
//  Created by Ryan Hurley on 1/15/12.
//  Copyright 2012 Apple. All rights reserved.
//

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "NotificationLayer.h"
#import "FacebookWrapper.h"
#import "EmpousAPIWrapper.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "CCFadableLayer.h"
#import "CCTextFieldCentererScene.h"
#import "CCLoadingOverlay.h"
#import "CCButton.h"

typedef enum messageOptions {
    NO_MESSAGE,
    CONNECTION_ERROR,
    OUTDATED_APP
} MessageOption;

@interface MainMenuScene : CCTextFieldCentererScene <FacebookWrapperDelegate, EmpousWrapperDelegate, MFMailComposeViewControllerDelegate, UITextFieldDelegate>
{    
    CCSprite* compass;
    NotificationLayer* notification;
    CCMenu* mainMenu;
    
    CCButton* questionMark;
    
    CCSprite* playableGameBackground;
    CCLabelTTF* playableGames;
    
    UIViewController* emailController;
    MFMailComposeViewController* mailMessage;
    
    CCLabelTTF* noConnection;
    CCLabelTTF* noConnectionHelpText;
    
    CCFadableLayer* loginOptions;
    CCFadableLayer* fbUsernameModel;
    CCFadableLayer* empousLoginModel;
    CCFadableLayer* empousUserCreationModel;
    CCFadableLayer* empousResetPasswordModal;
    
    CCButton* modalOverlay;
    
    //Facebook username field
    UITextField *fbUsernameTextField;
    
    //Empous login fields
    UITextField *empousUsernameField;
    UITextField *empousPasswordField;
    
    //Empous create user fields
    UITextField *empousTokenField;
    UITextField *empousUsernameTextField;
    UITextField *empousPasswordTextField;
    UITextField *empousConfirmPasswordTextField;
    UITextField *empousFirstTextField;
    UITextField *empousLastTextField;
    UITextField *empousEmailField;
    
    CCLoadingOverlay* overlay;
    
    CCLabelTTF* loggedInAs;

    
}

//Attempts to reload the user
-(void)authorize;

//Used when a connection error has occured and Empous can not be contacted
+(id)nodeWithMessage:(MessageOption)message;

-(void)setVolumeIcon;

//Called when a login is successful, shows the main menu.
-(void)loginSuccess;

-(void)backToLoginOptions;


@end
