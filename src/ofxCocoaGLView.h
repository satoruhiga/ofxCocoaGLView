#pragma once

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>

@interface ofxCocoaGLView : NSOpenGLView <NSWindowDelegate> {
	CVDisplayLinkRef displayLink;
	NSTimer *updateTimer;

@public

	bool initialised;

	bool enableSetupScreen;
	int frameCount;

	BOOL translucent;
	BOOL useDisplayLink;

	float targetFrameRate;
	float frameRate;

	float lastUpdateTime;
	float lastFrameTime;

	id globalMonitorHandler;
	id localMonitorHandler;

	NSTrackingRectTag trackingRectTag;

	float mouseX, mouseY;
	float width, height;
	
	float aspect;
}

@property (assign, readonly) float mouseX;
@property (assign, readonly) float mouseY;
@property (assign, readonly) float width;
@property (assign, readonly) float height;

+ (NSOpenGLContext*)sharedContext;
+ (void)lockSharedContext;
+ (void)unlockSharedContext;

- (void)setup;
- (void)update;
- (void)draw;
- (void)exit;

- (void)keyPressed:(int)key;
- (void)keyReleased:(int)key;
- (void)mouseMoved:(NSPoint)p;
- (void)mouseDragged:(NSPoint)p button:(int)button;
- (void)mousePressed:(NSPoint)p button:(int)button;
- (void)mouseReleased:(NSPoint)p button:(int)button;
- (void)windowResized:(NSSize)size;

- (void)mouseEntered;
- (void)mouseExited;

- (void)beginWindowEvent;
- (void)endWindowEvent;

//

- (void)setFrameRate:(float)framerate;

- (void)setFullscreenTo:(NSScreen*)screen;
- (void)exitFullscreen;
- (void)setFullscreen:(BOOL)v;
- (void)toggleFullscreen;

- (void)setTranslucent:(BOOL)v;
- (BOOL)isTranslucent;

- (void)enableDisplayLink:(BOOL)v;
- (void)enableWindowEvents:(BOOL)v;

- (void)setKeepAspect:(float)aspect;

//

@end
