using UnityEngine;
using TMPro;

public class Character : MonoBehaviour
{
    public TextMeshProUGUI textDisplay;
    private string input = "";

    void Update()
    {
        if (Input.touchPad && Input.GetTouch("LeftTrigger").phase == TouchPhase.LongPress)
        {
            // Example: Trigger voice synthesis
            SynthesizeVoice("Hello, I'm your AI companion!");
        }
    }

    public void SynthesizeVoice(string text)
    {
        UnityEngine.Networking.UnityWebRequest webRequest = UnityWebRequestTexture.LoadImage(text);
        yield return webRequest.Send();
        if (webRequest.isDone)
        {
            Texture2D texture = webRequest.texture;
            Sprite sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(1f, 1f));
            GetComponent<SpriteRenderer>().sprite = sprite;
        }
    }
}