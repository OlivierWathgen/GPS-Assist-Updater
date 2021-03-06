//
//  MountsHandler.h
//  GPS Assist Updater
//
//	Keep a list of mounts
//

#import <Cocoa/Cocoa.h>
#import "GPSAssistDataHandler.h"

@interface MountsHandler : NSObject
{
	NSMutableDictionary  *mounts;
	GPSAssistDataHandler *dataHandler;
	BOOL                 gpsAssistAutoUpdate;
}

@property(nonatomic) BOOL gpsAssistAutoUpdate;

- (id)initWithDataHandler:(GPSAssistDataHandler*)theDataHandler;

@end