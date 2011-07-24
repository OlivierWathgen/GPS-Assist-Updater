//
//  Mount.m
//  DSC-HX5V GPSAssist Update
//

#import "Mount.h"
#import <Growl/Growl.h>

@interface Mount(Private)
-(void)writeConfiguration;
-(void)initGpsAssist;
-(void)updateMenuItemTitle;
@end

static NSString *newDiskNotification=@"New disk detected";
static NSString *mountNotification=@"GPSAssist detected disk";
static NSString *updatedNotification=@"GPSAssist-data updated";
static NSString *updateFailedNotification=@"GPSAssist-data update failed";

static const NSString *configFileName=@".gpsassist.plist";
static const NSString *sonyFolder=@"Private/SONY";
static const NSString *gpsAssistDataFile=@"assistme.dat";
static const NSString *gpsAssistDataFolder=@"Private/SONY/GPS";

static const double GpsAssistUpdateInterval=86400;	//24hours
static const double GpsAssistUpdateRetryInterval=300;	//5 minutes
static const double GpsAssistValidTime=2505600;	//approx 29 days

static const NSString *GpsAssistEnabled=@"enabled";
static const NSString *GpsAssistLastUpdate=@"lastupdate";

static const BOOL showAllDisks=NO;	//if NO it only shows disks with the Private/SONY-path on it

@implementation Mount
@synthesize gpsAssistAutoUpdate;
@dynamic gpsAssistEnabled,gpsAssistLastUpdate,menuItem,hidden;

-(id)initWithPath:(NSString*)mountPath totalSize:(NSNumber*)total dataHandler:(GPSAssistDataHandler*)theDataHandler autoUpdate:(BOOL)autoUpdate{
	if(self=[super init]){
		path=[mountPath retain];
		totalSize=[total retain];
		dataHandler=[theDataHandler retain];
		gpsAssistAutoUpdate=autoUpdate;
		configFile=[[NSString stringWithFormat:@"%@/%@",path,configFileName]retain];
		NSLog(@"Mount created for path:%@ totalSize=%f",path,[totalSize doubleValue]);
		hidden=NO;
		[self initGpsAssist];
	}
	return self;
}

-(void)dealloc{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[path release];
	[totalSize release];
	[dataHandler release];
	[configFile release];
	[configuration release];
	[menuItem release];
	[super dealloc];
}

-(void)showErrorWithText:(NSString*)error{
	NSAlert *alert=[[NSAlert alloc]init];
	[alert setMessageText:error];
	[alert addButtonWithTitle:@"Close"];
	[alert runModal];
	[alert release];
}

-(void)writeConfiguration{
	//Write new configuration to disk (only if it contains keys)
	if([configuration count]>0){
		if(![configuration writeToFile:configFile atomically:YES]){
			[self showErrorWithText:[NSString stringWithFormat:@"Cannot store configuration on disk: %@",path]];
			[configuration release];
			configuration=nil;
		}
	}else{
		[configuration release];
		configuration=nil;
	}
}

-(BOOL)gpsAssistEnabled{
	NSNumber *value=[configuration objectForKey:GpsAssistEnabled];
	if(value){
		return [value boolValue];
	}else{
		return NO;
	}
}

-(void)setGpsAssistEnabled:(BOOL)value{
	[configuration setObject:[NSNumber numberWithBool:value] forKey:GpsAssistEnabled];
	[self writeConfiguration];
}

-(NSDate*)gpsAssistLastUpdate{
	return [configuration objectForKey:GpsAssistLastUpdate];
}

-(void)setGpsAssistLastUpdate:(NSDate*)value{
	if(value!=nil){
		[configuration setObject:value forKey:GpsAssistLastUpdate];
	}else{
		[configuration removeObjectForKey:GpsAssistLastUpdate];
	}
	[self writeConfiguration];
}

-(void)setGpsAssistAutoUpdate:(BOOL)value{
	if(gpsAssistAutoUpdate!=value){
		gpsAssistAutoUpdate=value;
		if(self.gpsAssistEnabled && gpsAssistAutoUpdate){
			//Check if the lastUpdate was more than 24 hours ago
			NSDate *lastUpdate=[self gpsAssistLastUpdate];
			if(lastUpdate==nil || [[NSDate date]timeIntervalSinceDate:lastUpdate]>GpsAssistUpdateInterval){
				[self updateGpsAssistData];
			}
		}
	}
}

-(NSString*)totalSizeAsString{
	double size=[totalSize doubleValue];
	//Not real KBs? As in 1024 bytes
	if(size>1000000000){
		return [NSString stringWithFormat:@"%.2f GB",size/1000000000];
	}else if(size>1000000){
		return [NSString stringWithFormat:@"%.2f MB",size/1000000];
	}else if(size>1000){
		return [NSString stringWithFormat:@"%.2f KB",size/1000];
	}else{
		return [NSString stringWithFormat:@"%f Bytes",size];
	}
}

-(NSString*)lastUpdateAsString{
	NSDate* lastUpdate=self.gpsAssistLastUpdate;
	if(lastUpdate==nil){
		return @"No GPSAssist-data";
	}else{
		NSDateFormatter *formatter=[[[NSDateFormatter alloc]init]autorelease];
		[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[formatter setDateStyle:NSDateFormatterMediumStyle];
		[formatter setTimeStyle:NSDateFormatterNoStyle];
		return [formatter stringFromDate:lastUpdate];
	}
}

-(NSString*)validTimeAsString{
	NSDate* lastUpdate=self.gpsAssistLastUpdate;
	if(lastUpdate==nil){
		return @"No GPSAssist-data";
	}else{
		NSDate *validDate=[lastUpdate addTimeInterval:GpsAssistValidTime];
		NSDateFormatter *formatter=[[[NSDateFormatter alloc]init]autorelease];
		[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[formatter setDateStyle:NSDateFormatterMediumStyle];
		[formatter setTimeStyle:NSDateFormatterNoStyle];
		return [formatter stringFromDate:validDate];
	}
}

-(void)sendGrowlNotification:(NSString*)message title:(NSString*)title notificationName:(NSString*)notificationName{
	[GrowlApplicationBridge notifyWithTitle:title
	  description:message
	  notificationName:(NSString *)notificationName
	  iconData:nil
	  priority:0
	  isSticky:NO
	  clickContext:nil];
}

-(void)initGpsAssist{
	//Check if the configfile is already on the disk
	BOOL newDisk=YES;
	NSFileManager *fileManager=[NSFileManager defaultManager];
	if([fileManager fileExistsAtPath:configFile]){
		//Ok, we did see this disk before. Read the configuration.
		configuration=[[NSMutableDictionary alloc]initWithContentsOfFile:configFile];
		if(configuration!=nil){
			newDisk=NO;
		}else{
			//Illegal configfile detected. Remove it. Nobody should be using this filename (bit drastic)
			if(![fileManager removeFileAtPath:configFile handler:nil]){
				[self showErrorWithText:[NSString stringWithFormat:@"Cannot remove invalid configuration file: %@",configFileName]];
				return;
			}
		}
	}
	if(newDisk){
		//This is a new disk, ask the user what to do with it.
		configuration=[[NSMutableDictionary alloc]init];
		//If the new disk contains directories that are created when the card is formatted in a DSC-HX5 then make YES the default button.
		//Otherwise make NO the default button.
		NSString *message=nil;	//TODO: localized string
		BOOL isSony=NO;
		BOOL isDirectory=NO;
		if([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",path,sonyFolder] isDirectory:&isDirectory] && isDirectory){
			message=[NSString stringWithFormat:@"New removable media was detected. It looks like removable media that is used in a Sony camera. Do you want to update the GpsAssist-data on this device?\nName:\t%@\nSize:\t%@",[path lastPathComponent],[self totalSizeAsString]];
			isSony=YES;
		}else{
			message=[NSString stringWithFormat:@"New removable media was detected. It is not recognized as removable media that is used in a Sony camera. Do you still want to update the GpsAssist-data on this device?\nName:\t%@\nSize:\t%@",[path lastPathComponent],[self totalSizeAsString]];
		}
		
		NSAlert *alert=[[NSAlert alloc]init];
		[alert setMessageText:message];
		if(isSony){
			[alert addButtonWithTitle:@"Yes"];
			[alert addButtonWithTitle:@"Not now"];
		}else if(showAllDisks){
			[alert addButtonWithTitle:@"Not now"];
			[alert addButtonWithTitle:@"Yes"];
		}
		if(isSony || showAllDisks){
			[self sendGrowlNotification:@"A new disk is detected. Please specify what to do with it." title:newDiskNotification notificationName:newDiskNotification];
			NSInteger result=[alert runModal];
			if(isSony){
				switch(result){
					case NSAlertFirstButtonReturn:
						//Enable updates
						[configuration setObject:[NSNumber numberWithBool:YES] forKey:GpsAssistEnabled];
						break;
					case NSAlertSecondButtonReturn:
						//Not now
						[configuration setObject:[NSNumber numberWithBool:NO] forKey:GpsAssistEnabled];
						break;
				}
			}else{
				switch(result){
					case NSAlertFirstButtonReturn:
						//Enable updates
						[configuration setObject:[NSNumber numberWithBool:YES] forKey:GpsAssistEnabled];
						break;
					case NSAlertThirdButtonReturn:
						//Not now
						[configuration setObject:[NSNumber numberWithBool:NO] forKey:GpsAssistEnabled];
						break;
				}
			}
			[self writeConfiguration];
			[alert release];
		}else{
			hidden=YES;
		}
	}
	if(!newDisk){
		[self sendGrowlNotification:[path lastPathComponent] title:mountNotification notificationName:mountNotification];
	}
	//Check if gpsassist-data is still on the disk
	NSDate *lastUpdate=[self gpsAssistLastUpdate];
	NSString *targetFile=[NSString stringWithFormat:@"%@/%@/%@",path,gpsAssistDataFolder,gpsAssistDataFile];
	if(![fileManager fileExistsAtPath:targetFile]){
		if(lastUpdate!=nil){
			[self setGpsAssistLastUpdate:nil];
			lastUpdate=nil;
		}
	}
	
	//Process mount according to configuration (existing or new)
	if(self.gpsAssistEnabled && gpsAssistAutoUpdate){
		//Check if the lastUpdate was more than 24 hours ago
		if(lastUpdate==nil || [[NSDate date]timeIntervalSinceDate:lastUpdate]>GpsAssistUpdateInterval){
			[self updateGpsAssistData];
		}
	}
}

-(void)updateGpsAssistData{
	// Ask the GpsAssistData for new data. It is asynchronous since it must be retrieved from the server
	[dataHandler getGpsAssistData:self];
}

-(void)stop{
	//Stop any pending gpsassist-updates, drive is unmounted
	NSLog(@"Mount %@ is unmounted",path);
	[dataHandler cancelGetGpsAssistData:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

-(void)updateMenuItemTitle{
	[menuItem setTitle:[NSString stringWithFormat:@"%@ - %@ - %@",[path lastPathComponent],[self totalSizeAsString], [self validTimeAsString]]];
}

-(NSMenuItem*)menuItem{
	if(hidden){
		return nil;
	}
	if(menuItem==nil){
		menuItem=[[NSMenuItem alloc]initWithTitle:@"" action:@selector(menuClicked) keyEquivalent:@""];
		[self updateMenuItemTitle];
		[menuItem setState:self.gpsAssistEnabled?NSOnState:NSOffState];
		[menuItem setEnabled:YES];
		[menuItem setTarget:self];
	}
	return menuItem;
}

-(void)menuClicked{
	//Show an alert with the options to enable/disable, update now or cancel
	NSAlert *alert=[[NSAlert alloc]init];
	NSString *message;
	if(self.gpsAssistEnabled){
		message=[NSString stringWithFormat:@"Do you want to disable the update of GpsAssist-data on this device?\nName:\t\t%@\nSize:\t\t%@\nLast update:\t%@",[path lastPathComponent],[self totalSizeAsString],[self lastUpdateAsString]];
		[alert addButtonWithTitle:@"Disable"];
	}else{
		message=[NSString stringWithFormat:@"Do you want to enable the update of GpsAssist-data on this device?\nName:\t\t%@\nSize:\t\t%@\nLast update:\t%@",[path lastPathComponent],[self totalSizeAsString],[self lastUpdateAsString]];
		[alert addButtonWithTitle:@"Enable"];
	}
	[alert setMessageText:message];
	[alert addButtonWithTitle:@"Update now"];
	[alert addButtonWithTitle:@"Cancel"];
	NSInteger result=[alert runModal];
	switch(result){
		case NSAlertFirstButtonReturn:
			//Toggle updates
			if(self.gpsAssistEnabled){
				self.gpsAssistEnabled=NO;
				[menuItem setState:NSOffState];
				[NSObject cancelPreviousPerformRequestsWithTarget:self];
				[dataHandler cancelGetGpsAssistData:self];
			}else{
				self.gpsAssistEnabled=YES;
				[menuItem setState:NSOnState];
				if(gpsAssistAutoUpdate){
					//Check if the lastUpdate was more than 24 hours ago
					NSDate *lastUpdate=[self gpsAssistLastUpdate];
					if(lastUpdate==nil || [[NSDate date]timeIntervalSinceDate:lastUpdate]>GpsAssistUpdateInterval){
						[self updateGpsAssistData];
					}
				}
			}
			break;
		case NSAlertSecondButtonReturn:
			[self updateGpsAssistData];
			break;
		case NSAlertThirdButtonReturn:
			//Nothing
			break;
	}
	[alert release];
}

#pragma mark GPSAssistDataHandlerDelegate
-(void)gpsAssistDataAvailable:(NSData*)gpsAssistData date:(NSDate*)downloadDate{
	//Write the data to disk. Create folder if needed
	NSFileManager *fileManager=[NSFileManager defaultManager];
	BOOL isDirectory=NO;
	NSString *targetFolder=[NSString stringWithFormat:@"%@/%@",path,gpsAssistDataFolder];
	if(![fileManager fileExistsAtPath:targetFolder isDirectory:&isDirectory]){
		//Create target folder
		NSError *error=nil;
		if(![fileManager createDirectoryAtPath:targetFolder withIntermediateDirectories:YES attributes:nil error:&error]){
			[self showErrorWithText:[NSString stringWithFormat:@"Cannot create directory %@",targetFolder]];
			return;
		}
	}else if(!isDirectory){
		[self showErrorWithText:[NSString stringWithFormat:@"Cannot create directory %@, a file with the same name already exists.",targetFolder]];
		return;
	}
	//Write data to file
	NSString *targetFile=[NSString stringWithFormat:@"%@/%@",targetFolder,gpsAssistDataFile];
	if(![gpsAssistData writeToFile:targetFile atomically:YES]){
		[self showErrorWithText:[NSString stringWithFormat:@"Cannot write GPSAssist-data to file: %@",targetFile]];
	}else{
		//write ok, update lastUpdate
		[self setGpsAssistLastUpdate:downloadDate];
		//Update menu, data is loaded
		[self updateMenuItemTitle];
		//Schedule next update
		[self performSelector:@selector(updateGpsAssistData) withObject:nil afterDelay:GpsAssistUpdateInterval];
		//Growl it
		[self sendGrowlNotification:[NSString stringWithFormat:@"Disk %@: valid until %@",[path lastPathComponent],[self validTimeAsString]] title:updatedNotification notificationName:updatedNotification];
	}
}

-(void)gpsAssistDataFailed{
	[self sendGrowlNotification:[NSString stringWithFormat:@"GPSAssist-data update failed for disk %@",[path lastPathComponent]] title:updateFailedNotification notificationName:updateFailedNotification];
	if(gpsAssistAutoUpdate){
		[self performSelector:@selector(updateGpsAssistData) withObject:nil afterDelay:GpsAssistUpdateRetryInterval];
	}else{
		[self showErrorWithText:[NSString stringWithFormat:@"Disk %@ failed",path]];
	}
}

@end
