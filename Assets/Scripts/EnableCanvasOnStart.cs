using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnableCanvasOnStart : MonoBehaviour
{
    void Start()
    {
        if (transform.gameObject != null && transform.gameObject.GetComponent<Canvas>() != null)
        {
            transform.gameObject.GetComponent<Canvas>().enabled = true;
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
