using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StereoSingleCam : MonoBehaviour
{
    public Light[] lights;
 
    //void Start()
    //{
    //    if (lights == null || lights.Length <= 0)
    //    {
    //        lights = transform.parent.GetComponentsInChildren<Light>();
    //    }        
    //}

    //private void EnableLights(bool enable)
    //{
    //    if (lights == null || lights.Length <= 0)
    //    {
    //        for(int i=0; i<lights.Length; i++)
    //        {
    //            if (lights[i] != null)
    //                lights[i].enabled = enable;
    //        }
    //    }
    //}

    //void OnPreCull()
    //{
    //    if (lights == null || lights.Length <= 0)
    //        EnableLights(true);
    //}

    //void OnPreRender()
    //{
    //    EnableLights(true);
    //}
    //void OnPostRender()
    //{
    //   // EnableLights(false);
    //}
}
