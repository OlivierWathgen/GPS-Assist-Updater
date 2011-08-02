//
//  MountsHandler.m
//  GPS Assist Updater
//

#import <Cocoa/Cocoa.h>
#import "MountsHandler.h"
#import "Mount.h"
#import "GPSAssistAppDelegate.h"

@interface MountsHandler(Private)
- (void)initMounts;
- (void)createMountFromPath:(NSString*)mountPath;
- (void)updateMenu;
@end


@implementation MountsHandler

@synthesize gpsAssistAutoUpdate;

- (id)initWithDataHandler:(GPSAssistDataHandler*)theDataHandler
{
    self = [super init];
    if (self)
    {
		GPSAssistAppDelegate *menu = (GPSAssistAppDelegate*) [[NSApplication sharedApplication] delegate];
		gpsAssistAutoUpdate = menu.autoUpdate;
		dataHandler = theDataHandler;
		[[[NSWorkspace sharedWorkspace]notificationCenter]addObserver:self selector:@selector(mount:) name:NSWorkspaceDidMountNotification object:nil];
		[[[NSWorkspace sharedWorkspace]notificationCenter]addObserver:self selector:@selector(unmount:) name:NSWorkspaceWillUnmountNotification object:nil];
		[self initMounts];
	}
	return self;
}

- (void)initMounts{
	mounts = [[NSMutableDictionary alloc] init];
	NSArray *mountedDisks = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
	for (NSString *mountPath in mountedDisks)
    {
		[self createMountFromPath:mountPath];
	}
}

- (void)createMountFromPath:(NSString*)mountPath
{
	// A mount is an unmountable writable device
	BOOL isRemovable;
	BOOL isWritable;
	BOOL isUnmountable;
	NSString *description;
	NSString *fsType;
	NSNumber *free  = nil;
	NSNumber *total = nil;
	NSError  *error = nil;

	[[NSWorkspace sharedWorkspace] getFileSystemInfoForPath:mountPath isRemovable:&isRemovable isWritable:&isWritable isUnmountable:&isUnmountable description:&description type:&fsType];
	NSDictionary *info = [[NSFileManager defaultManager] attributesOfFileSystemForPath:mountPath error:&error];
	if (info)
    {
		free  = (NSNumber*)[info objectForKey:NSFileSystemFreeSize];	// +868560896 = 868.5MB
		total = (NSNumber*)[info objectForKey:NSFileSystemSize];		// +1028075520= 1.03GB
	}
	NSLog(@"mount: %@ removable:%d writable:%d unmountable:%d description:%@ fstype:%@", mountPath, isRemovable, isWritable, isUnmountable, description, fsType);
	NSLog(@"free=%fMB total=%fMB",[free doubleValue]/(1024*1024), [total doubleValue]/(1024*1024));
	if (isRemovable && isWritable && isUnmountable)
    {
		if ([mounts objectForKey:mountPath] == nil)
        {
			// Create a mount for this path
			Mount *mount = [[Mount alloc] initWithPath:mountPath totalSize:total dataHandler:dataHandler autoUpdate:gpsAssistAutoUpdate];
			[mounts setObject:mount forKey:mountPath];
			// The mounts are changed, update the menu
			[self updateMenu];
		}
        else
        {
			NSLog(@"Error: multiple mounts with same path: %@", mountPath);
		}
	}
}

- (void)mount:(NSNotification*)notification
{
	NSDictionary *userInfo = [notification userInfo];
	NSString *mountPath = [userInfo objectForKey:@"NSDevicePath"];
	if (mountPath)
    {
		[self createMountFromPath:mountPath];
	}
    else{
		NSLog(@"Error: mounted unknown path");
	}
}

- (void)unmount:(NSNotification*)notification
{
	NSDictionary *userInfo = [notification userInfo];
	NSString *mountPath = [userInfo objectForKey:@"NSDevicePath"];
	NSLog(@"unmount: %@",mountPath);
	Mount *mount = [mounts objectForKey:mountPath];
	if (mount)
    {
		[mount stop];
		[mounts removeObjectForKey:mountPath];
		[self updateMenu];
	}
    else
    {
		NSLog(@"Unmounted unknown mount: %@", mountPath);
	}
}

- (void)updateMenu
{
	NSMutableArray *items = [NSMutableArray arrayWithCapacity:[mounts count]];
	for (id key in mounts)
    {
		Mount *mount = [mounts objectForKey:key];
		NSMenuItem *mountMenuItem = mount.menuItem;
		if (mountMenuItem)
        {
            // Ignore hidden mounts (no Private/SONY folder)
			[items addObject:mount.menuItem];
		}
	}
    GPSAssistAppDelegate *menu = (GPSAssistAppDelegate*) [[NSApplication sharedApplication] delegate];
	[menu updateMounts:items];
}

- (void)setGpsAssistAutoUpdate:(BOOL)value
{
	if (gpsAssistAutoUpdate != value)
    {
		gpsAssistAutoUpdate = value;
        
		// Update all mounts
		for (id key in mounts) {
			Mount *mount=[mounts objectForKey:key];
			mount.gpsAssistAutoUpdate = gpsAssistAutoUpdate;
		}
	}
}

@end
