using System;
using UnityEngine;

public static class DeviceManager
{
    private const string PlayerPrefsDeviceIdKey = "DeviceId";

    public static string GetSoftwareVersion() => Application.version;

    public static string GetId()
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        string androidId = TryGetAndroidId();
        if (!string.IsNullOrEmpty(androidId))
        {
            return androidId;
        }
#endif
        return GetOrCreateLocalDeviceId();
    }

    public static string GetDeviceType() => SystemInfo.deviceModel;

    public static double GetBatteryLevel()
    {
        float batteryLevel = SystemInfo.batteryLevel;

        if (batteryLevel < 0f)
            return -1;

        return Math.Round(batteryLevel * 100f, 1);
    }

#if UNITY_ANDROID && !UNITY_EDITOR
    private static string TryGetAndroidId()
    {
        try
        {
            using (var unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            {
                var currentActivity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity");
                var contentResolver = currentActivity.Call<AndroidJavaObject>("getContentResolver");

                using (var secure = new AndroidJavaClass("android.provider.Settings$Secure"))
                {
                    return secure.CallStatic<string>("getString", contentResolver, "android_id");
                }
            }
        }
        catch (Exception e)
        {
            Debug.LogWarning($"Failed to get Android ID: {e.Message}");
            return null;
        }
    }
#endif

    private static string GetOrCreateLocalDeviceId()
    {
        if (PlayerPrefs.HasKey(PlayerPrefsDeviceIdKey))
        {
            return PlayerPrefs.GetString(PlayerPrefsDeviceIdKey);
        }

        string newId = Guid.NewGuid().ToString();
        PlayerPrefs.SetString(PlayerPrefsDeviceIdKey, newId);
        PlayerPrefs.Save();
        return newId;
    }
}