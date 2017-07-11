
#include "UnityView.h"
#include "UnityAppController.h"
#include "iPhone_OrientationSupport.h"
#include "Unity/GlesHelper.h"
#include "Unity/DisplayManager.h"
#include "Unity/UnityMetalSupport.h"

extern bool	_unityAppReady;


@implementation UnityView
{
	CGSize 				_surfaceSize;
	ScreenOrientation 	_curOrientation;

	BOOL				_recreateView;
}

- (void)onUpdateSurfaceSize:(CGSize)size
{
	_surfaceSize = size;

	CGSize renderSize = CGSizeMake(truncf(size.width * self.contentScaleFactor), truncf(size.height * self.contentScaleFactor));
	UnityReportResizeView(renderSize.width, renderSize.height, ConvertToUnityScreenOrientation(self.contentOrientation, 0));
#if UNITY_CAN_USE_METAL
	if(UnitySelectedRenderingAPI() == apiMetal)
		((CAMetalLayer*)self.layer).drawableSize = renderSize;
#endif
}

- (void)initImpl:(CGRect)frame scaleFactor:(CGFloat)scale
{
	self.multipleTouchEnabled	= YES;
	self.exclusiveTouch			= YES;
	self.contentScaleFactor		= scale;
	if (_ios50orNewer)
	{
		self.isAccessibilityElement = TRUE;
		self.accessibilityTraits = UIAccessibilityTraitAllowsDirectInteraction;
	}

	[self onUpdateSurfaceSize:frame.size];

#if UNITY_CAN_USE_METAL
	if(UnitySelectedRenderingAPI() == apiMetal)
		((CAMetalLayer*)self.layer).framebufferOnly = NO;
#endif
}


- (id)initWithFrame:(CGRect)frame scaleFactor:(CGFloat)scale;
{
	if( (self = [super initWithFrame:frame]) )
		[self initImpl:frame scaleFactor:scale];
	return self;
}
- (id)initWithFrame:(CGRect)frame
{
	if( (self = [super initWithFrame:frame]) )
		[self initImpl:frame scaleFactor:1.0f];
	return self;
}
- (id)initFromMainScreen
{
	CGRect	frame	= [UIScreen mainScreen].bounds;
	CGFloat	scale	= UnityScreenScaleFactor([UIScreen mainScreen]);
	if( (self = [super initWithFrame:frame]) )
		[self initImpl:frame scaleFactor:scale];
	return self;
}


- (void)layoutSubviews
{
	if(_surfaceSize.width != self.bounds.size.width || _surfaceSize.height != self.bounds.size.height)
		_recreateView = YES;
	[self onUpdateSurfaceSize:self.bounds.size];

	[super layoutSubviews];
}

- (void)willRotateTo:(ScreenOrientation)orientation
{
	_curOrientation = orientation;
	AppController_RenderPluginMethodWithArg(@selector(onOrientationChange:), (id)_curOrientation);

	[[NSNotificationCenter defaultCenter] postNotificationName:kUnityViewWillRotate object:self];
}
- (void)didRotate
{
	if(_recreateView)
	{
		// we are not inside repaint so we need to draw second time ourselves
		[self recreateGLESSurface];
		if(_unityAppReady && !UnityIsPaused())
			UnityRepaint();
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:kUnityViewDidRotate object:self];
}


- (ScreenOrientation)contentOrientation
{
	return _curOrientation;
}

- (void)recreateGLESSurfaceIfNeeded
{
	unsigned requestedW, requestedH;	UnityGetRenderingResolution(&requestedW, &requestedH);
	unsigned systemW, systemH;			UnityGetSystemResolution(&systemW, &systemH);
	int requestedMSAA = UnityGetDesiredMSAASampleCount(MSAA_DEFAULT_SAMPLE_COUNT);

	UnityDisplaySurfaceBase* surf = GetMainDisplaySurface();

	if(		surf->use32bitColor != UnityUse32bitDisplayBuffer()
		||	surf->use24bitDepth != UnityUse24bitDepthBuffer()
		||	requestedW != surf->targetW || requestedH != surf->targetH
		||	systemW != surf->systemW || systemH != surf->systemH
		||	(_supportsMSAA && requestedMSAA != surf->msaaSamples)
		||	_recreateView == YES
	  )
	{
		[self recreateGLESSurface];
	}
}

- (void)recreateGLESSurface
{
	extern bool _glesContextCreated;
	extern bool _unityAppReady;
	extern bool _skipPresent;

	if(_glesContextCreated)
	{
		unsigned requestedW, requestedH;
		UnityGetRenderingResolution(&requestedW, &requestedH);

		RenderingSurfaceParams params =
		{
			UnityGetDesiredMSAASampleCount(MSAA_DEFAULT_SAMPLE_COUNT),
			requestedW, requestedH,
			UnityUse32bitDisplayBuffer(), UnityUse24bitDepthBuffer(), false
		};

		AppController_RenderPluginMethodWithArg(@selector(onBeforeMainDisplaySurfaceRecreate:), (id)&params);
		[GetMainDisplay() recreateSurface:params];

		// actually poke unity about updated back buffer and notify that extents were changed
		UnityReportBackbufferChange(GetMainDisplaySurface()->unityColorBuffer, GetMainDisplaySurface()->unityDepthBuffer);

		AppController_RenderPluginMethod(@selector(onAfterMainDisplaySurfaceRecreate));

		if(_unityAppReady)
		{
			// seems like ios sometimes got confused about abrupt swap chain destroy
			// draw 2 times to fill both buffers
			// present only once to make sure correct image goes to CA
			// if we are calling this from inside repaint, second draw and present will be done automatically
			_skipPresent = true;
			if (!UnityIsPaused())
				UnityRepaint();
			_skipPresent = false;
		}
	}

	_recreateView = NO;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	UnitySendTouchesBegin(touches, event);
	[UnityAppController UpdateForce:touches];
}
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	UnitySendTouchesEnded(touches, event);
	[UnityAppController  TouchesEndorCancelled:touches];
}
- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
	UnitySendTouchesCancelled(touches, event);
	[UnityAppController  TouchesEndorCancelled:touches];
}
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	UnitySendTouchesMoved(touches, event);
	[UnityAppController UpdateForce:touches];
}

@end


#include "objc/runtime.h"

static Class UnityRenderingView_LayerClassGLES(id self_, SEL _cmd)
{
	return [CAEAGLLayer class];
}
static Class UnityRenderingView_LayerClassMTL(id self_, SEL _cmd)
{
	return [[NSBundle bundleWithPath:@"/System/Library/Frameworks/QuartzCore.framework"] classNamed:@"CAMetalLayer"];
}

@implementation UnityRenderingView
+ (Class)layerClass
{
	return nil;
}

+ (void)InitializeForAPI:(UnityRenderingAPI)api
{
	IMP layerClassImpl = 0;
	if(api == apiOpenGLES2 || api == apiOpenGLES3)	layerClassImpl = (IMP)UnityRenderingView_LayerClassGLES;
	else if(api == apiMetal)						layerClassImpl = (IMP)UnityRenderingView_LayerClassMTL;

	Method layerClassMethod = class_getClassMethod([UnityRenderingView class], @selector(layerClass));

	if(layerClassMethod)	method_setImplementation(layerClassMethod, layerClassImpl);
	else					class_addMethod([UnityRenderingView class], @selector(layerClass), layerClassImpl, "#8@0:4");
}
@end
