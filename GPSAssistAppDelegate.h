//
//  GPSAssistAppDelegate.h
//  DSC-HX5V GPSAssist Update
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "MountsHandler.h"
#import "GPSAssistDataHandler.h"

@interface GPSAssistAppDelegate : NSObject <GrowlApplicationBridgeDelegate>
{
    IBOutlet NSWindow   *window;
    IBOutlet NSMenu     *statusMenu;
    IBOutlet NSMenuItem *autoUpdateItem;
    IBOutlet NSMenuItem *hiddenSeperator;
    
    NSStatusItem        *statusItem;
	NSArray             *mountsMenuItems;
    BOOL                autoUpdate;
    
	MountsHandler *mountsHandler;
	GPSAssistDataHandler *gpsAssistDataHandler;
	
	IBOutlet NSButtonCell *dontShowTickBox;
}

@property(assign) MountsHandler *mountsHandler;
@property(readonly) BOOL autoUpdate;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
- (IBAction)continuePressed:(id)sender;
- (void)updateMounts:(NSMutableArray*)menuItems;

@end
