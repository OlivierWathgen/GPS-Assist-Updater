//
//  AboutController.h
//  GPS Assist Updater
//

#import <Cocoa/Cocoa.h>

@interface AboutController : NSWindowController
{
    IBOutlet NSButton    *licence;
    IBOutlet NSPopover   *licencePopover;
    IBOutlet NSTextField *version;
}

- (IBAction)showLicence:(id)sender;

@end
