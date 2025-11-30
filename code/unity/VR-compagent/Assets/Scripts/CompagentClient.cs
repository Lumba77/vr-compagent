using System.Collections;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.UI;

[System.Serializable]
public class CompagentRequest
{
    public string input;
}

[System.Serializable]
public class CompagentResponse
{
    public string response;
    public string mode;
}

public class CompagentClient : MonoBehaviour
{
    [SerializeField] private InputField inputField;   // <- must be InputField
    [SerializeField] private Text responseText;       // <- must be Text
    [SerializeField] private string apiUrl = "http://localhost:8000/compagent";

    public void SendRequest()
    {
        if (string.IsNullOrWhiteSpace(apiUrl)) return;
        if (inputField == null) return;
        StartCoroutine(SendRequestCoroutine(inputField.text));
    }

    private IEnumerator SendRequestCoroutine(string userInput)
    {
        var requestPayload = new CompagentRequest { input = userInput };
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
}