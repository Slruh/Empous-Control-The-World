//
//  FacebookWrapper.m
//  Empous
//
//  Created by Ryan Hurley on 4/6/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "FacebookWrapper.h"
#import <Foundation/Foundation.h>
#import "EmpousAPIWrapper.h"

static Facebook* facebook = nil;
static FacebookWrapper* wrapper = nil;
static NSString* usernameToUse = nil;

NSString* APP_ID = @"REMOVED";
NSString* APP_URL = @"empous";

@implementation FacebookWrapper
@synthesize playerName;
@synthesize requestType;

- (id)init
{
    self = [super init];
    return self;
}


+(id)sharedFacebookWrapper
{
    if(wrapper == nil){
        wrapper = [[self alloc]init];
        if(wrapper){
            //Do Facebook allocation and things
            facebook = [[Facebook alloc]initWithAppId:APP_ID andDelegate:wrapper];
                        
            //Check to see if they have logged in already
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults objectForKey:@"FBAccessTokenKey"] 
                && [defaults objectForKey:@"FBExpirationDateKey"]) {
                facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
                NSLog(@"%@", [defaults objectForKey:@"FBAccessTokenKey"]);
                facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
            }
            
        }
    }
    return wrapper;
}

-(void)setDelegate:(id)newdelegate{
    if(![[newdelegate class] conformsToProtocol:@protocol(FacebookWrapperDelegate)]){
        [NSException raise:@"Delegate Exception" format:@"Delegate of class %@ is invalid", [newdelegate class]];
    }else{
        if(delegate){
            [delegate release];
        }
        [newdelegate retain];
        delegate = newdelegate;
        
    }
}

-(void)authorize
{
    [FBSession openActiveSessionWithReadPermissions:nil
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session,
       FBSessionState state, NSError *error) {
         [self sessionStateChanged:session state:state error:error];
     }];
}

-(void)authorizeWithUsername:(NSString*)username
{
    usernameToUse = username;
    [self authorize];
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen: {
            NSLog(@"FB Session Opened");
            [self handleGameLoaded];
        }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            //Just return to the main screen
            NSLog(@"FB Session Error: %@",[error description]);
            break;
        default:
            break;
    }
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

-(void)handleGameLoaded
{
    if(usernameToUse == nil)
    {
        [[EmpousAPIWrapper sharedEmpousAPIWrapper] setDelegate:self];
        [[EmpousAPIWrapper sharedEmpousAPIWrapper] performSelectorInBackground:@selector(createEmpousUserWithFacebook:) withObject:[[FBSession activeSession] accessToken]];
    }
    else
    {
        [[EmpousAPIWrapper sharedEmpousAPIWrapper] setDelegate:self];
        [[EmpousAPIWrapper sharedEmpousAPIWrapper] performSelectorInBackground:@selector(createEmpousUserWithFacebookAndUsernameDict:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:[[FBSession activeSession] accessToken], @"token", usernameToUse, @"username", nil]];
        usernameToUse = nil;
    }
}

//Call backs from the Empous Wrapper
-(void)playerLoggedIn
{
    if([delegate respondsToSelector:@selector(fbUserLoggedIn)]){
        [delegate fbUserLoggedIn];
    }
}

-(void)loginNeedsRevalidation:(NSString*)error
{
    [facebook logout:self];

    if([delegate respondsToSelector:@selector(fbUserLogInFailed:)]){
        [delegate performSelector:@selector(fbUserLogInFailed:) withObject:error];
    }
}

-(void)playerFailedLogIn:(NSString*)errorMessage;
{
    if([delegate respondsToSelector:@selector(fbUserLogInFailed:)]){
        [delegate performSelector:@selector(fbUserLogInFailed:) withObject:errorMessage];
    }
}

-(void)playerFailedLogInNeedUsername
{
    if([delegate respondsToSelector:@selector(fbuserLoginFailedNeedUsername)])
    {
        [delegate fbuserLoginFailedNeedUsername];
    }
}

/*******  Facebook Session Delegate Methods *******/
-(BOOL)handleOpenUrl:(NSURL *)url{
    return [FBSession.activeSession handleOpenURL:url];
}

// Pre iOS 4.2 support
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [facebook handleOpenURL:url]; 
}

// For iOS 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [facebook handleOpenURL:url]; 
}

- (void)fbDidLogin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"%@",[[facebook accessToken]description]);
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    
    [self handleGameLoaded];
}

// Method that gets called when the logout button is pressed
- (void) logoutButtonClicked:(id)sender {
    [facebook logout];
}

- (void) fbDidLogout {
    // Remove saved authorization information if it exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]) {
        [defaults removeObjectForKey:@"FBAccessTokenKey"];
        [defaults removeObjectForKey:@"FBExpirationDateKey"];
        [defaults synchronize];
    }
}

-(void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
    NSLog(@"token extended");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:accessToken forKey:@"FBAccessTokenKey"];
    [defaults setObject:expiresAt forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
}

/**
 * Called when the user dismissed the dialog without logging in.
 */
- (void)fbDidNotLogin:(BOOL)cancelled
{
    
}


/**
 * Called when the current session has expired. This might happen when:
 *  - the access token expired
 *  - the app has been disabled
 *  - the user revoked the app's permissions
 *  - the user changed his or her password
 */
- (void)fbSessionInvalidated{
    
}

/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"%@", [error localizedDescription]);
    NSLog(@"Err details: %@", [error description]);
}

/**
 * Helper method for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
}

/**
 * Called when dialog failed to load due to an error.
 */
- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error
{
    NSLog(@"Error in dialog");
    NSLog(@"%@", [error localizedDescription]);
    NSLog(@"Err details: %@", [error description]);
}



@end
