//
//  MountsHandler.m
//  DSC-HX5V GPSAssist Update
//

#import "MountsHandler.h"
#import "Mount.h"

@interface MountsHandler(Private)
-(void)initMounts;
-(void)createMountFromPath:(NSString*)mountPath;
-(void)updateMenu;
@end


@implementation MountsHandler
@synthesize gpsAssistAutoUpdate;

-(id)initWithMenu:(GPSAssistMenu*)theMenu dataHandler:(GPSAssistDataHandler*)theDataHandler{
	if(self=[super init]){
		menu=[theMenu retain];
		gpsAssistAutoUpdate=menu.autoUpdate;
		dataHandler=[theDataHandler retain];
		[[[NSWorkspace sharedWorkspace]notificationCenter]addObserver:self selector:@selector(mount:) name:NSWorkspaceDidMountNotification object:nil];
		[[[NSWorkspace sharedWorkspace]notificationCenter]addObserver:self selector:@selector(unmount:) name:NSWorkspaceWillUnmountNotification object:nil];
		[self initMounts];
	}
	return self;
}

-(void)dealloc{
	[[NSNotificationCenter defaultCenter]removeObserver:self];
	for (id key in mounts) {
		Mount *mount=[mounts objectForKey:key];
		[mount stop];
	}
	[mounts release];
	[menu release];
	[super dealloc];
}

-(void)initMounts{
	mounts=[[NSMutableDictionary alloc]init];
	NSArray *mountedDisks=[[NSWorkspace sharedWorkspace]mountedRemovableMedia];
	for(NSString *mountPath in mountedDisks){
		[self createMountFromPath:mountPath];
	}
}

-(void)createMountFromPath:(NSString*)mountPath{
	// a mount is an unmountable writable device
	BOOL isRemovable;
	BOOL isWritable;
	BOOL isUnmountable;
	NSString *description;
	NSString *fsType;
	NSNumber *free=nil;
	NSNumber *total=nil;
	NSError *error=nil;

	[[NSWorkspace sharedWorkspace]getFileSystemInfoForPath:mountPath isRemovable:&isRemovable isWritable:&isWritable isUnmountable:&isUnmountable description:&description type:&fsType];
	NSDictionary *info = [[NSFileManager defaultManager]attributesOfFileSystemForPath:mountPath error:&error];
	if(info!=nil){
		free=(NSNumber*)[info objectForKey:NSFileSystemFreeSize];	// +868560896 = 868.5MB
		total=(NSNumber*)[info objectForKey:NSFileSystemSize];		// +1028075520= 1.03GB
	}
	NSLog(@"mount: %@ removable:%d writable:%d unmountable:%d description:%@ fstype:%@",mountPath,isRemovable,isWritable,isUnmountable,description,fsType);
	NSLog(@"free=%fMB total=%fMB",[free doubleValue]/(1024*1024), [total doubleValue]/(1024*1024));
	if(isRemovable&&isWritable&&isUnmountable){
		if([mounts objectForKey:mountPath]==nil){
			//Create a mount for this path
			Mount *mount=[[Mount alloc]initWithPath:mountPath totalSize:total dataHandler:dataHandler autoUpdate:gpsAssistAutoUpdate];
			[mounts setObject:mount forKey:mountPath];
			//The mounts are changed, update the menu
			[self updateMenu];
			[mount release];
		}else{
			NSLog(@"Error: multiple mounts with same path: %@",mountPath);
		}
	}
}

-(void)mount:(NSNotification*)notification{
	NSDictionary *userInfo = [notification userInfo];
	NSString *mountPath = [userInfo objectForKey:@"NSDevicePath"];
	if(mountPath){
		[self createMountFromPath:mountPath];
	}else{
		NSLog(@"Error: mounted unknown path");
	}
}

-(void)unmount:(NSNotification*)notification{
	NSDictionary *userInfo = [notification userInfo];
	NSString *mountPath = [userInfo objectForKey:@"NSDevicePath"];
	NSLog(@"unmount: %@",mountPath);
	Mount *mount=[mounts objectForKey:mountPath];
	if(mount!=nil){
		[mount stop];
		[mounts removeObjectForKey:mountPath];
		[self updateMenu];
	}else{
		NSLog(@"Unmounted unknown mount: %@",mountPath);
	}
}

-(void)updateMenu{
	NSMutableArray *items=[NSMutableArray arrayWithCapacity:[mounts count]];
	for (id key in mounts) {
		Mount *mount=[mounts objectForKey:key];
		NSMenuItem *mountMenuItem=mount.menuItem;
		if(mountMenuItem!=nil){	//ignore hidden mounts (no Private/SONY folder)
			[items addObject:mount.menuItem];
		}
	}
	[menu updateMounts:items];
}

-(void)setGpsAssistAutoUpdate:(BOOL)value{
	if(gpsAssistAutoUpdate!=value){
		gpsAssistAutoUpdate=value;
		//update all mounts
		for (id key in mounts) {
			Mount *mount=[mounts objectForKey:key];
			mount.gpsAssistAutoUpdate=gpsAssistAutoUpdate;
		}
	}
}

@end
