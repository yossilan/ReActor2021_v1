using System.Collections;
using System.Collections.Generic;
using UnityEngine;
//using UnityEditor.Animations;

public class UMLAnimatorController : MonoBehaviour
{
    public bool ForceRotations = true;
    public bool RandomRotations = true;
    public bool BabyAnimations = false;
    public bool ClampCharacterDistanceFromCenter = true;

    public List<string> LoadedAnimationNames;

    public bool DebugLogRequired = false;

    public Animator theAnimator;

    public AudioSource theAudio;
    public List<AudioClip> theAudioClips;

    public int AnimIndex = -1;
    //public int NextAnimIndex = 0;
    public float TimeSinceLastAnimationSwitch = 0.0f;

    public AnimatorClipInfo CurrentClipInfo;
    public float CurrentClipLength;
    public string CurrentClipName;


    public AnimatorStateInfo AnimStateInfo;
    public int TestPlayCount;
    public int NumClips;
    public string CurrentStateName;

    public Transform PelvisTransform;

    public Vector3 prevPelvisPos;
    public Vector3 prevPelvisRot;
    public bool newPose = false;


    public float DistanceFromCenter = 0.0f;
    public Vector2 DistanceVector = Vector2.zero;
    
    [SerializeField]
    private const float MaxDistanceFromCenter = 2.2f;



    void Start()
    {
        theAnimator = GetComponent<Animator>();

        theAudio = GetComponent<AudioSource>();

        foreach (Transform trans in transform.GetComponentsInChildren<Transform>())
        {
            if (trans.name.Contains("Bip01 Pelvis"))
            {
                PelvisTransform = trans;
                break;
            }
        }

        if (theAnimator != null)
        {
            //AnimatorController animCont = theAnimator.runtimeAnimatorController as AnimatorController;
            
            //for(int i=0; i< animCont.layers[0].stateMachine.states.Length; i++)
            //{
            //    //Debug.Log(animCont.layers[0].stateMachine.states[i].state.name);
            //    LoadedAnimationNames.Add(animCont.layers[0].stateMachine.states[i].state.name);
            //}

            //foreach (AnimationClip ac in theAnimator.runtimeAnimatorController.animationClips)
            //{
            //    //Debug.Log(ac.name);
            //}
            NumClips = theAnimator.runtimeAnimatorController.animationClips.Length;
            PlayNextAnim();
            //AnimatorStateInfo animStateInfo = theAnimator.GetCurrentAnimatorStateInfo(0);
            ////Debug.Log( AnimStateInfo.ToString() );
        }
    }

    void PlayNextAnim()
    {        
        TimeSinceLastAnimationSwitch = 0.0f;

        AnimStateInfo = theAnimator.GetNextAnimatorStateInfo(0);


        //testString = AnimStateInfo.fullPathHash;
        if (NumClips > 1)
        {
            TestPlayCount++;
            if (BabyAnimations)
            {
                if (TestPlayCount % 3 == 0)
                    AnimIndex = 1;
                else if (TestPlayCount % 3 == 1)
                    AnimIndex = 3;
                else //if (TestPlayCount % 3 == 2)
                    AnimIndex = 4;
            }
            else if (RandomRotations)
                AnimIndex = (AnimIndex + Random.Range(1, NumClips-1)) % NumClips;
            else
                AnimIndex = (TestPlayCount + NumClips - 1) % NumClips;

            if (LoadedAnimationNames != null && AnimIndex >= 0 && LoadedAnimationNames.Count > 0 && AnimIndex < LoadedAnimationNames.Count)
            {
                CurrentStateName = "Base Layer." + LoadedAnimationNames[AnimIndex];
                //Debug.Log("-I- Playing a modified anim-state name: " + CurrentStateName);
            }
            else
            {
                CurrentStateName = "Base Layer.Take 001";
                if (AnimIndex >= 1)
                {
                    CurrentStateName += " ";
                    CurrentStateName += AnimIndex - 1;
                }
            }


            prevPelvisPos = PelvisTransform.position;// - prevPelvisPos;
            prevPelvisRot = PelvisTransform.localRotation.eulerAngles;
            newPose = true;
            if (DebugLogRequired)
                Debug.Log("-I- Animation.Play ==> " + transform.name + " -- " + CurrentStateName);
            theAnimator.Play(CurrentStateName, 0, 0.03f);

            if (theAudio != null && theAudioClips != null && AnimIndex >= 0 && AnimIndex < theAudioClips.Count && theAudioClips[AnimIndex] != null)
                theAudio.PlayOneShot(theAudioClips[AnimIndex], 1.0f);

            //    theAnimator.Play("Base Layer.Take 001", 0, 0.0f);
            //else if (TestPlayCount % 3 == 1)
            //    theAnimator.Play("Base Layer.Take 001 0", 0, 0.0f);
            //else
            //    theAnimator.Play("Base Layer.Take 001 1", 0, 0.0f);
        }
        ////Fetch the current Animation clip information for the base layer
        //CurrentClipInfo = theAnimator.GetCurrentAnimatorClipInfo(0)[0];
        ////Access the current length of the clip
        //CurrentClipLength = CurrentClipInfo.clip.length;
        ////Access the Animation clip name
        //CurrentClipName = CurrentClipInfo.clip.name;

        ////anim.Play("Base Layer.Bounce", 0, 0.25f);
        //AnimIndex = (AnimIndex + 1) % theAnimator.runtimeAnimatorController.animationClips.Length;
        ////anim.Play(AnimIndex, 0, 0.0f);
        ////anim.Play("Armature|searcher_transition_4", 0, 0.0f);
        ////Debug.Log(CurrentClipInfo[0].clip);
        //theAnimator.Play(0, 0, 0.0f);
    }

    void Update()
    {
        TimeSinceLastAnimationSwitch += Time.deltaTime;

        if (Input.GetKeyDown(KeyCode.A) && theAnimator != null)
        {
            theAnimator.speed = theAnimator.speed < 0.5f ? 1.0f : 0.0f;
        }


        if (theAnimator != null && theAnimator.GetCurrentAnimatorStateInfo(0).normalizedTime >= 1.0f && !theAnimator.IsInTransition(0) && TimeSinceLastAnimationSwitch > 5.0f)
        {
            PlayNextAnim();
        }
    }

    private void LateUpdate()
    {
        if (newPose)
        {
            PelvisTransform.parent.parent.position = new Vector3(prevPelvisPos.x, 0.0f, prevPelvisPos.z);
            //PelvisTransform.parent.parent.rotation *= Quaternion.Euler(prevPelvisRot.x, 0.0f, 0.0f);// Quaternion.Euler(0.0f, 0.0f, prevPelvisRot);
            //if (TestPlayCount <= 1)
            //    PelvisTransform.parent.parent.rotation = Quaternion.Euler(0.0f, -90.0f + prevPelvisRot.x, 0.0f);
            //else

            if (ForceRotations)
            {
                Vector3 initRotE = new Vector3(-90.0f, 90.0f, 0.0f);
                Vector3 finalRotE = prevPelvisRot;
                Vector3 accumelatedRot = -initRotE + finalRotE;
                PelvisTransform.parent.parent.localRotation *= Quaternion.Euler(0.0f, accumelatedRot.x, 0.0f);
            }

            //PelvisTransform.parent.parent.rotation = Quaternion.Euler(0.0f, PelvisTransform.parent.parent.rotation.y + prevPelvisRot.x - (-90.0f), 0.0f);
            newPose = false;
        }


        // Verify that all characters stay within the hexagon
        DistanceVector = new Vector2(PelvisTransform.position.x, PelvisTransform.position.z);
        DistanceFromCenter = DistanceVector.magnitude;
        if (ClampCharacterDistanceFromCenter && DistanceFromCenter > MaxDistanceFromCenter)
        {
            Vector2 borderDistanceVec = 1.0f * MaxDistanceFromCenter * DistanceVector.normalized;
            PelvisTransform.position = new Vector3(borderDistanceVec.x, PelvisTransform.position.y, borderDistanceVec.y);
        }
    }
}
