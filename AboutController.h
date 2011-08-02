//
//  AboutController.h
//  GPS Assist Updater
//
//  Created by Olivier Wathgen on 2/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AboutController : NSWindowController
{
    IBOutlet NSButton  *licence;
    IBOutlet NSPopover *licencePopover;
}

- (IBAction)showLicence:(id)sender;

@end
