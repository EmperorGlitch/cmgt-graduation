using System.IO;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Networking;

public class VideoDownloader
{
    private readonly string videoDirectory;

    public VideoDownloader()
    {
        videoDirectory = Path.Combine(Application.persistentDataPath, "videos");

        if (!Directory.Exists(videoDirectory))
        {
            Directory.CreateDirectory(videoDirectory);
        }
    }

    public bool IsVideoAvailable(string videoName)
    {
        string videoPath = Path.Combine(videoDirectory, videoName);
        return File.Exists(videoPath);
    }

    public async Task<bool> DownloadVideoAsync(string videoName, string videoUrl)
    {
        if (IsVideoAvailable(videoName))
        {
            Debug.Log("Video already downloaded locally: " + videoName);
            return true;
        }

        using (UnityWebRequest request = UnityWebRequest.Get(videoUrl))
        {
            var operation = request.SendWebRequest();

            while (!operation.isDone)
                await Task.Yield();

            if (request.result == UnityWebRequest.Result.Success)
            {
                string videoPath = Path.Combine(videoDirectory, videoName);
                File.WriteAllBytes(videoPath, request.downloadHandler.data);
                Debug.Log("Video downloaded: " + videoName);
                return true;
            }
            else
            {
                Debug.LogError($"Error loading {videoName}: {request.error}");
                return false;
            }
        }
    }
}