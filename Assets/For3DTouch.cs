//
//Add By Jumbo
//


using UnityEngine;
using System;
using System.Collections;
using System.Runtime.InteropServices;
using AOT;

public class For3DTouch : Singleton<For3DTouch>
{
#if UNITY_EDITOR
    public static void RegisterTouchEventCallback(Action<float, float> func)
    {
       
    }

    public static bool IsForceTouchCapability()
    {
        return false;
    }
#elif UNITY_IPHONE

    private delegate void touch_event_callback_delegate(float force, float maximumPossibleforce);

    private static Action<float, float> touchEventCallback;



   public static void RegisterTouchEventCallback(Action<float, float> func)
   {
       touchEventCallback = func;
	   _registerTouchEventCallback(TouchEventCallback);
   }
   
   public static bool IsForceTouchCapability()
   {
       return _isForceTouchCapability();
   }
   	

   [MonoPInvokeCallback(typeof(touch_event_callback_delegate))]
   private static void TouchEventCallback(float force, float maximumPossibleforce)
   {
      touchEventCallback(force, maximumPossibleforce);
   }


   [DllImport("__Internal")]
   private static extern void _registerTouchEventCallback(touch_event_callback_delegate func);
   
   [DllImport("__Internal")]
   private static extern bool _isForceTouchCapability();   
   
   
#endif
}