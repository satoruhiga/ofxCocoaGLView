#include "ofMain.h"

#include "ofxNSGLView.h"
#include "ofAppBaseWindow.h"

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,  const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext);

static bool bEnableSetupScreen = true;
static int nFrameCount = 0;

class ofxNSGLViewWindowProxy : public ofAppBaseWindow
{
public:
	
	NSView *view;
	
	ofxNSGLViewWindowProxy(NSView *view_)
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
};

static ofPtr<ofxNSGLViewWindowProxy> window_proxy;

static void setCurrentWindow(NSView *view)
{
	window_proxy = ofPtr<ofxNSGLViewWindowProxy>(new ofxNSGLViewWindowProxy(view));
	ofSetupOpenGL(window_proxy, view.frame.size.width, view.frame.size.height, OF_WINDOW);
}


@interface ofxNSGLView ()
- (void) initGL;
- (void) drawView;
+ (NSOpenGLPixelFormat*)getPixelFormat;
@end

@implementation ofxNSGLView

+ (NSOpenGLPixelFormat*)getPixelFormat
{
	NSOpenGLPixelFormatAttribute attrs[] =
	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
#if ESSENTIAL_GL_PRACTICES_SUPPORT_GL3 
		NSOpenGLPFAOpenGLProfile,
		NSOpenGLProfileVersion3_2Core,
#endif
		0
	};
	
	return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
}

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect pixelFormat:[ofxNSGLView getPixelFormat]];
	
	if (self)
	{
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self)
	{
		[self setPixelFormat:[ofxNSGLView getPixelFormat]];
	}
	
	return self;
}

- (void) dealloc
{	
	[self exit];
	
	CVDisplayLinkRelease(displayLink);
	
	[super dealloc];
}

- (void) prepareOpenGL
{
	[super prepareOpenGL];
	
	[self initGL];
	
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);
	
	CGLContextObj cglContext = (CGLContextObj)[[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = (CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	
	CVDisplayLinkStart(displayLink);
}

- (void) initGL
{
	[[self openGLContext] makeCurrentContext];

	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
	[[self window] makeFirstResponder:self];
	
	ofSetCurrentRenderer(ofPtr<ofBaseRenderer>(new ofGLRenderer()));
	setCurrentWindow(self);
	
	[self setup];
	ofNotifySetup();
}

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self drawView];
	
	[pool release];
	return kCVReturnSuccess;
}

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    CVReturn result = [(ofxNSGLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (void) drawView
{	 
	[[self openGLContext] makeCurrentContext];
	
	CGLContextObj cglContext = (CGLContextObj)[[self openGLContext] CGLContextObj];
	
	CGLLockContext(cglContext);
	
	[self update];
	ofNotifyUpdate();

	
	NSRect b = self.bounds;
	ofViewport(0, 0, b.size.width, b.size.height);
	float * bgPtr = ofBgColorPtr();
	bool bClearAuto = ofbClearBg();
	
	if (bClearAuto == true || nFrameCount < 3)
	{
		ofClear(bgPtr[0]*255,bgPtr[1]*255,bgPtr[2]*255, bgPtr[3]*255);
	}
		
	if(bEnableSetupScreen) ofSetupScreen();
	
	[self draw];
	ofNotifyDraw();
	
	CGLFlushDrawable(cglContext);
	CGLUnlockContext(cglContext);
	
	nFrameCount++;
}

- (void) reshape
{	
	[super reshape];
	
	CGLContextObj cglContext = (CGLContextObj)[[self openGLContext] CGLContextObj];
	CGLLockContext(cglContext);
	
	NSRect rect = [self bounds];
	[self onWindowResized:rect.size];
	CGLUnlockContext(cglContext);
}

#pragma mark events

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMousePressed:p button:[theEvent buttonNumber]];
	ofNotifyMousePressed(p.x, p.y, [theEvent buttonNumber]);
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseDragged:p button:[theEvent buttonNumber]];
	ofNotifyMouseDragged(p.x, p.y, [theEvent buttonNumber]);
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseReleased:p button:[theEvent buttonNumber]];
	ofNotifyMouseReleased(p.x, p.y, [theEvent buttonNumber]);
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseMoved:p];
	ofNotifyMouseMoved(p.x, p.y);
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMousePressed:p button:[theEvent buttonNumber]];
	ofNotifyMousePressed(p.x, p.y, [theEvent buttonNumber]);
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseDragged:p button:[theEvent buttonNumber]];
	ofNotifyMouseDragged(p.x, p.y, [theEvent buttonNumber]);
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseReleased:p button:[theEvent buttonNumber]];
	ofNotifyMouseReleased(p.x, p.y, [theEvent buttonNumber]);
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMousePressed:p button:[theEvent buttonNumber]];
	ofNotifyMousePressed(p.x, p.y, [theEvent buttonNumber]);
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseDragged:p button:[theEvent buttonNumber]];
	ofNotifyMouseDragged(p.x, p.y, [theEvent buttonNumber]);
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseReleased:p button:[theEvent buttonNumber]];
	ofNotifyMouseReleased(p.x, p.y, [theEvent buttonNumber]);
}

- (void)keyDown:(NSEvent *)theEvent
{
	const char *c = [[theEvent charactersIgnoringModifiers] UTF8String];
	[self onKeyPressed:c[0]];
	ofNotifyKeyPressed(c[0]);
}

- (void)keyUp:(NSEvent *)theEvent
{
	const char *c = [[theEvent charactersIgnoringModifiers] UTF8String];
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

@end
