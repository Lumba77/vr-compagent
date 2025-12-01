using System.Collections;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.UI;

[System.Serializable]
public class CompagentRequest
{
    public string input;
    public string channel; // "text" or "voice"
}

[System.Serializable]
public class CompagentResponse
{
    public string response;
    public string mode;
    public string channel;
}

[System.Serializable]
public class SttResponse
{
    public string text;
    public string language;
}

public class CompagentClient : MonoBehaviour
{
    [SerializeField] private InputField inputField;   // must be InputField
    [SerializeField] private Text responseText;       // must be Text
    [SerializeField] private string apiUrl = "http://localhost:8000/compagent";
    [SerializeField] private string sttUrl = "http://localhost:8001/stt";

    [Header("Voice Recording")]
    [SerializeField] private int sampleRate = 16000;
    [SerializeField] private int maxRecordSeconds = 10;

    private AudioClip _recordedClip;
    private bool _isRecording;

    // --- Text flow ---

    public void SendRequest()
    {
        if (string.IsNullOrWhiteSpace(apiUrl)) return;
        if (inputField == null) return;
        StartCoroutine(SendRequestCoroutine(inputField.text, "text"));
    }

    private IEnumerator SendRequestCoroutine(string userInput, string channel)
    {
        var requestPayload = new CompagentRequest { input = userInput, channel = channel };
        string json = JsonUtility.ToJson(requestPayload);

        var request = new UnityWebRequest(apiUrl, UnityWebRequest.kHttpVerbPOST);
        byte[] bodyRaw = Encoding.UTF8.GetBytes(json);
        request.uploadHandler = new UploadHandlerRaw(bodyRaw);
        request.downloadHandler = new DownloadHandlerBuffer();
        request.SetRequestHeader("Content-Type", "application/json");

        yield return request.SendWebRequest();

        if (request.result != UnityWebRequest.Result.Success)
        {
            if (responseText != null)
                responseText.text = "Error: " + request.error;
            yield break;
        }

        string responseJson = request.downloadHandler.text;
        var data = JsonUtility.FromJson<CompagentResponse>(responseJson);

        if (responseText != null)
        {
            responseText.text =
                data != null && !string.IsNullOrEmpty(data.response)
                    ? data.response
                    : responseJson;
        }
    }

    // --- Voice flow ---

    public void ToggleRecordAndSend()
    {
        if (!_isRecording)
        {
            StartRecording();
        }
        else
        {
            StopAndSendRecording();
        }
    }

    private void StartRecording()
    {
        if (!Microphone.IsRecording(null))
        {
            _recordedClip = Microphone.Start(null, false, maxRecordSeconds, sampleRate);
            _isRecording = true;
            if (responseText != null)
                responseText.text = "Listening...";
        }
    }

    private void StopAndSendRecording()
    {
        if (!_isRecording) return;

        Microphone.End(null);
        _isRecording = false;

        if (_recordedClip == null)
            return;

        StartCoroutine(HandleVoiceFlowCoroutine());
    }

    private IEnumerator HandleVoiceFlowCoroutine()
    {
        // 1) Convert recorded AudioClip to WAV bytes
        byte[] wavData = AudioClipToWav(_recordedClip, out int lengthSamples);
        if (wavData == null || wavData.Length == 0)
            yield break;

        // 2) Send to STT service using multipart/form-data
        var form = new WWWForm();
        form.AddBinaryData("audio", wavData, "speech.wav", "audio/wav");
        form.AddField("language", "auto");

        var sttRequest = UnityWebRequest.Post(sttUrl, form);
        sttRequest.downloadHandler = new DownloadHandlerBuffer();

        yield return sttRequest.SendWebRequest();

        if (sttRequest.result != UnityWebRequest.Result.Success)
        {
            if (responseText != null)
                responseText.text = "STT Error: " + sttRequest.error;
            yield break;
        }

        string sttJson = sttRequest.downloadHandler.text;
        var stt = JsonUtility.FromJson<SttResponse>(sttJson);
        if (stt == null || string.IsNullOrEmpty(stt.text))
        {
            if (responseText != null)
                responseText.text = "STT Error: empty transcript";
            yield break;
        }

        if (inputField != null)
            inputField.text = stt.text;

        // 3) Send transcript to compagent as voice channel
        yield return SendRequestCoroutine(stt.text, "voice");
    }

    // Simple WAV encoder for PCM 16-bit mono from an AudioClip
    private byte[] AudioClipToWav(AudioClip clip, out int lengthSamples)
    {
        lengthSamples = 0;
        if (clip == null)
            return null;

        int samples = clip.samples * clip.channels;
        float[] data = new float[samples];
        clip.GetData(data, 0);

        // Convert float [-1,1] to 16-bit PCM
        lengthSamples = samples;
        const int headerSize = 44;
        byte[] bytes = new byte[samples * 2 + headerSize];

        // RIFF header
        System.Text.Encoding.UTF8.GetBytes("RIFF").CopyTo(bytes, 0);
        System.BitConverter.GetBytes(bytes.Length - 8).CopyTo(bytes, 4);
        System.Text.Encoding.UTF8.GetBytes("WAVE").CopyTo(bytes, 8);
        System.Text.Encoding.UTF8.GetBytes("fmt ").CopyTo(bytes, 12);
        System.BitConverter.GetBytes(16).CopyTo(bytes, 16); // PCM chunk size
        System.BitConverter.GetBytes((short)1).CopyTo(bytes, 20); // audio format PCM
        System.BitConverter.GetBytes((short)1).CopyTo(bytes, 22); // channels (mono)
        System.BitConverter.GetBytes(sampleRate).CopyTo(bytes, 24);
        System.BitConverter.GetBytes(sampleRate * 2).CopyTo(bytes, 28); // byte rate
        System.BitConverter.GetBytes((short)2).CopyTo(bytes, 32); // block align
        System.BitConverter.GetBytes((short)16).CopyTo(bytes, 34); // bits per sample
        System.Text.Encoding.UTF8.GetBytes("data").CopyTo(bytes, 36);
        System.BitConverter.GetBytes(samples * 2).CopyTo(bytes, 40);

        int offset = headerSize;
        for (int i = 0; i < samples; i++)
        {
            short val = (short)(Mathf.Clamp01((data[i] + 1f) * 0.5f) * 65535f - 32768f);
            byte[] b = System.BitConverter.GetBytes(val);
            bytes[offset++] = b[0];
            bytes[offset++] = b[1];
        }

        return bytes;
    }
}