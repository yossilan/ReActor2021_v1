using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TorchInput : MonoBehaviour
{
    public SerialReaderWriter theSerialReader;
    public Vector3 CurrentEuler = Vector3.zero;

    public Vector3 SmoothEuler = Vector3.zero;

    public Vector3 CalibrationEuler = Vector3.zero;

    public Reaktion.JitterMotion aJitter;

    void Start()
    {
        aJitter = transform.GetComponent<Reaktion.JitterMotion>();
        if (aJitter != null)
            aJitter.enabled = false;
    }

    void Update()
    {
        if (theSerialReader != null && theSerialReader.LatestSerialValues != null && theSerialReader.LatestSerialValues.Length == 3)
        {
            CurrentEuler = new Vector3(theSerialReader.LatestSerialValues[0], -theSerialReader.LatestSerialValues[1], 0.0f);
            SmoothEuler = SmoothEuler * 0.9f + CurrentEuler * 0.1f;

            float x = Mathf.Clamp(SmoothEuler.x, CalibrationEuler.x - 25.0f, CalibrationEuler.x + 25.0f);
            float y = Mathf.Clamp(SmoothEuler.y, CalibrationEuler.y - 35.0f, CalibrationEuler.y + 35.0f);

            transform.localRotation = Quaternion.Euler(SmoothEuler - CalibrationEuler);
        }

        if (Input.GetKeyDown(KeyCode.T))
            CalibrationEuler = SmoothEuler;

        if (Input.GetKeyDown(KeyCode.Space) && aJitter != null)
            aJitter.enabled = !aJitter.enabled;
    }
}
