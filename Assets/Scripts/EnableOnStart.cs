using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnableOnStart : MonoBehaviour
{
    public List<Transform> TransformsToEnable;

    void Start()
    {
        for (int i = 0; i < TransformsToEnable.Count; i++)
        {
            if (TransformsToEnable[i] != null && TransformsToEnable[i].gameObject != null)
            {
                TransformsToEnable[i].gameObject.SetActive(true);
            }
        }
    }

    void Update()
    {
        
    }
}
