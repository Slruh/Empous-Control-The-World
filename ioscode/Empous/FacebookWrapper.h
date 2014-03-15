//
//  FacebookWrapper.h
//  Empous
//
//  Created by Ryan Hurley on 4/6/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect.h"
#import "EmpousAPIWrapper.h"

@protocol FacebookWrapperDelegate<NSObject>
@optional
-(void)fbUserLoggedIn;
-(void)fbUserLogInFailed:(NSString*)message;
-(void)fbuserLoginFailedNeedUsername;
-(void)invitedFacebookIds;

@end

typedef enum {
    NONE,
    PLAYER,
    FRIENDS
} CurrentRequest;

@interface FacebookWrapper : NSObject <FBSessionDelegate,FBRequestDelegate,FBDialogDelegate,EmpousWrapperDelegate>{
    NSString* playerName;
    CurrentRequest requestType;
    
    id <FacebookWrapperDelegate> delegate;
}
@property (retain) NSString* playerName;
@property CurrentRequest requestType;

+(id)sharedFacebookWrapper;
-(void)authorize;
-(void)authorizeWithUsername:(NSString*)username;
-(void)setDelegate:(id)newdelegate;
-(BOOL)handleOpenUrl:(NSURL *)url;



@end
