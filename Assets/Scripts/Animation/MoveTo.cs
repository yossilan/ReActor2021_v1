using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class MoveTo : MonoBehaviour
{
    public Transform goal;

    private NavMeshAgent agent; 

    void Start()
    {
        agent = GetComponent<NavMeshAgent>();
    }

    private void Update()
    {
        if (agent != null && goal != null)
            agent.destination = goal.position;
    }
}
