using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateTransformByAngle : MonoBehaviour
{
    public float Angle = 60.0f;
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Q))
            transform.localEulerAngles = transform.localEulerAngles + new Vector3(0.0f, Angle, 0.0f);
    }
}
