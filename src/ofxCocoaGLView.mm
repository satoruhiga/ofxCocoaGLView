#include "ofMain.h"

#include "ofxCocoaGLView.h"
#include "ofAppBaseWindow.h"

#define BEGIN_OPENGL() \
[[self openGLContext] makeCurrentContext]; \
CGLContextObj cglContext = (CGLContextObj)[[self openGLContext] CGLContextObj]; \
CGLLockContext(cglContext);

#define END_OPENGL() \
CGLUnlockContext(cglContext);

#define OFXCOCOAGLVIEW_IGNORED ofLogWarning("ofxNSGLView") << "operation ignored";

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,  const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext);

class ofxCocoaGLViewWindowProxy : public ofAppBaseWindow
{
public:
	
	ofxCocoaGLView *view;
	
	ofxCocoaGLViewWindowProxy(ofxCocoaGLView *view_)
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
		OFXCOCOAGLVIEW_IGNORED;
	}
	
	void setWindowShape(int w, int h)
	{
		OFXCOCOAGLVIEW_IGNORED;
	}
	
	void setWindowTitle(string title)
	{
		OFXCOCOAGLVIEW_IGNORED;
	}

};

static ofPtr<ofxCocoaGLViewWindowProxy> window_proxy;

static void setupWindowProxy(ofxCocoaGLView *view)
{
	if (window_proxy) return;
	window_proxy = ofPtr<ofxCocoaGLViewWindowProxy>(new ofxCocoaGLViewWindowProxy(view));
	ofSetupOpenGL(window_proxy, view.bounds.size.width, view.bounds.size.height, OF_WINDOW);
}

static void makeCurrentView(ofxCocoaGLView *view)
{
	window_proxy->view = view;
}

static NSOpenGLContext *_context = nil;

@interface ofxCocoaGLView ()
- (void) initGL;
- (void) drawView;
@end

@implementation ofxCocoaGLView

@synthesize mouseX, mouseY;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self)
	{
		initialised = NO;
		
		if (_context == nil)
		{
			_context = [self openGLContext];
		}
		else
		{
			self.openGLContext = [[NSOpenGLContext alloc] initWithFormat:self.pixelFormat shareContext:_context];
		}
		
		GLint double_buffer = 0;
		[self.pixelFormat getValues:&double_buffer forAttribute:NSOpenGLPFADoubleBuffer forVirtualScreen:0];
		
		if (double_buffer == 0)
			ofLogWarning("ofxCocoaGLView") << "double buffer is disabled";
		
		displayLink = NULL;
		
		bEnableSetupScreen = true;
		nFrameCount = 0;
		
		[self setFrameRate:60];
		lastFrameTime = 0;
		
		[NSEvent addLocalMonitorForEventsMatchingMask:NSMouseMovedMask handler:^(NSEvent *e) {
			[self _mouseMoved:e];
			return e;
		}];

		[NSEvent addGlobalMonitorForEventsMatchingMask:NSMouseMovedMask handler:^(NSEvent *e) {
			[self _mouseMoved:e];
		}];

		// setup terminate notification
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self
			   selector:@selector(appWillTerminate:)
				   name:NSApplicationWillTerminateNotification
				 object:NSApp];
	}
	
	return self;
}

- (void)appWillTerminate:(id)sender
{
	[self exit];
	
	if (displayLink)
	{
		CVDisplayLinkStop(displayLink);
		CVDisplayLinkRelease(displayLink);
	}
}

- (void)dealloc
{	
	[self exit];
	
	if (displayLink)
	{
		CVDisplayLinkStop(displayLink);
		CVDisplayLinkRelease(displayLink);
	}

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
	}
	else
	{
		[[self window] makeFirstResponder:nil];
	}
}

- (void)initGL
{
	[self enableWindowEvents:YES];
	
	// init mouse pos
	NSPoint p = [self.window convertScreenToBase:[NSEvent mouseLocation]];
	NSPoint m = [self convertPoint:p fromView:nil];
	mouseX = m.x;
	mouseY = self.frame.size.height - m.y;

	BEGIN_OPENGL();

	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
	GLenum err = glewInit();
	if (GLEW_OK != err)
	{
		NSLog(@"GLEW init error... bailing");
		exit(1);
	}

	setupWindowProxy(self);
	
	[self setup];
	ofNotifySetup();
	
	initialised = YES;
	
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
    CVReturn result = [(ofxCocoaGLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (void)drawView
{
	if (!initialised) return;
	
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
	[self windowResized:r.size];
	ofNotifyWindowResized(r.size.width, r.size.height);
	
	END_OPENGL();
	
	[self drawView];
}

#pragma mark events

- (NSPoint)getCurrentMousePos
{
	NSPoint p = [self.window convertScreenToBase:[NSEvent mouseLocation]];
	p = [self convertPoint:p fromView:nil];
	p.y = self.bounds.size.height - p.y;
	
	mouseX = p.x;
	mouseY = p.y;
	
	return p;
}

static int conv_button_number(int n)
{
	static int table[] = {0, 2, 1};
	return table[n];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint p = [self getCurrentMousePos];
	
	makeCurrentView(self);
	
	int b = conv_button_number([theEvent buttonNumber]);
	[self mousePressed:p button:b];
	ofNotifyMousePressed(p.x, p.y, b);
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [self getCurrentMousePos];
	
	makeCurrentView(self);
	
	int b = conv_button_number([theEvent buttonNumber]);
	[self mouseDragged:p button:b];
	ofNotifyMouseDragged(p.x, p.y, b);
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint p = [self getCurrentMousePos];
	
	makeCurrentView(self);
	
	int b = conv_button_number([theEvent buttonNumber]);
	[self mouseReleased:p button:b];
	ofNotifyMouseReleased(p.x, p.y, b);
}

- (void)_mouseMoved:(NSEvent *)theEvent
{
	NSPoint p = [self getCurrentMousePos];
	
	makeCurrentView(self);
	
	[self mouseMoved:p];
	ofNotifyMouseMoved(p.x, p.y);
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSPoint p = [self getCurrentMousePos];
	
	makeCurrentView(self);
	
	int b = conv_button_number([theEvent buttonNumber]);
	[self mousePressed:p button:b];
	ofNotifyMousePressed(p.x, p.y, b);
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [self getCurrentMousePos];
	
	makeCurrentView(self);
	
	int b = conv_button_number([theEvent buttonNumber]);
	[self mouseDragged:p button:b];
	ofNotifyMouseDragged(p.x, p.y, b);
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	NSPoint p = [self getCurrentMousePos];
	
	makeCurrentView(self);
	
	int b = conv_button_number([theEvent buttonNumber]);
	[self mouseReleased:p button:b];
	ofNotifyMouseReleased(p.x, p.y, b);
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
	NSPoint p = [self getCurrentMousePos];
	
	makeCurrentView(self);
	
	int b = conv_button_number([theEvent buttonNumber]);
	[self mousePressed:p button:b];
	ofNotifyMousePressed(p.x, p.y, b);
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [self getCurrentMousePos];
	
	makeCurrentView(self);
	
	int b = conv_button_number([theEvent buttonNumber]);
	[self mouseDragged:p button:b];
	ofNotifyMouseDragged(p.x, p.y, b);
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
	NSPoint p = [self getCurrentMousePos];
	
	makeCurrentView(self);
	
	int b = conv_button_number([theEvent buttonNumber]);
	[self mouseReleased:p button:b];
	ofNotifyMouseReleased(p.x, p.y, b);
}

- (void)keyDown:(NSEvent *)theEvent
{
	const char *c = [[theEvent charactersIgnoringModifiers] UTF8String];
	int key = c[0];
	
	makeCurrentView(self);
	
	if (key == OF_KEY_ESC)
	{
		[[NSApplication sharedApplication] terminate:self];
		[NSApp terminate:self];
	}
	
	[self keyPressed:key];
	ofNotifyKeyPressed(key);
}

- (void)keyUp:(NSEvent *)theEvent
{
	const char *c = [[theEvent charactersIgnoringModifiers] UTF8String];
	int key = c[0];
	
	makeCurrentView(self);
	
	[self keyReleased:key];
	ofNotifyKeyReleased(key);
}

- (void)mouseEntered:(NSEvent *)event
{
	[self mouseEntered];
}

- (void)mouseExited:(NSEvent *)event
{
	[self mouseExited];
}

#pragma mark oF like API

- (void)setup {}
- (void)update {}
- (void)draw {}
- (void)exit {}

- (void)keyPressed:(int)key {}
- (void)keyReleased:(int)key {}
- (void)mouseMoved:(NSPoint)p {}
- (void)mouseDragged:(NSPoint)p button:(int)button {}
- (void)mousePressed:(NSPoint)p button:(int)button {}
- (void)mouseReleased:(NSPoint)p button:(int)button {}
- (void)windowResized:(NSSize)size {}

- (void)mouseEntered {}
- (void)mouseExited {}

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

- (void)_surfaceNeedsUpdate:(NSNotification*)notification
{
	if (!initialised) return;
	[self update];
}

@end
