
//
//  main.m
//  Empous
//
//  Created by Ryan Hurley on 1/15/12.
//  Copyright Apple 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([AppController class]));
    [pool release];
    return retVal;
}

