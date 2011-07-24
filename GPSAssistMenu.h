//
//  GPSAssistMenu.h
//  DSC-HX5V GPSAssist Update
//
//	Handles the status-menu
//

#import <Cocoa/Cocoa.h>

@class MountsHandler;

@interface GPSAssistMenu : NSObject {
	NSMenuItem *statusMenuItem;
	NSMenu *statusMenu;
	MountsHandler *mountsHandler;
	NSMenuItem *autoUpdateItem;
	NSArray *mountsMenuItems;
	NSMenuItem *mountsBottomSeparator;
	BOOL autoUpdate;
}

@property(assign) MountsHandler *mountsHandler;
@property(readonly) BOOL autoUpdate;

-(void)updateMounts:(NSArray*)menuItems;

@end
