//
//  EmpousAPIWrapper+Http.h
//  Empous
//
//  Created by Ryan Personal on 7/5/13.
//  Copyright (c) 2013 HurleyProg. All rights reserved.
//

#import "EmpousAPIWrapper.h"

@interface EmpousAPIWrapper (Http)

-(NSDictionary*)sendPOSTRequest:(NSString*)requestUrlWithoutHost;
-(NSDictionary*)sendAsyncPOSTRequest:(NSString*)requestUrlWithoutHost callback:(SEL)selector;
-(NSDictionary*)sendPOSTRequest:(NSString*)requestUrlWithoutHost withParams:(NSMutableDictionary*)params;
-(NSDictionary*)sendAsyncPOSTRequest:(NSString*)requestUrlWithoutHost withParams:(NSMutableDictionary*)params callback:(SEL)selector;
-(NSDictionary*)sendPOSTRequest:(NSString*)requestUrlWithoutHost withParams:(NSMutableDictionary*)params withScreenShot:(NSString*)screenshotPath;
-(NSDictionary*)sendPOSTRequest:(NSString*)requestUrlWithoutHost withParams:(NSMutableDictionary*)params withScreenShot:(NSString*)screenshotPath callback:(SEL)selector useAsync:(BOOL)async;
-(void)showMainMenuConnectionError;
-(int)getStatus:(NSDictionary*)result;
-(NSString*)getMessage:(NSDictionary*)result;

@end
