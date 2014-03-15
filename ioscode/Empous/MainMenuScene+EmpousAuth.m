//
//  MainMenuScene+EmpousAuth.m
//  Empous
//
//  Created by Ryan Personal on 4/29/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "MainMenuScene+EmpousAuth.h"
#import "CCButton.h"
#import "EmpousAPIWrapper.h"
#import "CCLoadingOverlay.h"

@implementation MainMenuScene (EmpousAuth)

-(void)empousAuthorize
{    
    //Try to login using just the token
    BOOL tokenValid = [[EmpousAPIWrapper sharedEmpousAPIWrapper] loginUsingToken];
    if(tokenValid)
    {
        [self playerLoggedIn];
        return;
    }
    else
    {
        if(loginOptions != nil)
        {
            //Fade out the login options and then fade in the empousAuthModel
            id fadeOut = [CCFadeOut actionWithDuration:0.3];
            id loadEmpousOptions = [CCCallFunc actionWithTarget:self selector:@selector(fadeInEmpousLoginOptions)];
            [loginOptions runAction:[CCSequence actions:fadeOut,loadEmpousOptions,nil]];
        }
        else
        {
            [self fadeInEmpousLoginOptions];
        }
    }
}

-(void)fadeInEmpousLoginOptions
{
    //Remove the login options
    [self removeChild:loginOptions cleanup:YES];
    loginOptions = nil;
    
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    empousLoginModel = [CCFadableLayer node];
    
    [self addEmpousLoginTextFields];
    
    CCButton* loginButton = [CCButton spriteWithFile:@"EmpousLogin.png" withPressedFile:@"EmpousLogin-Pressed.png" target:self function:@selector(empousLogin) sound:@"button.mp3"];
    [loginButton setPosition:ccp(center.x, 60)];
    [empousLoginModel addChild:loginButton];
    
    CCButton* backButton = [CCButton spriteWithFile:@"Back-Button.png" withPressedFile:@"Back-Button-Pressed.png" target:self function:@selector(backToLoginOptions) sound:@"button.mp3"];
    [backButton setScale:.7];
    [backButton setPosition:ccp(center.x - 160, 15)];
    [empousLoginModel addChild:backButton];
    
    CCButton* createEmpousButton = [CCButton spriteWithFile:@"CreateNewAccount.png" withPressedFile:@"CreateNewAccount-Pressed.png" target:self function:@selector(showCreateAccountForm) sound:@"button.mp3"];
    [createEmpousButton setScale:.7];
    [createEmpousButton setPosition:ccp(center.x - 50, 15)];
    [empousLoginModel addChild:createEmpousButton];
    
    CCButton* resetPassword = [CCButton spriteWithFile:@"Forgot-Password.png" withPressedFile:@"Forgot-Password-Pressed.png" target:self function:@selector(showPasswordResetForm) sound:@"button.mp3"];
    [resetPassword setScale:.7];
    [resetPassword setPosition:ccp(center.x + 115, 15)];
    [empousLoginModel addChild:resetPassword];
    
    [self addChild:empousLoginModel];
}

-(void)addEmpousLoginTextFields
{
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    //Add the text field
    empousUsernameField = [[UITextField alloc] initWithFrame: CGRectMake((center.x - 150), 160, 300, 35)];
    
    // NOTE: UITextField won't be visible by default without setting backGroundColor & borderStyle
    empousUsernameField.backgroundColor = [UIColor colorWithRed:.27 green:.18 blue:.05 alpha:1.0];
    empousUsernameField.textColor = [UIColor whiteColor];
    empousUsernameField.borderStyle = UITextBorderStyleRoundedRect;
    empousUsernameField.font = [UIFont fontWithName:@"Helvetica" size:24];
    empousUsernameField.placeholder = @"Username or Email";
    empousUsernameField.delegate = self; // set this layer as the UITextFieldDelegate
    empousUsernameField.returnKeyType = UIReturnKeyDone; // add the 'done' key to the keyboard
    empousUsernameField.autocorrectionType = UITextAutocorrectionTypeNo; // switch of auto correction
    empousUsernameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    empousUsernameField.tag = 1;
    empousUsernameField.returnKeyType = UIReturnKeyNext;
    
    // add the textField to the main game openGLVview
    [[[CCDirector sharedDirector] view] addSubview: empousUsernameField];
    
    //Add the text field
    empousPasswordField = [[UITextField alloc] initWithFrame: CGRectMake((center.x - 150), 200, 300, 35)];
    
    // NOTE: UITextField won't be visible by default without setting backGroundColor & borderStyle
    empousPasswordField.backgroundColor = [UIColor colorWithRed:.27 green:.18 blue:.05 alpha:1.0];
    empousPasswordField.textColor = [UIColor whiteColor];
    empousPasswordField.borderStyle = UITextBorderStyleRoundedRect;
    empousPasswordField.font = [UIFont fontWithName:@"Helvetica" size:24];
    empousPasswordField.placeholder = @"Password";
    empousPasswordField.secureTextEntry = YES;
    
    empousPasswordField.delegate = self; // set this layer as the UITextFieldDelegate
    empousPasswordField.returnKeyType = UIReturnKeyDone; // add the 'done' key to the keyboard
    empousPasswordField.autocorrectionType = UITextAutocorrectionTypeNo; // switch of auto correction
    empousPasswordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    empousPasswordField.tag = 2;
    
    // add the textField to the main game openGLVview
    [[[CCDirector sharedDirector] view] addSubview: empousPasswordField];
}

-(void)removeEmpousLoginTextFields
{
    //Need to remove the login UITextFields because of z issues
    [empousUsernameField removeFromSuperview];
    [empousPasswordField removeFromSuperview];
}


-(void)empousLogin
{
    //Get the values from the two fields
    NSString* usernameOrEmail = [empousUsernameField text];
    NSString* password = [empousPasswordField text];
    
    //Try to login
    [[EmpousAPIWrapper sharedEmpousAPIWrapper] setDelegate:self];
    if([[EmpousAPIWrapper sharedEmpousAPIWrapper] loginWithEmpousUsernameOrEmail:usernameOrEmail password:password])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"empous" forKey:@"login"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self loginSuccess];
    }
    else
    {
        if([empousLoginModel getChildByTag:0] == nil)
        {
            //Get screensize
            CGSize winSize = [[CCDirector sharedDirector] winSize];
            CGPoint center = ccp(winSize.width/2,winSize.height/2);
            
            //Display an error so the user can retry to enter a username.
            CCLabelTTF* errorMessage = [CCLabelTTF labelWithString:@"Credentials are invalid" fontName:@"Armalite Rifle" fontSize:12];
            [errorMessage setPosition:ccp(center.x, 170)];
            [errorMessage setColor:ccRED];
            [empousLoginModel addChild:errorMessage z:0 tag:0];
        }
    }
}

/**
 Show the model for creating a new user
 */
-(void)showCreateAccountForm
{
    if(empousUserCreationModel != nil){
        return;
    }
    
    [self removeEmpousLoginTextFields];
    
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    //Create overlay
    modalOverlay = [CCButton spriteWithFile:@"Notification.png" withPressedFile:@"Notification.png" target:self function:@selector(removeEmpousCreateAccount)];
    modalOverlay.scaleX = CC_CONTENT_SCALE_FACTOR() * winSize.width;
    modalOverlay.scaleY = CC_CONTENT_SCALE_FACTOR() * winSize.height;
    modalOverlay.position = center;
    [self addChild:modalOverlay z:2];
    
    empousUserCreationModel = [CCLayer node];
    
    CCButton* modelBackground = [CCButton spriteWithFile:@"Confirm-Box.png"];
    [modelBackground setPosition:center];
    [modelBackground setScaleY:1.2];
    [empousUserCreationModel addChild:modelBackground];
    
    CCButton* closeButton = [CCButton spriteWithFile:@"CloseX.png" withPressedFile:@"CloseX-Pressed.png" target:self function:@selector(removeEmpousCreateAccount) sound:@"button.mp3"];
    [closeButton setPosition:ccp(center.x + 185,290)];
    [empousUserCreationModel addChild:closeButton];
    
    CCButton* createAccount = [CCButton spriteWithFile:@"CreateAccount.png" withPressedFile:@"CreateAccount-Pressed.png" target:self function:@selector(empousCreateAccount) sound:@"button.mp3"];
    [createAccount setPosition:ccp(center.x, 52)];
    [empousUserCreationModel addChild:createAccount];
    
    //Add the username field
    empousUsernameTextField = [[UITextField alloc] initWithFrame: CGRectMake((center.x - 150), 50, 300, 35)];
    empousUsernameTextField.backgroundColor = [UIColor colorWithRed:.23 green:.39 blue:.23 alpha:1.0];
    empousUsernameTextField.textColor = [UIColor whiteColor];
    empousUsernameTextField.borderStyle = UITextBorderStyleRoundedRect;
    empousUsernameTextField.font = [UIFont fontWithName:@"Helvetica" size:24];
    empousUsernameTextField.delegate = self;
    empousUsernameTextField.returnKeyType = UIReturnKeyDone;
    empousUsernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    empousUsernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    empousUsernameTextField.placeholder = @"Username";
    empousUsernameTextField.tag = 3;
    empousUsernameTextField.returnKeyType = UIReturnKeyNext;
    
    //Add the firstname field
    empousFirstTextField = [[UITextField alloc] initWithFrame: CGRectMake(center.x-150, 90, 147, 35)];
    empousFirstTextField.backgroundColor = [UIColor colorWithRed:.23 green:.39 blue:.23 alpha:1.0];
    empousFirstTextField.textColor = [UIColor whiteColor];
    empousFirstTextField.borderStyle = UITextBorderStyleRoundedRect;
    empousFirstTextField.font = [UIFont fontWithName:@"Helvetica" size:24];
    empousFirstTextField.delegate = self;
    empousFirstTextField.returnKeyType = UIReturnKeyDone;
    empousFirstTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    empousFirstTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    empousFirstTextField.placeholder = @"First Name";
    empousFirstTextField.tag = 4;
    empousFirstTextField.returnKeyType = UIReturnKeyNext;;

    
    //Last name
    empousLastTextField = [[UITextField alloc] initWithFrame: CGRectMake(center.x+3, 90, 147, 35)];
    empousLastTextField.backgroundColor = [UIColor colorWithRed:.23 green:.39 blue:.23 alpha:1.0];
    empousLastTextField.textColor = [UIColor whiteColor];
    empousLastTextField.borderStyle = UITextBorderStyleRoundedRect;
    empousLastTextField.font = [UIFont fontWithName:@"Helvetica" size:24];
    empousLastTextField.delegate = self;
    empousLastTextField.returnKeyType = UIReturnKeyDone;
    empousLastTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    empousLastTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    empousLastTextField.placeholder = @"Last Name";
    empousLastTextField.tag = 5;
    empousLastTextField.returnKeyType = UIReturnKeyNext;

    //Add the password fields
    empousPasswordTextField = [[UITextField alloc] initWithFrame: CGRectMake((center.x - 150), 130, 300, 35)];
    empousPasswordTextField.backgroundColor = [UIColor colorWithRed:.23 green:.39 blue:.23 alpha:1.0];
    empousPasswordTextField.textColor = [UIColor whiteColor];
    empousPasswordTextField.borderStyle = UITextBorderStyleRoundedRect;
    empousPasswordTextField.font = [UIFont fontWithName:@"Helvetica" size:24];
    empousPasswordTextField.delegate = self;
    empousPasswordTextField.returnKeyType = UIReturnKeyDone;
    empousPasswordTextField.placeholder = @"Password";
    empousPasswordTextField.secureTextEntry = YES;
    empousPasswordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    empousPasswordTextField.tag = 6;
    empousPasswordTextField.returnKeyType = UIReturnKeyNext;
    
    empousConfirmPasswordTextField = [[UITextField alloc] initWithFrame: CGRectMake((center.x - 150), 170, 300, 35)];
    empousConfirmPasswordTextField.backgroundColor = [UIColor colorWithRed:.23 green:.39 blue:.23 alpha:1.0];
    empousConfirmPasswordTextField.textColor = [UIColor whiteColor];
    empousConfirmPasswordTextField.borderStyle = UITextBorderStyleRoundedRect;
    empousConfirmPasswordTextField.font = [UIFont fontWithName:@"Helvetica" size:24];
    empousConfirmPasswordTextField.delegate = self;
    empousConfirmPasswordTextField.returnKeyType = UIReturnKeyDone;
    empousConfirmPasswordTextField.placeholder = @"Confirm Password";
    empousConfirmPasswordTextField.secureTextEntry = YES;
    empousConfirmPasswordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    empousConfirmPasswordTextField.tag = 7;
    empousConfirmPasswordTextField.returnKeyType = UIReturnKeyNext;
    
    empousEmailField = [[UITextField alloc] initWithFrame: CGRectMake((center.x - 150), 210, 300, 35)];
    empousEmailField.backgroundColor = [UIColor colorWithRed:.23 green:.39 blue:.23 alpha:1.0];
    empousEmailField.keyboardType = UIKeyboardTypeEmailAddress;
    empousEmailField.textColor = [UIColor whiteColor];
    empousEmailField.borderStyle = UITextBorderStyleRoundedRect;
    empousEmailField.font = [UIFont fontWithName:@"Helvetica" size:24];
    empousEmailField.delegate = self;
    empousEmailField.returnKeyType = UIReturnKeyDone;
    empousEmailField.autocorrectionType = UITextAutocorrectionTypeNo;
    empousEmailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    empousEmailField.placeholder = @"Email";
    empousEmailField.tag = 8;
    
    //Add all the text fields
    UIView* view = [[CCDirector sharedDirector] view];
    [view addSubview:empousUsernameTextField];
    [view addSubview:empousFirstTextField];
    [view addSubview:empousLastTextField];
    [view addSubview:empousPasswordTextField];
    [view addSubview:empousConfirmPasswordTextField];
    [view addSubview:empousEmailField];
    
    [self addChild:empousUserCreationModel z:3];
}

-(void)showPasswordResetForm
{
    if (empousResetPasswordModal != nil)
    {
        return;
    }
    
    [self removeEmpousLoginTextFields];
    
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    //Create overlay
    modalOverlay = [CCButton spriteWithFile:@"Notification.png" withPressedFile:@"Notification.png" target:self function:@selector(removeEmpousResetPassword)];
    modalOverlay.scaleX = CC_CONTENT_SCALE_FACTOR() * winSize.width;
    modalOverlay.scaleY = CC_CONTENT_SCALE_FACTOR() * winSize.height;
    modalOverlay.position = center;
    [self addChild:modalOverlay z:2];
    
    empousResetPasswordModal = [CCLayer node];
    
    CCButton* modelBackground = [CCButton spriteWithFile:@"Confirm-Box.png"];
    [modelBackground setPosition:center];
    [modelBackground setScaleY:1.3];
    [modelBackground setScaleX:1.1];
    [empousResetPasswordModal addChild:modelBackground];
    
    CCButton* closeButton = [CCButton spriteWithFile:@"CloseX.png" withPressedFile:@"CloseX-Pressed.png" target:self function:@selector(removeEmpousResetPassword) sound:@"button.mp3"];
    [closeButton setPosition:ccp(center.x + 207,295)];
    [empousResetPasswordModal addChild:closeButton];
    
    CCLabelTTF* helpText = [CCLabelTTF labelWithString:@"Reset your password with a token" fontName:@"Armalite Rifle" fontSize:20];
    [helpText setPosition:ccp(center.x,280)];
    [empousResetPasswordModal addChild:helpText];
    
    CCButton* sendToken = [CCButton spriteWithFile:@"Email-Token.png" withPressedFile:@"Email-Token-Pressed.png" target:self function:@selector(sendTokenForUser) sound:@"button.mp3"];
    [sendToken setPosition:ccp(center.x, 250)];
    [empousResetPasswordModal addChild:sendToken];
    
    CCButton* resetPassword = [CCButton spriteWithFile:@"Reset-Password.png" withPressedFile:@"Reset-Password-Pressed.png" target:self function:@selector(resetPassword)];
    [resetPassword setPosition:ccp(center.x, 40)];
    [empousResetPasswordModal addChild:resetPassword];
    
    [self addChild:empousResetPasswordModal z:3];
    
    //Add Token Field
    empousTokenField = [[UITextField alloc] initWithFrame:CGRectMake((center.x - 150), 95, 300, 35)];
    empousTokenField.backgroundColor = [UIColor colorWithRed:.23 green:.39 blue:.23 alpha:1.0];
    empousTokenField.textColor = [UIColor whiteColor];
    empousTokenField.borderStyle = UITextBorderStyleRoundedRect;
    empousTokenField.font = [UIFont fontWithName:@"Helvetica" size:24];
    empousTokenField.delegate = self;
    empousTokenField.returnKeyType = UIReturnKeyDone;
    empousTokenField.autocorrectionType = UITextAutocorrectionTypeNo;
    empousTokenField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    empousTokenField.placeholder = @"Token";
    empousTokenField.tag = 9;
    empousTokenField.returnKeyType = UIReturnKeyNext;
    
    //Add the Username Field
    empousUsernameTextField = [[UITextField alloc] initWithFrame: CGRectMake((center.x - 150), 135, 300, 35)];
    empousUsernameTextField.backgroundColor = [UIColor colorWithRed:.23 green:.39 blue:.23 alpha:1.0];
    empousUsernameTextField.textColor = [UIColor whiteColor];
    empousUsernameTextField.borderStyle = UITextBorderStyleRoundedRect;
    empousUsernameTextField.font = [UIFont fontWithName:@"Helvetica" size:24];
    empousUsernameTextField.delegate = self;
    empousUsernameTextField.returnKeyType = UIReturnKeyDone;
    empousUsernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    empousUsernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    empousUsernameTextField.placeholder = @"Username/Email";
    empousUsernameTextField.tag = 10;
    empousUsernameTextField.returnKeyType = UIReturnKeyNext;
    
    //Add the password fields
    empousPasswordTextField = [[UITextField alloc] initWithFrame: CGRectMake((center.x - 150), 175, 300, 35)];
    empousPasswordTextField.backgroundColor = [UIColor colorWithRed:.23 green:.39 blue:.23 alpha:1.0];
    empousPasswordTextField.textColor = [UIColor whiteColor];
    empousPasswordTextField.borderStyle = UITextBorderStyleRoundedRect;
    empousPasswordTextField.font = [UIFont fontWithName:@"Helvetica" size:24];
    empousPasswordTextField.delegate = self;
    empousPasswordTextField.returnKeyType = UIReturnKeyDone;
    empousPasswordTextField.placeholder = @"Password";
    empousPasswordTextField.secureTextEntry = YES;
    empousPasswordTextField.tag = 11;
    empousPasswordTextField.returnKeyType = UIReturnKeyNext;
    
    empousConfirmPasswordTextField = [[UITextField alloc] initWithFrame: CGRectMake((center.x - 150), 215, 300, 35)];
    empousConfirmPasswordTextField.backgroundColor = [UIColor colorWithRed:.23 green:.39 blue:.23 alpha:1.0];
    empousConfirmPasswordTextField.textColor = [UIColor whiteColor];
    empousConfirmPasswordTextField.borderStyle = UITextBorderStyleRoundedRect;
    empousConfirmPasswordTextField.font = [UIFont fontWithName:@"Helvetica" size:24];
    empousConfirmPasswordTextField.delegate = self;
    empousConfirmPasswordTextField.returnKeyType = UIReturnKeyDone;
    empousConfirmPasswordTextField.placeholder = @"Confirm Password";
    empousConfirmPasswordTextField.secureTextEntry = YES;
    empousConfirmPasswordTextField.tag = 12;
    
    UIView* view = [[CCDirector sharedDirector] view];
    [view addSubview:empousTokenField];
    [view addSubview:empousUsernameTextField];
    [view addSubview:empousPasswordTextField];
    [view addSubview:empousConfirmPasswordTextField];

}

-(void)sendTokenForUser
{
    //Show pop up box for username / email
    UIAlertView* dialog = [[UIAlertView alloc] init];
    [dialog setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [dialog setDelegate:self];
    [dialog setTitle:@"Enter Your Username or Email"];
    [dialog addButtonWithTitle:@"Cancel"];
    [dialog addButtonWithTitle:@"Send Token"];
    [dialog setCancelButtonIndex:0];
    [dialog show];
    [dialog release];
}

//Called when the user clicks a button in an alert view
-(void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1)
    {
        //Display a spinner
        overlay = [CCLoadingOverlay nodeWithMessage:@"Generating Token..." withFont:@"Armalite Rifle"];
        [self addChild:overlay z:INT_MAX - 1];
        
        //Hide the reset password fields
        [self setPasswordResetFieldHidden:YES];
        
        NSLog(@"Attempting to send token to %@", [[alert textFieldAtIndex:0] text]);
        NSString* usernameOrEmail = [[[alert textFieldAtIndex:0] text] copy];
        [[EmpousAPIWrapper sharedEmpousAPIWrapper] setDelegate:self];
        [[EmpousAPIWrapper sharedEmpousAPIWrapper] sendTokenForUser:usernameOrEmail];
        [usernameOrEmail release];
    }
}

-(void)setPasswordResetFieldHidden:(BOOL)hideFields
{
    [empousTokenField setHidden:hideFields];
    [empousUsernameTextField setHidden:hideFields];
    [empousPasswordTextField setHidden:hideFields];
    [empousConfirmPasswordTextField setHidden:hideFields];
}

-(void)tokenResponse:(NSString*)response
{
    //Remove the spinner
    [self removeChild:overlay cleanup:YES];
    
    //Unhide the reset password fields
    [self setPasswordResetFieldHidden:NO];
    
    //Show pop up box for username / email
    UIAlertView* dialog = [[UIAlertView alloc] init];
    [dialog setDelegate:self];
    [dialog setTitle:@"Send a Token"];
    [dialog setMessage:response];
    [dialog addButtonWithTitle:@"OK"];
    [dialog setCancelButtonIndex:0];
    [dialog show];
    [dialog release];
}

-(void)resetPassword
{
    NSString* usernameOrEmail = [empousUsernameTextField text];
    NSString* password = [empousPasswordTextField text];
    NSString* confirmPassword = [empousConfirmPasswordTextField text];
    NSString* token = [empousTokenField text];
    
    //Check that all fields have values
    if([usernameOrEmail isEqualToString:@""]|| [password isEqualToString:@""] || [confirmPassword isEqualToString:@""] || [token isEqualToString:@""])
    {
        return [self showEmpousResetPasswordError:@"All fields must have values"];
    }
    
    //Check that the passwords match
    if(![password isEqualToString:confirmPassword])
    {
        return [self showEmpousResetPasswordError:@"Passwords do not match"];
    }
    
    //Hide the reset password fields
    [self setPasswordResetFieldHidden:YES];
    
    //Display a spinner
    overlay = [CCLoadingOverlay nodeWithMessage:@"Resetting your password..." withFont:@"Armalite Rifle"];
    [self addChild:overlay z:INT_MAX - 1];
    
    //Attempt to reset the password
    [[EmpousAPIWrapper sharedEmpousAPIWrapper] setDelegate:self];
    [[EmpousAPIWrapper sharedEmpousAPIWrapper] resetPasswordForEmpousUserWithUsernameOrEmail:usernameOrEmail password:password token:token];
}

-(void)passwordResetResponse:(BOOL)success message:(NSString*)errorMessage
{
    [self removeChild:overlay];

    if (success)
    {
        [self removeEmpousResetPassword];
        
        UIAlertView* dialog = [[UIAlertView alloc] init];
        [dialog setDelegate:self];
        [dialog setTitle:@"Password Reset"];
        [dialog setMessage:@"Your password has been reset"];
        [dialog addButtonWithTitle:@"OK"];
        [dialog setCancelButtonIndex:0];
        [dialog show];
        [dialog release];
    }
    else
    {
        [self setPasswordResetFieldHidden:NO];
        [self showEmpousResetPasswordError:errorMessage];
    }
}

-(void)showEmpousResetPasswordError:(NSString*)error
{
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    //Display password error
    if([empousResetPasswordModal getChildByTag:0] != nil)
    {
        [empousResetPasswordModal removeChildByTag:0 cleanup:YES];
    }
    
    //Display an error so the user can retry to enter a username.
    CCLabelTTF* errorMessage = [CCLabelTTF labelWithString:error fontName:@"Armalite Rifle" fontSize:12];
    [errorMessage setPosition:ccp(center.x, 60)];
    [errorMessage setColor:ccRED];
    [empousResetPasswordModal addChild:errorMessage z:0 tag:0];
    return;
}

-(void)empousCreateAccount
{
    //[self cleanUpEmpousAuthElements];
    
    NSString* username = [empousUsernameTextField text];
    NSString* password = [empousPasswordTextField text];
    NSString* confirmPassword = [empousConfirmPasswordTextField text];
    NSString* firstName = [empousFirstTextField text];
    NSString* lastName = [empousLastTextField text];
    NSString* email = [empousEmailField text];
    
    //Check that all fields have values
    if([username isEqualToString:@""]|| [password isEqualToString:@""] || [confirmPassword isEqualToString:@""] || [firstName isEqualToString:@""] || [lastName isEqualToString:@""] || [email isEqualToString:@""])
    {
        return [self showEmpousCreateAccountError:@"All fields must have values"];
    }
    
    //Check that the passwords match
    if(![password isEqualToString:confirmPassword])
    {
        return [self showEmpousCreateAccountError:@"Passwords do not match"];
    }

    //If they do check if the username is available
    if(![[EmpousAPIWrapper sharedEmpousAPIWrapper] checkIfUsernameAvailable:username])
    {
        return [self showEmpousCreateAccountError:@"Username is already taken"];
    }
    
    //Hide the create input fields so they don't show above the overlay
    [self hideEmpousCreateAccountTextFields];
    
    //Display a spinner
    overlay = [CCLoadingOverlay nodeWithMessage:@"Creating Account..." withFont:@"Armalite Rifle"];
    [self addChild:overlay z:INT_MAX - 1];
    
    //Create the account
    [[EmpousAPIWrapper sharedEmpousAPIWrapper] setDelegate:self];
    [[EmpousAPIWrapper sharedEmpousAPIWrapper] createEmpousUserWithUsername:username password:password firstName:firstName lastName:lastName email:email];
}

-(void)showEmpousCreateAccountError:(NSString*)error
{
    [self displayEmpousUserCreationError:error];
    return;
}

-(void)cleanUpEmpousAuthElements
{
    //Be careful. You must remove the create account stuff first
    [self removeEmpousCreateAccount];
    
    if(empousLoginModel != nil)
    {
        [self removeChild:empousLoginModel cleanup:YES];
    }
    
    [empousUsernameField removeFromSuperview];
    [empousPasswordField removeFromSuperview];
}

-(void)hideEmpousCreateAccountTextFields
{
    [empousUsernameTextField setHidden:YES];
    [empousPasswordTextField setHidden:YES];
    [empousConfirmPasswordTextField setHidden:YES];
    [empousFirstTextField setHidden:YES];
    [empousLastTextField setHidden:YES];
    [empousEmailField setHidden:YES];
}

-(void)showEmpousCreateAccountFields
{
    [empousUsernameTextField setHidden:NO];
    [empousPasswordTextField setHidden:NO];
    [empousConfirmPasswordTextField setHidden:NO];
    [empousFirstTextField setHidden:NO];
    [empousLastTextField setHidden:NO];
    [empousEmailField setHidden:NO];
}

-(void)removeEmpousCreateAccount
{
    
    [empousUsernameTextField removeFromSuperview];
    [empousPasswordTextField removeFromSuperview];
    [empousConfirmPasswordTextField removeFromSuperview];
    [empousFirstTextField removeFromSuperview];
    [empousLastTextField removeFromSuperview];
    [empousEmailField removeFromSuperview];
    
    if(empousUserCreationModel != nil)
    {
        [self removeChild:modalOverlay cleanup:YES];
        [self removeChild:empousUserCreationModel cleanup:YES];
        [self addEmpousLoginTextFields];
        empousUserCreationModel = nil;
    }
}

-(void)removeEmpousResetPassword
{
    [empousTokenField removeFromSuperview];
    [empousUsernameTextField removeFromSuperview];
    [empousPasswordTextField removeFromSuperview];
    [empousConfirmPasswordTextField removeFromSuperview];
    
    if (empousResetPasswordModal != nil)
    {
        [self removeChild:modalOverlay cleanup:YES];
        [self removeChild:empousResetPasswordModal cleanup:YES];
        [self addEmpousLoginTextFields];
        empousResetPasswordModal = nil;
    }
}

-(void)displayEmpousUserCreationError:(NSString*)error
{
    //Get screensize
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(winSize.width/2,winSize.height/2);
    
    //Display password error
    if([empousUserCreationModel getChildByTag:0] != nil)
    {
        [empousUserCreationModel removeChildByTag:0 cleanup:YES];
    }
    
    //Display an error so the user can retry to enter a username.
    CCLabelTTF* errorMessage = [CCLabelTTF labelWithString:error fontName:@"Armalite Rifle" fontSize:12];
    [errorMessage setPosition:ccp(center.x, 278)];
    [errorMessage setColor:ccRED];
    [empousUserCreationModel addChild:errorMessage z:0 tag:0];
    return;
}

-(void)playerLoggedIn
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"empous" forKey:@"login"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self loginSuccess];
}

-(void)playerFailedLogIn:(NSString*)errorMessage
{
    [self displayEmpousUserCreationError:errorMessage];
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    NSInteger nextTag = textField.tag + 1;
    // Try to find next responder
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
        // Not found, so remove keyboard.
        [textField resignFirstResponder];
    }
    return NO; // We do not want UITextField to insert line-breaks.
}

@end
