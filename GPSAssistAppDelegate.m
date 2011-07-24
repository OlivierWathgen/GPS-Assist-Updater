//
//  GPSAssistAppDelegate.m
//  DSC-HX5V GPSAssist Update
//

#import "GPSAssistAppDelegate.h"

static NSString *hideWelcome=@"hideWelcome";

@interface GPSAssistAppDelegate(Private)
-(void)startApplication;
@end


@implementation GPSAssistAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
	[GrowlApplicationBridge setGrowlDelegate:self];
    	
	//Check if we need to show the welcome-window first
	if(![[NSUserDefaults standardUserDefaults]boolForKey:hideWelcome]){
		//show window
		[window makeKeyAndOrderFront:self];
	}else{
		[self startApplication];
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender{
	[gpsAssistMenu release];
	[gpsAssistDataHandler stop];
	[gpsAssistDataHandler release];
	[mountsHandler release];
	return NSTerminateNow;
}

-(void)startApplication{
    //Create the StatusMenu
	gpsAssistMenu=[[GPSAssistMenu alloc]init];
	//Create the handler that gets the data from the server
	gpsAssistDataHandler=[[GPSAssistDataHandler alloc]init];
	//Create the MountsHandler
	mountsHandler=[[MountsHandler alloc]initWithMenu:gpsAssistMenu dataHandler:gpsAssistDataHandler];
	gpsAssistMenu.mountsHandler=mountsHandler;
}

-(IBAction)continuePressed:(id)sender{
	//Store the dontShow-value in the userDefalts
	BOOL dontShow=[dontShowTickBox intValue]==1;
	[[NSUserDefaults standardUserDefaults]setBool:dontShow forKey:hideWelcome];
	[[NSUserDefaults standardUserDefaults]synchronize];
	[window close];
	[self startApplication];
}

@end
