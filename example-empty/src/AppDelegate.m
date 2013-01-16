#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSLog(@"%@", self.window.contentView);
}

@end
