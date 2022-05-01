// Patrol.cs
using UnityEngine;
using UnityEngine.AI;
using System.Collections;
using System.Collections.Generic;


public class Patrol : MonoBehaviour
{
    public List<Transform> points;
    private int destPoint = 0;
    private NavMeshAgent agent;

    public float TargetRadius = 1.0f;

    public float TimeInCurrentPoint = 0.0f;
    public float CurrentPointTimeLimit = 3.0f;

    public float TimeOnPathToNextPoint = 0.0f;
    public float TimeOnPathLimit = 15.0f;

    public float MinTimeInPoint = 10.0f;
    public float MaxTimeInPoint = 20.0f;
    void Start()
    {
        agent = GetComponent<NavMeshAgent>();

        // Disabling auto-braking allows for continuous movement
        // between points (ie, the agent doesn't slow down as it
        // approaches a destination point).
        //agent.autoBraking = false;

        GotoNextPoint();
    }


    void GotoNextPoint()
    {
        // Returns if no points have been set up
        if (points.Count == 0)
            return;

        // Set the agent to go to the currently selected destination.
        agent.destination = points[destPoint].position;

        // Choose the next point in the array as the destination,
        // cycling to the start if necessary.
        destPoint = (destPoint + 1) % points.Count;

        TimeInCurrentPoint = 0.0f;
        TimeOnPathToNextPoint = 0.0f;
        CurrentPointTimeLimit = Random.Range(MinTimeInPoint, MaxTimeInPoint);
    }


    void Update()
    {
        if (!agent.pathPending)
        {
            if (agent.remainingDistance < TargetRadius)
            {
                TimeInCurrentPoint += Time.deltaTime;

                if (TimeInCurrentPoint >= CurrentPointTimeLimit)
                    GotoNextPoint();
            }
            else
            {
                TimeOnPathToNextPoint += Time.deltaTime;
                if (TimeOnPathToNextPoint >= TimeOnPathLimit)
                    GotoNextPoint();
            }
        }


        NavMeshPath path = agent.path;
        if (path != null && path.status == NavMeshPathStatus.PathComplete && agent.remainingDistance >= TargetRadius)
        {
            int length = path.corners.Length;
            Vector3 posTarget = new Vector3(path.corners[length - 1].x, 0.0f, path.corners[length - 1].z);
            Vector3 posCurrent = new Vector3(transform.position.x, 0.0f, transform.position.z);
            Quaternion finalRot = Quaternion.LookRotation(posTarget - posCurrent, Vector3.up);
            transform.rotation = Quaternion.Slerp(transform.rotation, finalRot, Time.deltaTime); // LookAt(LookAt(agent.0.0f, 1.0f, 0.0f);
        }
    }
}