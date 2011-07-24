//
//  MountsHandler.h
//  DSC-HX5V GPSAssist Update
//
//	Keep a list of mounts
//

#import <Cocoa/Cocoa.h>
#import "GPSAssistMenu.h"
#import "GPSAssistDataHandler.h"

@interface MountsHandler : NSObject {
	NSMutableDictionary *mounts;
	GPSAssistMenu *menu;
	GPSAssistDataHandler *dataHandler;
	BOOL gpsAssistAutoUpdate;
}

@property BOOL gpsAssistAutoUpdate;

-(id)initWithMenu:(GPSAssistMenu*)menu dataHandler:(GPSAssistDataHandler*)dataHandler;

@end
