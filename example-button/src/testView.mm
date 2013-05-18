#import "testView.h"
#include <stdlib.h>

@implementation testView

- (void)setup
{
    int r = 255;
    int g = 0;
    int b = 0;
}

- (void)update
{
}

- (void)draw
{
    ofBackground(r, g, b);
	
	ofNoFill();
	ofSetColor(255);
	ofCircle(self.mouseX, self.mouseY, 100);

}

- (void)exit
{
	
}

-(void)changeColor:(id)sender
{
    r = arc4random() % 255;
    g = arc4random() % 255;
    b = arc4random() % 255;
}

- (void)keyPressed:(int)key
{
	
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