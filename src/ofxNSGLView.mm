#include "ofMain.h"

#include "ofxNSGLView.h"

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext);

@interface ofxNSGLView ()
- (void) initGL;
- (void) drawView;
+ (NSOpenGLPixelFormat*)getPixelFormat;
@end

@implementation ofxNSGLView

@synthesize enableOfNotifiy;

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
	self.enableOfNotifiy = NO;
	
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
	
	[self setup];
	if (enableOfNotifiy) ofNotifySetup();
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
	
	glClearColor(0, 0, 0, 0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	[self update];
	if (enableOfNotifiy) ofNotifyUpdate();
	
	[self draw];
	if (enableOfNotifiy) ofNotifyDraw();
	
	CGLFlushDrawable(cglContext);
	CGLUnlockContext(cglContext);
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
	if (enableOfNotifiy) ofNotifyMousePressed(p.x, p.y, [theEvent buttonNumber]);
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseDragged:p button:[theEvent buttonNumber]];
	if (enableOfNotifiy) ofNotifyMouseDragged(p.x, p.y, [theEvent buttonNumber]);
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseReleased:p button:[theEvent buttonNumber]];
	if (enableOfNotifiy) ofNotifyMouseReleased(p.x, p.y, [theEvent buttonNumber]);
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseMoved:p];
	if (enableOfNotifiy) ofNotifyMouseMoved(p.x, p.y);
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMousePressed:p button:[theEvent buttonNumber]];
	if (enableOfNotifiy) ofNotifyMousePressed(p.x, p.y, [theEvent buttonNumber]);
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseDragged:p button:[theEvent buttonNumber]];
	if (enableOfNotifiy) ofNotifyMouseDragged(p.x, p.y, [theEvent buttonNumber]);
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseReleased:p button:[theEvent buttonNumber]];
	if (enableOfNotifiy) ofNotifyMouseReleased(p.x, p.y, [theEvent buttonNumber]);
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMousePressed:p button:[theEvent buttonNumber]];
	if (enableOfNotifiy) ofNotifyMousePressed(p.x, p.y, [theEvent buttonNumber]);
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseDragged:p button:[theEvent buttonNumber]];
	if (enableOfNotifiy) ofNotifyMouseDragged(p.x, p.y, [theEvent buttonNumber]);
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p.y = self.bounds.size.height - p.y;
	[self onMouseReleased:p button:[theEvent buttonNumber]];
	if (enableOfNotifiy) ofNotifyMouseReleased(p.x, p.y, [theEvent buttonNumber]);
}

- (void)keyDown:(NSEvent *)theEvent
{
	const char *c = [[theEvent charactersIgnoringModifiers] UTF8String];
	[self onKeyPressed:c[0]];
	if (enableOfNotifiy) ofNotifyKeyPressed(c[0]);
}

- (void)keyUp:(NSEvent *)theEvent
{
	const char *c = [[theEvent charactersIgnoringModifiers] UTF8String];
	[self onKeyReleased:c[0]];
	if (enableOfNotifiy) ofNotifyKeyReleased(c[0]);
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
