//
//  MainMenuScene+FacebookAuth.h
//  Empous
//
//  Created by Ryan Personal on 4/29/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "MainMenuScene.h"

@interface MainMenuScene (FacebookAuth)

-(void)facebookAuthorize;
-(void)facebookAuthorizeWithUsername;
-(void)cleanUpFacebookAuthElements;

@end
