using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class NavigationAgentsTest : MonoBehaviour
{
    public List<NavMeshAgent> agents;
    public List<Transform> walls;
    public Transform floor;
    public int NumWallsToPatrol = 4;

    void Start()
    {
        agents = new List<NavMeshAgent>(GetComponentsInChildren<NavMeshAgent>());

        foreach (NavMeshAgent agent in agents)
        {
            Patrol patroler = agent.gameObject.GetComponent<Patrol>();
            
            int wallsOnPath = 0;
            int newWallIndex = Random.Range(0, walls.Count);

            while (wallsOnPath<NumWallsToPatrol)
            {
                newWallIndex = (newWallIndex + Random.Range(1, walls.Count)) % walls.Count;
                if (!patroler.points.Contains(walls[newWallIndex]))
                {
                    patroler.points.Add(walls[newWallIndex]);
                    wallsOnPath++;
                }
            }

            patroler.points.Add(floor);
        }

    }

    void Update()
    {
        //foreach(NavMeshAgent agent in agents)
        //{
        //    MoveTo mover = agent.gameObject.GetComponent<MoveTo>();
        //    if (mover != null)
        //        mover.goal = walls[0];
        //}
    }
}
