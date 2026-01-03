using UnityEngine;
using UnityEngine.XR;

public class VRTrackingFix : MonoBehaviour
{
    private InputDevice headDevice;
    private float lastWarningTime;
    private const float WarningIntervalSeconds = 2f;

    void Start()
    {
        // Find the head tracking device
        headDevice = InputDevices.GetDeviceAtXRNode(XRNode.Head);
    }

    void Update()
    {
        if (!headDevice.isValid)
        {
            headDevice = InputDevices.GetDeviceAtXRNode(XRNode.Head);
        }

        // Manually apply head position and rotation if not tracking
        if (headDevice.isValid)
        {
            headDevice.TryGetFeatureValue(CommonUsages.devicePosition, out Vector3 position);
            headDevice.TryGetFeatureValue(CommonUsages.deviceRotation, out Quaternion rotation);
            
            transform.localPosition = position;
            transform.localRotation = rotation;
        }
        else
        {
            if (Time.unscaledTime - lastWarningTime >= WarningIntervalSeconds)
            {
                lastWarningTime = Time.unscaledTime;
                Debug.LogWarning("Head tracking device not found!");
            }
        }
    }
}