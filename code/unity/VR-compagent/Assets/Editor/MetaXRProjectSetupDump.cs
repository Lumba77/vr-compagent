using System;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEngine;

public static class MetaXRProjectSetupDump
{
    private const string DepthApiOculusXrRequirementUid = "a5e47360ca88da6ac9ce565eed87be4e";

    [MenuItem("Tools/Meta XR/Dump Required Fixes (Android)")]
    public static void DumpRequiredFixesAndroid()
    {
        DumpRequiredFixes(BuildTargetGroup.Android);
    }

    [MenuItem("Tools/Meta XR/Ignore DepthAPI OculusXR Requirement (Android)")]
    public static void IgnoreDepthApiOculusXrRequirementAndroid()
    {
        SetIgnoredByUid(BuildTargetGroup.Android, DepthApiOculusXrRequirementUid, ignored: true);
    }

    [MenuItem("Tools/Meta XR/Unignore DepthAPI OculusXR Requirement (Android)")]
    public static void UnignoreDepthApiOculusXrRequirementAndroid()
    {
        SetIgnoredByUid(BuildTargetGroup.Android, DepthApiOculusXrRequirementUid, ignored: false);
    }

    [MenuItem("Tools/Meta XR/Dump Required Fixes (Standalone)")]
    public static void DumpRequiredFixesStandalone()
    {
        DumpRequiredFixes(BuildTargetGroup.Standalone);
    }

    private static void DumpRequiredFixes(BuildTargetGroup buildTargetGroup)
    {
        try
        {
            var ovrProjectSetupType = FindType("OVRProjectSetup");
            if (ovrProjectSetupType == null)
            {
                Debug.LogError("[MetaXRProjectSetupDump] Could not find type OVRProjectSetup. Is Meta XR SDK Core installed?");
                return;
            }

            var getTasksMethod = ovrProjectSetupType.GetMethod(
                "GetTasks",
                BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static,
                binder: null,
                types: new[] { typeof(BuildTargetGroup) },
                modifiers: null);

            if (getTasksMethod == null)
            {
                Debug.LogError("[MetaXRProjectSetupDump] Could not find method OVRProjectSetup.GetTasks(BuildTargetGroup).");
                return;
            }

            var tasksObj = getTasksMethod.Invoke(null, new object[] { buildTargetGroup });
            if (tasksObj is not System.Collections.IEnumerable tasksEnumerable)
            {
                Debug.LogError("[MetaXRProjectSetupDump] GetTasks did not return an IEnumerable.");
                return;
            }

            var tasks = tasksEnumerable.Cast<object>().ToList();

            var requiredTasks = tasks
                .Where(t => IsTaskValidForPlatform(t, buildTargetGroup))
                .Where(t => GetTaskLevel(t, buildTargetGroup) == "Required")
                .Where(t => !IsTaskDone(t, buildTargetGroup))
                .Where(t => !IsTaskIgnored(t, buildTargetGroup))
                .Where(t => !IsTaskMarkedAsFixed(t, buildTargetGroup))
                .ToList();

            Debug.Log($"[MetaXRProjectSetupDump] Required fixes for {buildTargetGroup}: {requiredTasks.Count}");

            foreach (var task in requiredTasks)
            {
                var group = GetPropertyValue(task, "Group")?.ToString() ?? "Unknown";
                var tags = GetPropertyValue(task, "Tags")?.ToString() ?? "None";
                var uid = GetPropertyValue(task, "Id")?.ToString() ?? "(no id)";
                var message = GetTaskMessage(task, buildTargetGroup);
                var fixMessage = GetTaskFixMessage(task, buildTargetGroup);

                Debug.Log(
                    $"[MetaXRProjectSetupDump] [{group}] [{uid}] {message}\n" +
                    $"  Tags: {tags}\n" +
                    $"  Fix: {fixMessage}");
            }
        }
        catch (Exception ex)
        {
            Debug.LogError($"[MetaXRProjectSetupDump] Exception: {ex}");
        }
    }

    private static void SetIgnoredByUid(BuildTargetGroup buildTargetGroup, string uid, bool ignored)
    {
        try
        {
            var ovrProjectSetupType = FindType("OVRProjectSetup");
            if (ovrProjectSetupType == null)
            {
                Debug.LogError("[MetaXRProjectSetupDump] Could not find type OVRProjectSetup.");
                return;
            }

            var getTasksMethod = ovrProjectSetupType.GetMethod(
                "GetTasks",
                BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static,
                binder: null,
                types: new[] { typeof(BuildTargetGroup) },
                modifiers: null);

            if (getTasksMethod == null)
            {
                Debug.LogError("[MetaXRProjectSetupDump] Could not find method OVRProjectSetup.GetTasks(BuildTargetGroup).");
                return;
            }

            var tasksObj = getTasksMethod.Invoke(null, new object[] { buildTargetGroup });
            if (tasksObj is not System.Collections.IEnumerable tasksEnumerable)
            {
                Debug.LogError("[MetaXRProjectSetupDump] GetTasks did not return an IEnumerable.");
                return;
            }

            var tasks = tasksEnumerable.Cast<object>().ToList();
            var task = tasks.FirstOrDefault(t => string.Equals(GetPropertyValue(t, "Id")?.ToString(), uid, StringComparison.OrdinalIgnoreCase));
            if (task == null)
            {
                Debug.LogWarning($"[MetaXRProjectSetupDump] Task not found for uid: {uid}");
                return;
            }

            var setIgnoredMethod = task.GetType().GetMethod("SetIgnored", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
            if (setIgnoredMethod == null)
            {
                Debug.LogError("[MetaXRProjectSetupDump] Could not find method SetIgnored(BuildTargetGroup,bool) on task.");
                return;
            }

            setIgnoredMethod.Invoke(task, new object[] { buildTargetGroup, ignored });
            Debug.Log($"[MetaXRProjectSetupDump] SetIgnored({ignored}) for uid {uid} on {buildTargetGroup}. Re-run dump to confirm.");
        }
        catch (Exception ex)
        {
            Debug.LogError($"[MetaXRProjectSetupDump] Exception while setting ignored: {ex}");
        }
    }

    private static Type FindType(string typeName)
    {
        foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
        {
            var t = asm.GetType(typeName);
            if (t != null)
            {
                return t;
            }
        }

        return null;
    }

    private static object GetPropertyValue(object obj, string propertyName)
    {
        if (obj == null) return null;
        var prop = obj.GetType().GetProperty(propertyName, BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
        return prop?.GetValue(obj);
    }

    private static bool IsTaskValidForPlatform(object task, BuildTargetGroup platform)
    {
        var validObj = GetPropertyValue(task, "Valid");
        return InvokeOptionalLambda(validObj, platform, defaultValue: true);
    }

    private static string GetTaskLevel(object task, BuildTargetGroup platform)
    {
        var levelObj = GetPropertyValue(task, "Level");
        var levelStr = InvokeOptionalLambda(levelObj, platform, defaultValue: "Recommended");
        return levelStr;
    }

    private static string GetTaskMessage(object task, BuildTargetGroup platform)
    {
        var msgObj = GetPropertyValue(task, "Message");
        return InvokeOptionalLambda(msgObj, platform, defaultValue: "(no message)");
    }

    private static string GetTaskFixMessage(object task, BuildTargetGroup platform)
    {
        var msgObj = GetPropertyValue(task, "FixMessage");
        return InvokeOptionalLambda(msgObj, platform, defaultValue: "(no fix message)");
    }

    private static bool IsTaskDone(object task, BuildTargetGroup platform)
    {
        var isDoneDelegate = GetPropertyValue(task, "IsDone");
        if (isDoneDelegate is Delegate del)
        {
            var result = del.DynamicInvoke(platform);
            return result is bool b && b;
        }

        return false;
    }

    private static bool IsTaskIgnored(object task, BuildTargetGroup platform)
    {
        var method = task.GetType().GetMethod("IsIgnored", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
        if (method == null) return false;
        var result = method.Invoke(task, new object[] { platform });
        return result is bool b && b;
    }

    private static bool IsTaskMarkedAsFixed(object task, BuildTargetGroup platform)
    {
        var method = task.GetType().GetMethod("IsMarkedAsFixed", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
        if (method == null) return false;
        var result = method.Invoke(task, new object[] { platform });
        return result is bool b && b;
    }

    private static T InvokeOptionalLambda<T>(object optionalLambdaObj, BuildTargetGroup platform, T defaultValue)
    {
        if (optionalLambdaObj == null) return defaultValue;

        // OptionalLambdaType<BuildTargetGroup, T>.GetValue(BuildTargetGroup)
        var getValueMethod = optionalLambdaObj.GetType().GetMethod(
            "GetValue",
            BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance,
            binder: null,
            types: new[] { typeof(BuildTargetGroup) },
            modifiers: null);

        if (getValueMethod == null) return defaultValue;

        var value = getValueMethod.Invoke(optionalLambdaObj, new object[] { platform });
        if (value is T typed)
        {
            return typed;
        }

        // Handle enums / other types by ToString() in string case
        if (typeof(T) == typeof(string) && value != null)
        {
            return (T)(object)value.ToString();
        }

        return defaultValue;
    }
}
