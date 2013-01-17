#import "testView1.h"

@implementation testView1

- (void)setup
{
}

- (void)update
{
}

- (void)draw
{
	ofBackground(255, 0, 0);
	
	ofSetColor(255);
	ofCircle(self.mouseX, self.mouseY, 100);
	
	string str = "View1: " + ofToString(self.mouseX) +  " " + ofToString(self.mouseY);
	ofDrawBitmapString(str, 10, 20);
}

- (void)exit
{
	
}

- (void)keyPressed:(int)key
{
	
}

- (void)keyReleased:(int)key
{
	
}

- (void)mouseMoved_:(NSPoint)p
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