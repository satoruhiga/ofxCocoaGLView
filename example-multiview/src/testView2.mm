#import "testView2.h"

@implementation testView2

- (void)setup
{
}

- (void)update
{
}

- (void)draw
{
	ofBackground(0, 255, 0);
	
	ofSetColor(255);
	ofCircle(self.mouseX, self.mouseY, 100);
	
	string str = "View2: " + ofToString(self.mouseX) +  " " + ofToString(self.mouseY);
	ofDrawBitmapString(str, 10, 20);
}

- (void)exit
{
	
}

- (void)onKeyPressed:(int)key
{
	
}

- (void)onKeyReleased:(int)key
{
	
}

- (void)onMouseMoved:(NSPoint)p
{
	
}

- (void)onMouseDragged:(NSPoint)p button:(int)button
{
	
}

- (void)onMousePressed:(NSPoint)p button:(int)button
{
	
}

- (void)onMouseReleased:(NSPoint)p button:(int)button
{
	
}

- (void)onWindowResized:(NSSize)size
{
	
}

@end