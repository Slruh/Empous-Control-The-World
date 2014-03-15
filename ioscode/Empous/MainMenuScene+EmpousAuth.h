//
//  MainMenuScene+EmpousAuth.h
//  Empous
//
//  Created by Ryan Personal on 4/29/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "MainMenuScene.h"
#import "ControlLayer.h"

@interface MainMenuScene (EmpousAuth) <ControlLayerDelegate>

-(void)empousAuthorize;

-(void)empousLogin;

-(void)cleanUpEmpousAuthElements;
-(void)removeEmpousCreateAccount;
-(void)removeEmpousResetPassword;

@end
