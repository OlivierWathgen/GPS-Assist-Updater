//
//  AboutController.m
//  GPS Assist Updater
//

#import "AboutController.h"

@implementation AboutController

- (id)init
{
    self = [super initWithWindowNibName:@"AboutWindow"];
    if (self)
    {
        
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (IBAction)showLicence:(id)sender
{
    if ([licencePopover isShown])
    {
        [licencePopover close];
    }
    else
    {
       [licencePopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge]; 
    }
}

@end
