//
//  GPSAssistAppDelegate.h
//  GPS Assist Updater
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "MountsHandler.h"
#import "GPSAssistDataHandler.h"
#import "AboutController.h"

@interface GPSAssistAppDelegate : NSObject <GrowlApplicationBridgeDelegate>
{
    IBOutlet NSWindow     *welcomeWindow;
    IBOutlet NSMenu       *statusMenu;
    IBOutlet NSMenuItem   *autoUpdateItem;
    IBOutlet NSMenuItem   *hiddenSeperator;
    
    NSStatusItem          *statusItem;
	NSArray               *mountsMenuItems;
    BOOL                  autoUpdate;
    
	MountsHandler         *mountsHandler;
	GPSAssistDataHandler  *gpsAssistDataHandler;
    
    AboutController       *aboutController;
	
	IBOutlet NSButtonCell *dontShowTickBox;
}

@property(assign)   MountsHandler *mountsHandler;
@property(readonly) BOOL          autoUpdate;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
- (IBAction)continuePressed:(id)sender;
- (void)updateMounts:(NSMutableArray*)menuItems;

@end
