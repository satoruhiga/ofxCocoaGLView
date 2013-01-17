#pragma once

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>

@interface ofxCocoaGLView : NSOpenGLView {
	CVDisplayLinkRef displayLink;
	NSTimer *updateTimer;
	
@public
	
	bool bEnableSetupScreen;
	int nFrameCount;
	
	BOOL translucent;
	BOOL useDisplayLink;
	
	float targetFrameRate;
	float frameRate;
	
	float lastUpdateTime;
	float lastFrameTime;
	
	float mouseX, mouseY;
}

@property (assign, readonly) float mouseX;
@property (assign, readonly) float mouseY;

- (void)setup;
- (void)update;
- (void)draw;
- (void)exit;

- (void)onKeyPressed:(int)key;
- (void)onKeyReleased:(int)key;
- (void)onMouseMoved:(NSPoint)p;
- (void)onMouseDragged:(NSPoint)p button:(int)button;
- (void)onMousePressed:(NSPoint)p button:(int)button;
- (void)onMouseReleased:(NSPoint)p button:(int)button;
- (void)onWindowResized:(NSSize)size;

//

- (void)setFrameRate:(float)framerate;

- (void)setFullscreen:(BOOL)v;
- (void)toggleFullscreen;

- (void)setTranslucent:(BOOL)v;
- (BOOL)isTranslucent;

- (void)enableDisplayLink:(BOOL)v;
- (void)enableWindowEvents:(BOOL)v;

//

@end
