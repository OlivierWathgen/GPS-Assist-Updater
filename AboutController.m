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
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *complete = [NSString stringWithFormat:@"%@%@", [version stringValue], currentVersion];
    [version setStringValue:complete];
    NSLog(@"%@",[version stringValue]);
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
