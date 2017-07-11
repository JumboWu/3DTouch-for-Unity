//
//Add By Jumbo
//


#import "UnityAppController+For3DTouch.h"

static BOOL isSupport3DTouch = NO;
static registerTouchEventCallbackFunc touchEventCallback = nil;

@implementation UnityAppController(For3DTouch)


-(void)registerTouchEventCallback:(registerTouchEventCallbackFunc) func
{
   touchEventCallback = func;
}

-(BOOL)IsForceTouchCapability
{
	if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0)
	{
	   isSupport3DTouch = NO;
	   return false;
	}
	
	if (self.rootViewController.view.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)
	{
		isSupport3DTouch = YES;
		return true;
	}
	else
	{
		isSupport3DTouch = NO;
		return false;
	}
}

+(void)UpdateForce:(NSSet<UITouch *>*) touches
{
	if (isSupport3DTouch && touchEventCallback != nil)
	{
		touchEventCallback(touches.anyObject.force, touches.anyObject.maximumPossibleForce);
	}
}

+(void)TouchesEndorCancelled:(NSSet<UITouch *>*) touches
{
	if (isSupport3DTouch && touchEventCallback != nil)
	{
		touchEventCallback(0, touches.anyObject.maximumPossibleForce);
	}
}

@end

#if defined(__cplusplus)
extern "C"{
#endif

bool _isForceTouchCapability()
{
    return [(UnityAppController *)[UIApplication sharedApplication].delegate IsForceTouchCapability];
}

void _registerTouchEventCallback(registerTouchEventCallbackFunc func)
{
   [(UnityAppController *)[UIApplication sharedApplication].delegate registerTouchEventCallback:func];
}


#if defined(__cplusplus)
}
#endif