//
//  AboutController.h
//  GPS Assist Updater
//

#import <Cocoa/Cocoa.h>

@interface AboutController : NSWindowController
{
    IBOutlet NSButton  *licence;
    IBOutlet NSPopover *licencePopover;
}

- (IBAction)showLicence:(id)sender;

@end
