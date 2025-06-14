using System;
using System.Collections;
using System.Net.WebSockets;
using System.Threading;
using System.Threading.Tasks;
using System.Text;

using Newtonsoft.Json.Linq;

using UnityEngine;

public class NetworkController : MonoBehaviour
{
    [SerializeField] private int port = 8080;
    [SerializeField] private int timeoutMs = 1000;
    [SerializeField] private VideoPlayerController videoPlayerController;

    private ClientWebSocket webSocket;

    void Start()
    {
        StartCoroutine(ScanForServer());
    }

    void OnApplicationQuit() => CloseWebSocket();

    void OnDestroy() => CloseWebSocket();

    private void CloseWebSocket()
    {
        if (webSocket != null && webSocket.State == WebSocketState.Open)
        {
            try
            {
                webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "App quit", CancellationToken.None).Wait();
                Debug.Log("Connection closed.");
            }
            catch (Exception ex)
            {
                Debug.LogError($"Error closing the connection: {ex.Message}");
            }
            finally
            {
                webSocket.Dispose();
                webSocket = null;
            }
        }
    }

    IEnumerator ScanForServer()
    {
#if UNITY_ANDROID
        string networkSubnet = NetworkScanner.GetLocalSubnet();
        if (networkSubnet == null)
        {
            Debug.LogError("Could not determine the subnet.");

            yield break;
        }

        Debug.Log($"Scanning for server in subnet: {networkSubnet}.xxx");
#endif

        for (int i = 2; i < 255; i++)
        {
#if UNITY_ANDROID
            string ip = $"{networkSubnet}.{i}";
            string uri = $"ws://{ip}:{port}";
#elif UNITY_EDITOR
            string uri = $"ws://127.0.0.1:{port}";
#elif UNITY_STANDALONE_WIN
            string uri = $"ws://127.0.0.1:{port}";
#endif
            Task<bool> tryConnectTask = TryConnect(uri);
            yield return new WaitUntil(() => tryConnectTask.IsCompleted);

            if (tryConnectTask.Result)
            {
                Debug.Log($"Successful connection to server: {uri}");

                SendDeviceInfo();

                StartCoroutine(ReceiveMessages());
                StartCoroutine(SendPlaybackStatusLoop());
                yield break;
            }

            yield return null;
        }

        Debug.LogWarning("Server not found.");
    }

    private async void SendDeviceInfo()
    {
        if (webSocket == null || webSocket.State != WebSocketState.Open)
            return;

        DeviceInfo deviceInfo = new DeviceInfo
        {
            id = DeviceManager.GetId(),
            deviceType = DeviceManager.GetDeviceType(),
            batteryLevel = DeviceManager.GetBatteryLevel()
        };

        string json = JsonUtility.ToJson(deviceInfo);

        Debug.Log(json);

        byte[] bytes = Encoding.UTF8.GetBytes(json);
        var segment = new ArraySegment<byte>(bytes);

        try
        {
            await webSocket.SendAsync(segment, WebSocketMessageType.Text, true, CancellationToken.None);
            Debug.Log("Device information sent.");
        }
        catch (Exception ex)
        {
            Debug.LogError($"Error sending device information: {ex.Message}");
        }
    }

    private async void SendPlaybackStatus()
    {
        if (webSocket == null || webSocket.State != WebSocketState.Open)
            return;

        PlaybackStatus playbackStatus = new PlaybackStatus
        {
            currentVideo = videoPlayerController.GetCurrentVideoName(),
            totalDuration = videoPlayerController.GetVideoDuration(),
            status = videoPlayerController.GetPlaybackStatus()
        };

        string json = JsonUtility.ToJson(playbackStatus);

        Debug.Log(json);

        byte[] bytes = Encoding.UTF8.GetBytes(json);
        var segment = new ArraySegment<byte>(bytes);

        try
        {
            await webSocket.SendAsync(segment, WebSocketMessageType.Text, true, CancellationToken.None);
            Debug.Log("Playback status sent.");
        }
        catch (Exception ex)
        {
            Debug.LogError($"Error sending playback status: {ex.Message}");
        }
    }

    private Task<bool> TryConnect(string uri)
    {
        return Task.Run(async () =>
        {
            try
            {
                webSocket = new ClientWebSocket();
                CancellationTokenSource cts = new CancellationTokenSource(timeoutMs);

                await webSocket.ConnectAsync(new Uri(uri), cts.Token);

                return webSocket.State == WebSocketState.Open;
            }
            catch
            {
                return false;
            }
        });
    }

    private IEnumerator SendPlaybackStatusLoop()
    {
        while (true)
        {
            SendPlaybackStatus();
            yield return new WaitForSeconds(1f);
        }
    }

    private IEnumerator ReceiveMessages()
    {
        byte[] buffer = new byte[1024];
        VideoDownloader downloader = new VideoDownloader();

        while (webSocket != null && webSocket.State == WebSocketState.Open)
        {
            var segment = new ArraySegment<byte>(buffer);
            var receiveTask = webSocket.ReceiveAsync(segment, CancellationToken.None);

            yield return new WaitUntil(() => receiveTask.IsCompleted);

            var result = receiveTask.Result;
            if (result.MessageType == WebSocketMessageType.Text)
            {
                string message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                Debug.Log($"Message received: {message}");

                JObject json;
                try
                {
                    json = JObject.Parse(message);
                }
                catch (Exception ex)
                {
                    Debug.LogError($"JSON parsing error: {ex.Message}");
                    continue;
                }

                string type = json["type"]?.ToString();

                if (type == "video_list")
                {
                    var videos = json["videos"] as JArray;
                    if (videos != null)
                    {
                        foreach (var video in videos)
                        {
                            string name = video["name"]?.ToString();
                            string url = video["url"]?.ToString();

                            if (!string.IsNullOrEmpty(name) && !string.IsNullOrEmpty(url))
                            {
                                if (!downloader.IsVideoAvailable(name))
                                {
                                    var downloadTask = downloader.DownloadVideoAsync(name, url);
                                    yield return new WaitUntil(() => downloadTask.IsCompleted);

                                    if (downloadTask.Exception != null)
                                    {
                                        Debug.LogError($"Error during download {name}: {downloadTask.Exception.InnerException?.Message}");
                                    }
                                    else
                                    {
                                        Debug.Log($"Video {name} has been downloaded successfully.");
                                    }
                                }
                                else
                                {
                                    Debug.Log($"Video {name} already exists locally.");
                                }
                            }
                        }
                    }
                }
                else if (type == "command")
                {
                    videoPlayerController?.Execute(message);
                }
            }
        }
    }
}
