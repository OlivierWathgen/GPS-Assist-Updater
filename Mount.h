//
//  Mount.h
//  DSC-HX5V GPSAssist Update
//
//	Handles one mount
//

#import <Cocoa/Cocoa.h>
#import "GPSAssistDataHandler.h"
#import "GPSAssistDataHandlerDelegate.h"

@interface Mount : NSObject <GPSAssistDataHandlerDelegate> {
	NSString *path;
	NSNumber *totalSize;
	GPSAssistDataHandler *dataHandler;
	NSString *configFile;
	NSMutableDictionary *configuration;
	BOOL gpsAssistAutoUpdate;
	NSMenuItem *menuItem;
	BOOL hidden;
}

@property BOOL gpsAssistEnabled;
@property(readonly) NSDate *gpsAssistLastUpdate;
@property BOOL gpsAssistAutoUpdate;
@property(readonly) NSMenuItem *menuItem;
@property(readonly) BOOL hidden;

-(id)initWithPath:(NSString*)mountPath totalSize:(NSNumber*)totalSize dataHandler:(GPSAssistDataHandler*)dataHandler autoUpdate:(BOOL)autoUpdate;
-(void)updateGpsAssistData;
-(void)stop;

@end
