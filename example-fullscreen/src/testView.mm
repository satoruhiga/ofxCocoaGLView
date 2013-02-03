#import "testView.h"

@implementation testView

- (void)setup
{
	[self setFullscreen:YES];
}

- (void)update
{
}

- (void)draw
{
	ofDrawBitmapString("if press any key to toggle fullscreen", 10, 20);
}

- (void)exit
{
	
}

- (void)keyPressed:(int)key
{
	[self toggleFullscreen];
}

- (void)keyReleased:(int)key
{
	
}

- (void)mouseMoved:(NSPoint)p
{
	
}

- (void)mouseDragged:(NSPoint)p button:(int)button
{
	
}

- (void)mousePressed:(NSPoint)p button:(int)button
{
	
}

- (void)mouseReleased:(NSPoint)p button:(int)button
{
	
}

- (void)windowResized:(NSSize)size
{
	
}

@end