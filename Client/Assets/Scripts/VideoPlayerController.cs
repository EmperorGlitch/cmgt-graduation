using System.Collections;
using System.IO;

using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Video;

[RequireComponent(typeof(VideoPlayer))]
public class VideoPlayerController : MonoBehaviour
{
    [SerializeField] private Material videoMaterial;
    [SerializeField] private CanvasGroup logo1CanvasGroup;
    [SerializeField] private CanvasGroup logo2CanvasGroup;
    [SerializeField] private RawImage logo1RawImage;
    [SerializeField] private RawImage logo2RawImage;
    [SerializeField] private float fadeDuration = 1.0f;
    [SerializeField] private float delayBeforeAfterPlay = 1.0f;

    private VideoPlayer videoPlayer;
    private bool isPlaying = false;
    private VideoPlaybackStatus playbackStatus = VideoPlaybackStatus.Stopped;

    private void Start()
    {
        videoPlayer = GetComponent<VideoPlayer>();
        videoPlayer.loopPointReached += OnVideoEnd;

        videoPlayer.Prepare();

        LoadLogo("logo1.png", logo1RawImage);
        LoadLogo("logo2.png", logo2RawImage);
    }

    public double GetVideoDuration()
    {
        if (videoPlayer != null && videoPlayer.isPrepared)
        {
            return videoPlayer.length;
        }
        else
        {
            Debug.LogWarning("Video is not prepared. Duration is unavailable.");
            return 0;
        }
    }

    public string GetCurrentVideoName()
    {
        if (!string.IsNullOrEmpty(videoPlayer.url))
        {
            return Path.GetFileName(videoPlayer.url);
        }
        else
        {
            Debug.LogWarning("Video URL is not set.");
            return string.Empty;
        }
    }

    public string GetPlaybackStatus()
    {
        return playbackStatus.ToString();
    }

    private void LoadLogo(string logoName, RawImage rawImage)
    {
        string path = Path.Combine(Application.persistentDataPath, "logos", logoName);

        if (File.Exists(path))
        {
            byte[] imageData = File.ReadAllBytes(path);
            Texture2D texture = new Texture2D(2, 2);
            texture.LoadImage(imageData);
            rawImage.texture = texture;
        }
        else
        {
            Debug.LogWarning($"Logo {logoName} not found in {path}.");
            rawImage.gameObject.SetActive(false);
        }
    }

    private void OnDestroy()
    {
        if (videoPlayer != null)
            videoPlayer.loopPointReached -= OnVideoEnd;
    }

    public void Execute(string json)
    {
        try
        {
            VideoPlayerCommand command = JsonUtility.FromJson<VideoPlayerCommand>(json);
            if (command.type == "command")
            {
                switch (command.command)
                {
                    case "play":
                        if (!string.IsNullOrEmpty(command.video))
                        {
                            PlayVideo(command.video);
                            playbackStatus = VideoPlaybackStatus.Playing;
                        }
                        break;

                    case "pause":
                        videoPlayer?.Pause();
                        playbackStatus = VideoPlaybackStatus.Paused;
                        break;

                    case "stop":
                        videoPlayer?.Stop();
                        playbackStatus = VideoPlaybackStatus.Stopped;
                        isPlaying = false;
                        break;
                }
            }
        }
        catch (System.Exception ex)
        {
            Debug.LogError($"Error processing command: {ex.Message}");
        }
    }

    private VideoLayout GetLayoutFromFilename(string filename)
    {
        string name = filename.ToLower();

        if (name.Contains("_tb"))
            return VideoLayout.TopBottomStereo;
        if (name.Contains("_sbs"))
            return VideoLayout.SideBySideStereo;

        return VideoLayout.Equirectangular;
    }

    private void PlayVideo(string fileName)
    {
        if (isPlaying)
            return;

        string videoDirectory = Path.Combine(Application.persistentDataPath, "videos");
        string path = Path.Combine(videoDirectory, fileName);

        if (File.Exists(path))
        {

            isPlaying = true;

            videoPlayer.source = VideoSource.Url;
            videoPlayer.url = path;

            VideoLayout layout = GetLayoutFromFilename(fileName);
            if (videoMaterial != null)
            {
                videoMaterial.SetFloat("_Layout", (float)layout);
            }
            else
            {
                Debug.LogWarning("Video material not assigned!");
            }

            if (logo1RawImage.texture != null)
            {
                StartCoroutine(FadeInLogo(logo1CanvasGroup, () =>
                {
                    StartCoroutine(FadeOutLogo(logo1CanvasGroup, () =>
                    {
                        StartCoroutine(PlayVideoWithDelay());
                    }));
                }));
            }
            else
            {
                StartCoroutine(PlayVideoWithDelay());
            }
        }
        else
        {
            Debug.LogWarning($"Video not found: {path}");
        }
    }

    private void OnVideoEnd(VideoPlayer player)
    {
        player.Stop();
        if (logo2RawImage.texture != null)
        {
            StartCoroutine(FadeInLogo(logo2CanvasGroup, () =>
            {
                StartCoroutine(FadeOutLogo(logo2CanvasGroup, () =>
                {
                    isPlaying = false;
                }));
            }));
        }
        else
        {
            isPlaying = false;
        }
    }

    private IEnumerator FadeInLogo(CanvasGroup logoCanvasGroup, System.Action onComplete = null)
    {
        logoCanvasGroup.alpha = 0f;
        logoCanvasGroup.gameObject.SetActive(true);
        float elapsedTime = 0f;

        while (elapsedTime < fadeDuration)
        {
            logoCanvasGroup.alpha = Mathf.Lerp(0f, 1f, elapsedTime / fadeDuration);
            elapsedTime += Time.deltaTime;
            yield return null;
        }

        logoCanvasGroup.alpha = 1f;
        onComplete?.Invoke();
    }

    private IEnumerator FadeOutLogo(CanvasGroup logoCanvasGroup, System.Action onComplete = null)
    {
        float elapsedTime = 0f;

        while (elapsedTime < fadeDuration)
        {
            logoCanvasGroup.alpha = Mathf.Lerp(1f, 0f, elapsedTime / fadeDuration);
            elapsedTime += Time.deltaTime;
            yield return null;
        }

        logoCanvasGroup.alpha = 0f;
        logoCanvasGroup.gameObject.SetActive(false);
        onComplete?.Invoke();
    }

    private IEnumerator PlayVideoWithDelay()
    {
        yield return new WaitForSeconds(delayBeforeAfterPlay);
        videoPlayer.Play();
    }

    [System.Serializable]
    public class VideoPlayerCommand
    {
        public string type;
        public string command;
        public string video;
    }
}

public enum VideoLayout
{
    Equirectangular = 0,
    TopBottomStereo = 1,
    SideBySideStereo = 2
}

public enum VideoPlaybackStatus
{
    Stopped,
    Playing,
    Paused
}