//
//  GPSAssistAppDelegate.h
//  DSC-HX5V GPSAssist Update
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "GPSAssistMenu.h"
#import "MountsHandler.h"
#import "GPSAssistDataHandler.h"

@interface GPSAssistAppDelegate : NSObject <GrowlApplicationBridgeDelegate> {
	GPSAssistMenu *gpsAssistMenu;
	MountsHandler *mountsHandler;
	GPSAssistDataHandler *gpsAssistDataHandler;
	IBOutlet NSWindow *window;
	IBOutlet NSButtonCell *dontShowTickBox;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
- (IBAction)continuePressed:(id)sender;

@end
