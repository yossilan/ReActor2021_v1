using UnityEngine;

public class WebcamHandler : MonoBehaviour
{
    public MeshRenderer theWebcamRenderer;

    [SerializeField]
    public WebCamDevice[] devices;

    void Start()
    {
        devices = WebCamTexture.devices;

        if (devices == null ||  devices.Length <= 0)
        {
            Debug.Log("-I- No Matching Webcam Found. Webcam Textures Disabled!");
            return;
        }

        // for debugging purposes, prints available devices to the console
        bool foundMatchingName = false;
        for(int i = 0; i < devices.Length; i++)
        {
            if (devices[i].name.Contains("USB Camera"))
            {
                foundMatchingName = true;
                Debug.Log("Webcam available: " + devices[i].name);
            }
        }

        if (!foundMatchingName)
        {
            Debug.Log("-I- No Matching Webcam Found. Webcam Textures Disabled!");
            return;
        }


        // assuming the first available WebCam is desired
        if (theWebcamRenderer == null)
            theWebcamRenderer = this.GetComponentInChildren<MeshRenderer>();

        WebCamTexture tex = new WebCamTexture(devices[devices.Length-1].name, 320, 240, 30);

        if (theWebcamRenderer != null && tex != null)
        {
            //theWebcamRenderer.material.mainTexture = tex;
            theWebcamRenderer.material.SetTexture("_EmissionMap", tex);
            tex.Play();
        }
    }
}
