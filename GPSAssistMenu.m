//
//  GPSAssistMenu.m
//  DSC-HX5V GPSAssist Update
//

#import "GPSAssistMenu.h"
#import "MountsHandler.h"

@interface GPSAssistMenu(Private)
-(void)initMenu;
@end

static NSString *disableAutoUpdate=@"disableAutoUpdate";

@implementation GPSAssistMenu
@synthesize mountsHandler,autoUpdate;

-(id)init{
	if(self=[super init]){
		[self initMenu];
	}
	return self;
}

-(void)dealloc{
	[statusMenuItem release];
	[statusMenu release];
	[mountsBottomSeparator release];
	[mountsMenuItems release];
	[autoUpdateItem release];
	[super dealloc];
}

-(void)initMenu{
	NSImage *statusMenuImage=[NSImage imageNamed:@"gps_small.png"];
	statusMenuItem=[[[NSStatusBar systemStatusBar] statusItemWithLength:[statusMenuImage size].width] retain];
	[statusMenuItem setImage:statusMenuImage];
	statusMenu=[[NSMenu alloc]initWithTitle:@""];
	[statusMenu setAutoenablesItems:NO];
	[statusMenuItem setMenu:statusMenu];
	
	autoUpdateItem=[[statusMenu addItemWithTitle:@"Auto update GPSAssist-data" action:@selector(autoUpdateMenu) keyEquivalent:@""]retain];
	if([[NSUserDefaults standardUserDefaults]boolForKey:disableAutoUpdate]){
		[autoUpdateItem setState:NSOffState];
		autoUpdate=NO;
	}else{
		//no setting or enabled
		[autoUpdateItem setState:NSOnState];
		autoUpdate=YES;
	}
	[autoUpdateItem setEnabled:YES];
	[autoUpdateItem setTarget:self];
	
	[statusMenu addItem:[NSMenuItem separatorItem]];

	NSMenuItem *item=[statusMenu addItemWithTitle:@"About" action:@selector(about) keyEquivalent:@""];
	[item setEnabled:YES];
	[item setTarget:self];

	[statusMenu addItem:[NSMenuItem separatorItem]];
	
	item=[statusMenu addItemWithTitle:@"Exit" action:@selector(exitMenu) keyEquivalent:@""];
	[item setEnabled:YES];
	[item setTarget:self];
}

-(void)autoUpdateMenu{
	if(autoUpdate){
		autoUpdate=NO;
		[autoUpdateItem setState:NSOffState];
		mountsHandler.gpsAssistAutoUpdate=NO;
		[[NSUserDefaults standardUserDefaults]setBool:YES forKey:disableAutoUpdate];
	}else{
		autoUpdate=YES;
		[autoUpdateItem setState:NSOnState];
		mountsHandler.gpsAssistAutoUpdate=YES;
		[[NSUserDefaults standardUserDefaults]setBool:NO forKey:disableAutoUpdate];
	}
}

-(void)about{
	NSAlert *alert=[[NSAlert alloc]init];
	[alert setMessageText:[NSString stringWithFormat:@"GPSAssist Update %@\n\nSome legal stuff:\nTHIS SOFTWARE IS PROVIDED \"AS IS\" AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)\nHOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
	[alert addButtonWithTitle:@"OK"];
	[alert runModal];
	[alert release];
}

-(void)exitMenu{
	[[NSApplication sharedApplication]terminate:self];
}

-(void)updateMounts:(NSArray*)menuItems{
	if(mountsMenuItems!=nil){
		for(NSMenuItem *item in mountsMenuItems){
			[statusMenu removeItem:item];
		}
		[mountsMenuItems release];
	}
	if(mountsBottomSeparator!=nil && [mountsBottomSeparator menu]!=nil){
		[statusMenu removeItem:mountsBottomSeparator];
	}
	//Ask mountsHandler for a list of menuItems for all mounts
	mountsMenuItems=[menuItems retain];
	int index=2;
	for(NSMenuItem *item in mountsMenuItems){
		[statusMenu insertItem:item atIndex:index++];
	}
	if([mountsMenuItems count]>0){
		if(mountsBottomSeparator==nil){
			mountsBottomSeparator=[[NSMenuItem separatorItem]retain];
		}
		[statusMenu insertItem:mountsBottomSeparator atIndex:index];
	}
}

@end
