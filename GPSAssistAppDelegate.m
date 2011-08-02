//
//  GPSAssistAppDelegate.m
//  DSC-HX5V GPSAssist Update
//

#import "GPSAssistAppDelegate.h"
#import "Sparkle/Sparkle.h"

static NSString *hideWelcome=@"hideWelcome";
static NSString *disableAutoUpdate = @"disableAutoUpdate";

@interface GPSAssistAppDelegate(Private)
-(void)startApplication;
@end


@implementation GPSAssistAppDelegate

@synthesize mountsHandler;
@synthesize autoUpdate;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[GrowlApplicationBridge setGrowlDelegate:self];
    
    SUUpdater *updater = [SUUpdater sharedUpdater];
    [updater checkForUpdatesInBackground];
    	
	// Check if we need to show the welcome-window first
	if (![[NSUserDefaults standardUserDefaults]boolForKey:hideWelcome])
    {
		[window makeKeyAndOrderFront:self];
	}
    else {
		[self startApplication];
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	[gpsAssistDataHandler stop];
	[gpsAssistDataHandler release];
	[mountsHandler release];
	return NSTerminateNow;
}

-(void)startApplication
{
    NSImage *statusMenuImage = [NSImage imageNamed:@"gps_small.png"];
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:[statusMenuImage size].width] retain];
	[statusItem setImage:statusMenuImage];
    [statusItem setTitle:@"GPS Assist Updater"];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:statusMenu];
    
    // Set state of MenuItem "auto update"
    if ([[NSUserDefaults standardUserDefaults] boolForKey:disableAutoUpdate]){
		[autoUpdateItem setState:NSOffState];
		autoUpdate = NO;
	}
    else {
		[autoUpdateItem setState:NSOnState];
		autoUpdate = YES;
	}
    
	// Create the handler that gets the data from the server
	gpsAssistDataHandler = [[GPSAssistDataHandler alloc] init];
    
	// Create the MountsHandler
	mountsHandler = [[MountsHandler alloc] initWithDataHandler:gpsAssistDataHandler];
}

-(IBAction)autoUpdateMenu:(id)sender
{
	if (autoUpdate)
    {
		[autoUpdateItem setState:NSOffState];
		[[NSUserDefaults standardUserDefaults]setBool:YES forKey:disableAutoUpdate];
	}
    else
    {
		[autoUpdateItem setState:NSOnState];
		[[NSUserDefaults standardUserDefaults]setBool:NO forKey:disableAutoUpdate];
	}
    autoUpdate = !autoUpdate;
    mountsHandler.gpsAssistAutoUpdate = !mountsHandler.gpsAssistAutoUpdate;
}

-(IBAction)checkUpdates:(id)sender
{
    SUUpdater *updater = [SUUpdater sharedUpdater];
    [updater checkForUpdates:self];
}

-(IBAction)about:(id)sender
{
	NSAlert *alert=[[NSAlert alloc]init];
	[alert setMessageText:[NSString stringWithFormat:@"GPSAssist Update %@\n\nSome legal stuff:\nTHIS SOFTWARE IS PROVIDED \"AS IS\" AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)\nHOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
	[alert addButtonWithTitle:@"OK"];
	[alert runModal];
	[alert release];
}

-(IBAction)exitMenu:(id)sender
{
	[[NSApplication sharedApplication] terminate:self];
}

- (void)updateMounts:(NSMutableArray*)menuItems;
{
	if (mountsMenuItems)
    {
		for(NSMenuItem *item in mountsMenuItems){
			[statusMenu removeItem:item];
		}
	}
    
	[hiddenSeperator setHidden:YES];
    
	// Ask mountsHandler for a list of menuItems for all mounts
	mountsMenuItems = [menuItems copy];
    
	int index=2;
	for (NSMenuItem *item in mountsMenuItems)
    {
		[statusMenu insertItem:item atIndex:index++];
	}
    
    if ([menuItems count] > 0)
    {
        [hiddenSeperator setHidden:NO];
	}
}

-(IBAction)continuePressed:(id)sender
{
	//Store the dontShow-value in the userDefalts
	BOOL dontShow=[dontShowTickBox intValue]==1;
	[[NSUserDefaults standardUserDefaults]setBool:dontShow forKey:hideWelcome];
	[[NSUserDefaults standardUserDefaults]synchronize];
	[window close];
	[self startApplication];
}

@end
