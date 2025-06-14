using TMPro;
using UnityEngine;

public class HudController : MonoBehaviour
{
    [SerializeField] TextMeshProUGUI softwareVersionText;

    private void Start()
    {
        softwareVersionText.text = DeviceManager.GetSoftwareVersion();
    }
}