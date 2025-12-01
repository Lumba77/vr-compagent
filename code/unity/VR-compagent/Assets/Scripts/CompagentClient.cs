using System.Collections;
using System.Text;
using System;
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

[System.Serializable]
public class TtsResponse
{
    public string audio;      // base64-encoded WAV data
    public int sample_rate;
}

public class CompagentClient : MonoBehaviour
{
    [SerializeField] private InputField inputField;   // must be InputField
    [SerializeField] private Text responseText;       // must be Text
    [SerializeField] private string apiUrl = "http://localhost:8000/compagent";
    [SerializeField] private string sttUrl = "http://localhost:8001/stt";
    [SerializeField] private string ttsUrl = "http://localhost:8002/tts";

    [Header("TTS Playback")]
    [SerializeField] private AudioSource ttsAudioSource;

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

        string replyText = data != null && !string.IsNullOrEmpty(data.response)
            ? data.response
            : responseJson;

        if (responseText != null)
        {
            responseText.text = replyText;
        }

        // If this was a voice-channel request, optionally trigger TTS playback
        if (channel == "voice" && !string.IsNullOrEmpty(replyText))
        {
            yield return StartCoroutine(RequestTtsAndPlay(replyText));
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

    // --- TTS helpers ---

    private IEnumerator RequestTtsAndPlay(string text)
    {
        if (string.IsNullOrWhiteSpace(ttsUrl) || ttsAudioSource == null)
            yield break;

        var payload = new { text = text, voice = "default" };
        string json = JsonUtility.ToJson(payload);

        var request = new UnityWebRequest(ttsUrl, UnityWebRequest.kHttpVerbPOST);
        byte[] bodyRaw = Encoding.UTF8.GetBytes(json);
        request.uploadHandler = new UploadHandlerRaw(bodyRaw);
        request.downloadHandler = new DownloadHandlerBuffer();
        request.SetRequestHeader("Content-Type", "application/json");

        yield return request.SendWebRequest();

        if (request.result != UnityWebRequest.Result.Success)
        {
            if (responseText != null)
                responseText.text = "TTS Error: " + request.error;
            yield break;
        }

        string ttsJson = request.downloadHandler.text;
        var tts = JsonUtility.FromJson<TtsResponse>(ttsJson);
        if (tts == null || string.IsNullOrEmpty(tts.audio))
            yield break;

        byte[] wavBytes;
        try
        {
            wavBytes = Convert.FromBase64String(tts.audio);
        }
        catch (Exception)
        {
            yield break;
        }

        var clip = WavBytesToAudioClip(wavBytes, "tts_clip");
        if (clip != null)
        {
            ttsAudioSource.clip = clip;
            ttsAudioSource.Play();
        }
    }

    private AudioClip WavBytesToAudioClip(byte[] wavBytes, string clipName)
    {
        if (wavBytes == null || wavBytes.Length < 44)
            return null;

        // Parse minimal WAV header (PCM 16-bit mono)
        int channels = BitConverter.ToInt16(wavBytes, 22);
        int sampleRateFromFile = BitConverter.ToInt32(wavBytes, 24);
        int bitsPerSample = BitConverter.ToInt16(wavBytes, 34);

        // Find "data" chunk
        int pos = 12;
        while (!(wavBytes[pos] == 'd' && wavBytes[pos + 1] == 'a' && wavBytes[pos + 2] == 't' && wavBytes[pos + 3] == 'a'))
        {
            pos += 4;
            int chunkSize = BitConverter.ToInt32(wavBytes, pos);
            pos += 4 + chunkSize;
            if (pos >= wavBytes.Length - 8)
                return null;
        }

        pos += 4; // skip "data"
        int dataSize = BitConverter.ToInt32(wavBytes, pos);
        pos += 4;

        int sampleCount = dataSize / (bitsPerSample / 8);
        float[] samples = new float[sampleCount];

        int byteIndex = pos;
        for (int i = 0; i < sampleCount && byteIndex + 1 < wavBytes.Length; i++)
        {
            short sample = BitConverter.ToInt16(wavBytes, byteIndex);
            samples[i] = sample / 32768f;
            byteIndex += 2;
        }

        int unityChannels = Mathf.Max(1, channels);
        int unitySampleRate = sampleRateFromFile > 0 ? sampleRateFromFile : sampleRate;
        var clip = AudioClip.Create(clipName, sampleCount / unityChannels, unityChannels, unitySampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }
}