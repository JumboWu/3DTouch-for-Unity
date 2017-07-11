using UnityEngine;
using System.Collections;
using UnityEngine.UI;

public class UIMain : MonoBehaviour {

	// Use this for initialization
    public Text text0;
    public Text text1;
    public Text text2;
	void Start () {
        //text1.text = "1";
        //text2.text = "2";
        if (For3DTouch.IsForceTouchCapability())
        {
            text0.text = "3DTouch support";
        }
        else
        {
            text0.text = "3DTouch not support";
        }

        For3DTouch.RegisterTouchEventCallback(TouchEventCallback);
	}
	
	// Update is called once per frame
	void Update () {
	
	}

    void TouchEventCallback(float force, float maximumPossibleforce)
    {
        text1.text = "force:" + force;
        text2.text = "maximumPossibleforce:" + maximumPossibleforce;
    }
}
