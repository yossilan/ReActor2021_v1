using System;
using System.Threading;
using UnityEngine;
using System.Collections;
using System.IO.Ports;

//using UnityEditor;

public class SerialReaderWriter : MonoBehaviour
{
    public bool ShowDebugLog = false;

    public String[] AvailableSerialPorts;

    // Serial 
    public int SerialPortIndex = 28;
    public int NumValuesInInputString = 3;
    private const String SerialPortNamePrefix = "\\\\.\\COM";
    public SerialPort SerialReadStream;

    private Thread SerialReadThread;

    private static bool ReadThreadRequired = false;

    public string SerialLineRead;
    public string[] SerialReadVec;
    public float[] LatestSerialValues;

    public bool StartCompleted = false;

    public int NumReads = 0;

    private IEnumerator Start()
    {
        yield return new WaitForSeconds(2.0f);

        LatestSerialValues = new float[NumValuesInInputString];
        if (LatestSerialValues != null)
        {
            for (int i = 0; i < NumValuesInInputString; i++)
                LatestSerialValues[i] = 0.0f;
        }

        while (!StartCompleted)
        {
            try
            {
                SerialReadStream = new SerialPort(SerialPortNamePrefix + SerialPortIndex.ToString(), 115200);
                if (SerialReadStream != null)
                {
                    SerialReadStream.Open(); //Open the Serial Stream.
                    SerialReadThread = new Thread(new ThreadStart(GetSerial));
                    SerialReadThread.IsBackground = true;
                    SerialReadThread.Start();
                    ReadThreadRequired = true;

                    if (ShowDebugLog)
                        Debug.Log("SerialReadThread Started");
                }
            }
            catch (Exception e)
            {
                Debug.LogError("Could not open serial port: " + e.Message);
                if (SerialReadStream != null)
                    SerialReadStream.Close();

                SerialReadStream = null;
            }

            if (SerialReadStream != null && SerialReadStream.IsOpen)
                StartCompleted = true;
            else
                yield return new WaitForSeconds(10.0f);
        }
    }


    public void OnApplicationQuit()
    {
        ReadThreadRequired = false;

        if (SerialReadStream != null && SerialReadStream.IsOpen)
        {
            SerialReadStream.Close();
            if (ShowDebugLog)
                Debug.Log("SerialReadStream Closed1.");
        }

        ////////if (SerialWriteStream != null)
        ////////	SerialWriteStream.Close();
    }

    public void OnDestroy()
    {
        ReadThreadRequired = false;

        if (SerialReadStream != null && SerialReadStream.IsOpen)
        {
            SerialReadStream.Close();
            if (ShowDebugLog)
                Debug.LogError("SerialReadStream Closed2.");
        }

        //////if (SerialWriteStream != null)
        //////	SerialWriteStream.Close();
    }

    private void GetSerial()
    {
        while (SerialReadThread != null && SerialReadThread.IsAlive)
        {
            if (!ReadThreadRequired)
            {
                if (SerialReadStream != null)
                {
                    SerialReadStream.Close();
                    if (ShowDebugLog)
                        Debug.Log("SerialReadThread Closed3.");
                }

                Thread.Sleep(1000);
                SerialReadThread.Abort();
            }
            else
            {
                try
                {
                    if (SerialReadStream != null && SerialReadStream.IsOpen)
                    {
                        SerialReadStream.BaseStream.Flush(); //Clear the serial information so we assure we get new information.
                        SerialLineRead = SerialReadStream.ReadLine();
                    }
                }
                catch (Exception e)
                {
                    if (ReadThreadRequired)
                        Debug.LogError("Serial Read Failed: " + e.Message);
                }
            }
        }

        if (SerialReadStream != null && (SerialReadThread == null || !SerialReadThread.IsAlive))
        {
            SerialReadStream.Close();
            Debug.LogError("SerialReadThread Closed4.");
        }
    }



    // Update is called once per frame
    void Update()
    {
        if (!StartCompleted)
            return;

        try
        {
            SerialReadVec = SerialLineRead.Split(','); //My Serial script returns a 7 part value (for example: deltaTime, Serial index, touch-sensorVal1, touch-sensorVal2, etc.)

            if (SerialReadVec != null && SerialReadVec.Length == NumValuesInInputString) //Check if all values are recieved
            {
                for (int i = 0; i < NumValuesInInputString; i++)
                    LatestSerialValues[i] = float.Parse(SerialReadVec[i]);
            }
            else
                return;

            NumReads++;
        }

        catch (Exception e)
        {
            Debug.LogError("SerialReaderWriter Update Failed: " + e.Message);

            if (SerialReadStream == null)
                Debug.LogError("SerialReadStream is null!");
            else if (!SerialReadStream.IsOpen)
                Debug.LogError("SerialReadStream is closed!");
        }
    }


    void UpdateWriter()
	{
		////////try
		////////{
		////////	SerialWriteStream.BaseStream.Flush();
		////////	SerialWriteStream.WriteLine(LEDCursor.ToString());			
		////////}
		////////catch (Exception e)
		////////{
		////////	Debug.LogError("Could not write to serial port4: " + e.Message);		
		////////}
	}

}
