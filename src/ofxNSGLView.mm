#include "ofMain.h"

#include "ofxNSGLView.h"
#include "ofAppBaseWindow.h"

#define BEGIN_OPENGL() \
[[self openGLContext] makeCurrentContext]; \
CGLContextObj cglContext = (CGLContextObj)[[self openGLContext] CGLContextObj]; \
CGLLockContext(cglContext);

#define END_OPENGL() \
CGLUnlockContext(cglContext);

#define OFXNSGLVIEW_IGNORED ofLogWarning("ofxNSGLView") << "operation ignored";

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,  const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext);

class ofxNSGLViewWindowProxy : public ofAppBaseWindow
{
public:
	
	ofxNSGLView *view;
	
	ofxNSGLViewWindowProxy(ofxNSGLView *view_)
	{
		view = view_;
	}
	
	int getWidth()
	{
		return view.bounds.size.width;
	}
	
	int getHeight()
	{
		return view.bounds.size.height;
	}
	
	ofPoint getWindowSize()
	{
		NSSize size = view.bounds.size;
		return ofPoint(size.width, size.height);
	}

	int getFrameNum()
	{
		return view->nFrameCount;
	}
	
	float getFrameRate()
	{
		return view->frameRate;
	}
	
	double getLastFrameTime()
	{
		return view->lastFrameTime;
	}
	
	void setFrameRate(float targetRate)
	{
		[view setFrameRate:targetRate];
	}

	void setFullscreen(bool fullscreen)
	{
		[view setFullscreen:fullscreen];
	}
	
	void toggleFullscreen()
	{
		[view toggleFullscreen];
	}

	void hideCursor()
	{
		[NSCursor hide];
	}
	
	void showCursor()
	{
		[NSCursor unhide];
	}

	void setWindowPosition(int x, int y)
	{
		OFXNSGLVIEW_IGNORED;
	}
	
	void setWindowShape(int w, int h)
	{
		OFXNSGLVIEW_IGNORED;
	}
	
	void setWindowTitle(string title)
	{
		OFXNSGLVIEW_IGNORED;
	}

};

static ofPtr<ofxNSGLViewWindowProxy> window_proxy;

static void setupWindowProxy(ofxNSGLView *view)
{
	if (window_proxy) return;
	window_proxy = ofPtr<ofxNSGLViewWindowProxy>(new ofxNSGLViewWindowProxy(view));
	ofSetupOpenGL(window_proxy, view.bounds.size.width, view.bounds.size.height, OF_WINDOW);
}

static void makeCurrentView(ofxNSGLView *view)
{
	window_proxy->view = view;
}

@interface ofxNSGLView ()
- (void) initGL;
- (void) drawView;
@end

@implementation ofxNSGLView

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self)
	{
		GLint double_buffer = 0;
		[[self pixelFormat] getValues:&double_buffer forAttribute:NSOpenGLPFADoubleBuffer forVirtualScreen:0];
		
		if (double_buffer == 0)
			ofLogWarning("ofxNSGLView") << "double buffer is disabled";
		
		displayLink = NULL;
		
		bEnableSetupScreen = true;
		nFrameCount = 0;
		
		[self setFrameRate:60];
		lastFrameTime = 0;
	}
	
	return self;
}

- (void)dealloc
{	
	[self exit];
	
	CVDisplayLinkRelease(displayLink);
	
	[super dealloc];
}

- (void)setFrameRate:(float)framerate_
{
	targetFrameRate = framerate_;
	frameRate = targetFrameRate;
	
	[self enableDisplayLink:useDisplayLink];
}

- (void)setFullscreen:(BOOL)v
{
	
}

- (void)toggleFullscreen
{
	
}

- (void)enableDisplayLink:(BOOL)v
{
	useDisplayLink = v;
	
	if (displayLink)
	{
		CVDisplayLinkStop(displayLink);
		CVDisplayLinkRelease(displayLink);
		displayLink = NULL;
	}
	
	if (updateTimer)
	{
		[updateTimer invalidate];
		updateTimer = nil;
	}
	
	if (v)
	{
		CGLContextObj cglContext = (CGLContextObj)[[self openGLContext] CGLContextObj];
		CGLPixelFormatObj cglPixelFormat = (CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj];

		CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
		CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);
		
		CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
		
		CVDisplayLinkStart(displayLink);
	}
	else
	{
		float interval = 1. / targetFrameRate;
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
	}
}

- (void)prepareOpenGL
{
	[super prepareOpenGL];
	
	[self initGL];
	
	[self enableDisplayLink:NO];
}

- (void)enableWindowEvents:(BOOL)v
{
	if (v)
	{
		[[self window] makeFirstResponder:self];
		[[self window] setAcceptsMouseMovedEvents:YES];
	}
	else
	{
		if ([[self window] firstResponder] == self)
			[[self window] makeFirstResponder:nil];
	}
}

- (void)initGL
{
	[self enableWindowEvents:YES];

	BEGIN_OPENGL();

	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
	GLenum err = glewInit();
	if (GLEW_OK != err) {
		NSLog(@"GLEW init error... bailing");
		exit(1);
	}

	setupWindowProxy(self);
	
	[self setup];
	ofNotifySetup();
	
	END_OPENGL();
}

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self drawView];
	
	[pool release];
	return kCVReturnSuccess;
}

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
									  const CVTimeStamp* now,
									  const CVTimeStamp* outputTime,
									  CVOptionFlags flagsIn,
									  CVOptionFlags* flagsOut,
									  void* displayLinkContext)
{
    CVReturn result = [(ofxNSGLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (void)drawView
{
	BEGIN_OPENGL();
	
	makeCurrentView(self);
	
	{
		float t = ofGetElapsedTimef();
		lastFrameTime = t - lastUpdateTime;
		float d = 1. / lastFrameTime;
		
		frameRate += (d - frameRate) * 0.1;
		
		lastUpdateTime = t;
	}
	
	[self update];
	ofNotifyUpdate();

	NSRect r = self.bounds;
	ofViewport(0, 0, r.size.width, r.size.height);

	float *bgPtr = ofBgColorPtr();
	bool bClearAuto = ofbClearBg();
	
	if (bClearAuto || nFrameCount < 3)
	{
		float * bgPtr = ofBgColorPtr();
		glClearColor(bgPtr[0], bgPtr[1], bgPtr[2], bgPtr[3]);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}
	
	if (bEnableSetupScreen) ofSetupScreen();
	
	[self draw];
	ofNotifyDraw();
	
	glFlush();
	[[self openGLContext] flushBuffer];
	
	END_OPENGL();
	
	nFrameCount++;
}

- (void)reshape
{
	BEGIN_OPENGL();
	
	makeCurrentView(self);
	
	[[self openGLContext] update];
	
	NSRect r = self.bounds;
	[self onWindowResized:r.size];
	ofNotifyWindowResized(r.size.width, r.size.height);
	
	END_OPENGL();
	
	[self drawView];
}

#pragma mark events

- (NSPoint)pointFromEvent:(NSEvent*)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	return NSMakePoint(p.x, self.bounds.size.height - p.y);
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint p = [self pointFromEvent:theEvent];
	
	makeCurrentView(self);
	
	[self onMousePressed:p button:[theEvent buttonNumber]];
	ofNotifyMousePressed(p.x, p.y, [theEvent buttonNumber]);
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [self pointFromEvent:theEvent];
	
	makeCurrentView(self);
	
	[self onMouseDragged:p button:[theEvent buttonNumber]];
	ofNotifyMouseDragged(p.x, p.y, [theEvent buttonNumber]);
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint p = [self pointFromEvent:theEvent];
	
	makeCurrentView(self);
	
	[self onMouseReleased:p button:[theEvent buttonNumber]];
	ofNotifyMouseReleased(p.x, p.y, [theEvent buttonNumber]);
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	NSPoint p = [self pointFromEvent:theEvent];
	
	makeCurrentView(self);
	
	[self onMouseMoved:p];
	ofNotifyMouseMoved(p.x, p.y);
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSPoint p = [self pointFromEvent:theEvent];
	
	makeCurrentView(self);
	
	[self onMousePressed:p button:[theEvent buttonNumber]];
	ofNotifyMousePressed(p.x, p.y, [theEvent buttonNumber]);
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [self pointFromEvent:theEvent];
	
	makeCurrentView(self);
	
	[self onMouseDragged:p button:[theEvent buttonNumber]];
	ofNotifyMouseDragged(p.x, p.y, [theEvent buttonNumber]);
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	NSPoint p = [self pointFromEvent:theEvent];
	
	makeCurrentView(self);
	
	[self onMouseReleased:p button:[theEvent buttonNumber]];
	ofNotifyMouseReleased(p.x, p.y, [theEvent buttonNumber]);
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
	NSPoint p = [self pointFromEvent:theEvent];
	
	makeCurrentView(self);
	
	[self onMousePressed:p button:[theEvent buttonNumber]];
	ofNotifyMousePressed(p.x, p.y, [theEvent buttonNumber]);
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [self pointFromEvent:theEvent];
	
	makeCurrentView(self);
	
	[self onMouseDragged:p button:[theEvent buttonNumber]];
	ofNotifyMouseDragged(p.x, p.y, [theEvent buttonNumber]);
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
	NSPoint p = [self pointFromEvent:theEvent];
	
	makeCurrentView(self);
	
	[self onMouseReleased:p button:[theEvent buttonNumber]];
	ofNotifyMouseReleased(p.x, p.y, [theEvent buttonNumber]);
}

- (void)keyDown:(NSEvent *)theEvent
{
	const char *c = [[theEvent charactersIgnoringModifiers] UTF8String];
	
	makeCurrentView(self);
	
	[self onKeyPressed:c[0]];
	ofNotifyKeyPressed(c[0]);
}

- (void)keyUp:(NSEvent *)theEvent
{
	const char *c = [[theEvent charactersIgnoringModifiers] UTF8String];
	
	makeCurrentView(self);
	
	[self onKeyReleased:c[0]];
	ofNotifyKeyReleased(c[0]);
}

#pragma mark oF like API

- (void)setup {}
- (void)update {}
- (void)draw {}
- (void)exit {}

- (void)onKeyPressed:(int)key {}
- (void)onKeyReleased:(int)key {}
- (void)onMouseMoved:(NSPoint)p {}
- (void)onMouseDragged:(NSPoint)p button:(int)button {}
- (void)onMousePressed:(NSPoint)p button:(int)button {}
- (void)onMouseReleased:(NSPoint)p button:(int)button {}
- (void)onWindowResized:(NSSize)size {}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (BOOL)resignFirstResponder
{
	return YES;
}

//

- (void)setTranslucent:(BOOL)v
{
	translucent = v;
	
	GLint opt = translucent ? 0 : 1;
	[[self openGLContext] setValues:&opt forParameter:NSOpenGLCPSurfaceOpacity];
}

- (BOOL)isTranslucent
{
	return translucent;
}

- (BOOL)isOpaque
{
	return !translucent;
}

@end
