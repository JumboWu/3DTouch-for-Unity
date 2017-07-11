# UnityFor3DTouch
A plugin for Unity to support 3DTouch


Unity 5以前的版本是不支持3DTouch的，需要手动编写Objective-C代码来实现与Unity交互。
先介绍下iOS 3DTouch相关知识：
### 1、支持以下三种运用
![3DTouch](http://upload-images.jianshu.io/upload_images/191918-a7c02fb37e0743ee.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
       a、Quick Actions 快捷选项标签
       b、Peek and Pop 展示预览 跳转到预览页面
       c、Pressure Sensitivity 压力值

【官方介绍】https://developer.apple.com/ios/3d-touch/
###2、Pressure Sensitivity 介绍
前面两种就不介绍了，一般应用都支持，主要讲下压力值的运用，这个在游戏里面可以做一些操控。例如：王者荣耀 技能重压力取消操作

首先我们在Unity里面需要有两个接口或属性：
1、bool IsForceTouchCapability() : 3DTouch支持判断
2、bool IsForcePressTouch : 是否重压，这里取大于0.5

3、For3DTouch.cs //中间件Unity上层调用
```
using UnityEngine;
using System;
using System.Collections;
using System.Runtime.InteropServices;
using AOT;

//3DTouch 单例
public class For3DTouch : Singleton<For3DTouch>
{
    private bool _isForcePressTouch = false;
    public bool IsForcePressTouch
    {
        get
        {
            return _isForcePressTouch;
        }
    }

    public  For3DTouch()
    {
        RegisterTouchEventCallback();
    }

#if UNITY_EDITOR || UNITY_ANDROID
   
   private  void RegisterTouchEventCallback(Action<float, float> func = null)
   {
   
   }

     
   public  bool IsForceTouchCapability()
   {
       return false;
   }

#elif UNITY_IPHONE

    private delegate void touch_event_callback_delegate(float force, float maximumPossibleforce);

    private  Action<float, float> touchEventCallback;



   private  void  RegisterTouchEventCallback(Action<float, float> func = null)
   {
       touchEventCallback = func;
	   _registerTouchEventCallback(TouchEventCallback);
   }
   
   public  bool IsForceTouchCapability()
   {
       return _isForceTouchCapability();
   }
   	

   //OC回调过来的压力值
   [MonoPInvokeCallback(typeof(touch_event_callback_delegate))]
   private static void TouchEventCallback(float force, float maximumPossibleforce)
   {
       For3DTouch.Instance()._isForcePressTouch = (force / maximumPossibleforce) > 0.5;
       if (For3DTouch.Instance().touchEventCallback != null)
           For3DTouch.Instance().touchEventCallback(force, maximumPossibleforce);
   }

   //注册重压回调
   [DllImport("__Internal")]
   private static extern void _registerTouchEventCallback(touch_event_callback_delegate func);
   //3DTouch支持判断
   [DllImport("__Internal")]
   private static extern bool _isForceTouchCapability();   
   
   
#endif
}
```
4、新建Objective-C代码 3DTouch Native Code：
UnityAppController+For3DTouch.h //UnityAppController 子类
```
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
```
UnityAppController+For3DTouch.mm
```
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
```
5、UnityView.mm修改 Unity自己写的，我们需要改动一下，监控Touch操作事件,反馈给Unity注册过来的回调接口
```
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	UnitySendTouchesBegin(touches, event);
	[UnityAppController UpdateForce:touches];//Add
}
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	UnitySendTouchesEnded(touches, event);
	[UnityAppController  TouchesEndorCancelled:touches];//Add
}
- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
	UnitySendTouchesCancelled(touches, event);
	[UnityAppController  TouchesEndorCancelled:touches];//Add
}
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	UnitySendTouchesMoved(touches, event);
	[UnityAppController UpdateForce:touches];//Add
}
```

###3、集成到Unity项目
a、For3DTouch.cs拷贝到Plugins目录下 Singleton.cs 单例之前的文章有了，就不再上传，可以关注之前的文章
b、UnityAppController+For3DTouch.h UnityAppController+For3DTouch.mm拷贝到Plugins\iOS目录下
c、UnityView.mm 覆盖到导出的XCode工程目录：Classes\UI




