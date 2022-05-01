using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FollowMovingActors : MonoBehaviour
{
    public List<Transform> ActiveActors;

    public Transform ActorsRoot;

    public Vector3 ActiveActorsAverage;
    
    void Start()
    {
        GameObject actorsRootGO = GameObject.Find("/Actors");

        if (actorsRootGO != null)
        {
            ActorsRoot = actorsRootGO.transform;

            if (ActorsRoot != null)
            {
                Transform[] allActors = ActorsRoot.GetComponentsInChildren<Transform>(false);

                if (allActors != null && allActors.Length > 0)
                {
                    for (int i = 0; i < allActors.Length; i++)
                    {
                        if (allActors[i] != null && allActors[i].name == "Bip01 Pelvis")
                            ActiveActors.Add(allActors[i]);
                    }
                }
            }
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (ActiveActors == null || ActiveActors.Count <= 0)
            return;

        ActiveActorsAverage = Vector3.zero;
        for(int i=0; i<ActiveActors.Count; i++)
        {
            if (ActiveActors[i] != null)
            {
                ActiveActorsAverage = new Vector3(ActiveActors[i].position.x, 1.5f, ActiveActors[i].position.z);// - ActiveActors[i].parent.parent.position.z;
                //Debug.Log("Position: " + ActiveActors[i].position.ToString("F2"));
            }
        }

        ActiveActorsAverage /= (float)ActiveActors.Count;

        Vector3 targetPosition = ActiveActorsAverage + 10.0f * Vector3.forward;
        float currentLerp = Mathf.Lerp(0.00005f, 0.003f, (targetPosition - transform.position).magnitude / 3.0f);
        transform.position = Vector3.Lerp(transform.position, targetPosition, currentLerp);
    }
}
