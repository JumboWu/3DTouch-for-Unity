//
//Add By Jumbo
//


#import "UnityAppController.h"



typedef void (*registerTouchEventCallbackFunc)(float, float);

@interface UnityAppController(For3DTouch)

+(void)UpdateForce:(NSSet<UITouch *> *) touches;
+(void)TouchesEndorCancelled:(NSSet<UITouch *>*) touches;

-(BOOL)IsForceTouchCapability;
@end

#if defined(__cplusplus)
extern "C"{
#endif

extern bool _isForceTouchCapability();
extern void _registerTouchEventCallback(registerTouchEventCallbackFunc func);

#if defined(__cplusplus)
}
#endif
