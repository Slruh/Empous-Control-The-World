//
//  EmpousAPIWrapper+Http.m
//  Empous
//
//  Created by Ryan Personal on 7/5/13.
//  Copyright (c) 2013 HurleyProg. All rights reserved.
//

#import "EmpousAPIWrapper+Http.h"
#import "FBSBJSON.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "MainMenuScene.h"

@implementation EmpousAPIWrapper (Http)

-(NSDictionary*)sendPOSTRequest:(NSString*)requestUrlWithoutHost
{
    return [self sendPOSTRequest:requestUrlWithoutHost withParams:nil];
}

-(NSDictionary*)sendAsyncPOSTRequest:(NSString*)requestUrlWithoutHost callback:(SEL)selector
{
    return [self sendAsyncPOSTRequest:requestUrlWithoutHost withParams:nil callback:selector];
}

-(NSDictionary*)sendPOSTRequest:(NSString*)requestUrlWithoutHost withParams:(NSMutableDictionary*)params
{
    return [self sendPOSTRequest:requestUrlWithoutHost withParams:params withScreenShot:nil callback:nil useAsync:NO];
}

-(NSDictionary*)sendAsyncPOSTRequest:(NSString*)requestUrlWithoutHost withParams:(NSMutableDictionary*)params callback:(SEL)selector
{
    return [self sendPOSTRequest:requestUrlWithoutHost withParams:params withScreenShot:nil callback:selector useAsync:YES];
}

-(NSDictionary*)sendPOSTRequest:(NSString*)requestUrlWithoutHost withParams:(NSMutableDictionary*)params withScreenShot:(NSString*)screenshotPath
{
    return [self sendPOSTRequest:requestUrlWithoutHost withParams:params withScreenShot:screenshotPath callback:nil useAsync:NO];
}

/*
 *  Sends a post request to the Empous server to the URL supplied
 *  params - the post params
 *  withFilePath - the file to upload to the server
 *
 *  Note that the error callback is only called when there is a error in the request.
 *  Not if there is an error in the empous response dictionary. You must check for it.
 */
-(NSDictionary*)sendPOSTRequest:(NSString*)requestUrlWithoutHost withParams:(NSMutableDictionary*)params withScreenShot:(NSString*)screenshotPath callback:(SEL)selector useAsync:(BOOL)async
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseUrl, requestUrlWithoutHost]];
    
    //Add the device token if it exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* iosToken = [defaults objectForKey:@"iostoken"];
    if(nil != iosToken)
    {
        [params setObject:iosToken forKey:@"iostoken"];
    }
    
    __block NSMutableDictionary* result;
    
#if TARGET_IPHONE_SIMULATOR
    //[NSThread sleepForTimeInterval:5];
#endif
    
    if(async)
    {
        __block ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:url];
        [self addParamsToRequest:request withParams:params withScreenShotPath:screenshotPath];
        [request setTimeOutSeconds:30];
        [request setValidatesSecureCertificate:NO];
        [request setCompletionBlock:^{
            NSLog(@"Response: %@", [request responseString]);
            result = [self preprocessResponseData:[request responseString]];
            
            if (result != nil)
            {
                if(selector != nil)
                {
                    [self performSelector:selector withObject:result];
                    return;
                }
            }
            else
            {
                [self showMainMenuConnectionError];
            }

        }];
        [request setFailedBlock:^{
            NSError* error = [request error];
            NSLog(@"Error when contacting empous: %@", [error localizedDescription]);
            [self showMainMenuConnectionError];
        }];
        
        [request startAsynchronous];
    }
    else
    {
        ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:url];
        [self addParamsToRequest:request withParams:params withScreenShotPath:screenshotPath];
        [request setTimeOutSeconds:30];
        
        //Send the request
        [request startSynchronous];
        
        //Check for any errors
        NSError* error = [request error];
        result = [self preprocessResponseData:[request responseString]];
        if(!error && result != nil)
        {
            return result;
        }
        else
        {
            [self showMainMenuConnectionError];
        }
    }
    
    return result;
}

-(void)addParamsToRequest:(ASIFormDataRequest*)request withParams:(NSMutableDictionary*)params withScreenShotPath:(NSString*)screenshotPath
{
    //Add all the parameters to the request and send it
    if(nil != params){
        for (id key in params)
        {
            id value = [params objectForKey:key];
            if ([value isKindOfClass:[NSArray class]]){
                //Embed a JSON string instead
                FBSBJSON* jsonParser = [[FBSBJSON alloc] init];
                NSString* jsonValue = [jsonParser stringWithObject:(NSArray*)value];
                [request setPostValue:jsonValue forKey:key];
                [jsonParser release];
            }
            //Assume it's a string
            else
            {
                [request setPostValue:[params objectForKey:key] forKey:key];
            }
        }
    }
    
    //Add the build number so the server can make sure the app isnt too old.
    NSString* buildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [request setPostValue:buildNumber forKey:@"build"];
    
    //Add the empous token and user id
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* token = [defaults objectForKey:@"token"];
    NSLog(@"Token used: %@", token);
    NSString* empousId = [defaults objectForKey:@"empous_id"];
    
    //Add if continents are enabled
    id continents = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"canPlayWithContinents"];
    if (continents)
    {
        [request setPostValue:continents forKey:@"canPlayWithContinents"];
    }

    [request setPostValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"IsEmpousLite"] forKey:@"isEmpousLite"];

    if(nil != token){
        //These keys are needed by the django token api
        [request setPostValue:token forKey:@"token"];
        [request setPostValue:empousId forKey:@"user"];
    }
    
    if(nil != screenshotPath)
    {
        [request setFile:screenshotPath forKey:@"screenshot_file"];
    }
}

-(NSMutableDictionary*)preprocessResponseData:(NSString*)jsonResponse
{
    NSLog(@"** Empous API Result **");
    NSLog(@"%@", jsonResponse);
    
    FBSBJSON *jsonParser = [[FBSBJSON alloc] init];
    NSMutableDictionary* result = [jsonParser objectWithString:jsonResponse];
    [jsonParser release];
    
    //Check the result for out of data application
    if ([[result objectForKey:@"result"] intValue] == 2)
    {
        [self showOutOfDateError];
    }
    
    return result;
}

-(void)showMainMenuConnectionError
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:0.5f scene:[MainMenuScene nodeWithMessage:CONNECTION_ERROR]]];
}

-(void)showOutOfDateError
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:0.5f scene:[MainMenuScene nodeWithMessage:OUTDATED_APP]]];
}

-(int)getStatus:(NSDictionary*)result
{
    return [[result objectForKey:@"result"] intValue];
}

-(NSString*)getMessage:(NSDictionary*)result
{
    return [result objectForKey:@"message"];
}
@end
