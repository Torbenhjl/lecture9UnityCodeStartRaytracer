using UnityEngine;

public class ShaderController : MonoBehaviour
{
    public Material raytraceMaterial;

    Vector3 camPos = new Vector3(-2, 2, 1);
    Vector3 lookAt = new Vector3(0, 0, -1);
    float refIdx = 1.5f;
    float sphereOffsetX = 0f;

    float speed = 2.0f;
    float sensitivity = 2.0f;
    float yaw = 0f;
    float pitch = 0f;

    void Update()
    {
        float dt = Time.deltaTime;

        // Keyboard movement
        if (Input.GetKey(KeyCode.W)) camPos += Vector3.forward * speed * dt;
        if (Input.GetKey(KeyCode.S)) camPos += Vector3.back * speed * dt;
        if (Input.GetKey(KeyCode.A)) camPos += Vector3.left * speed * dt;
        if (Input.GetKey(KeyCode.D)) camPos += Vector3.right * speed * dt;
        if (Input.GetKey(KeyCode.Space)) camPos += Vector3.up * speed * dt;
        if (Input.GetKey(KeyCode.LeftControl)) camPos += Vector3.down * speed * dt;


        // Adjust refraction index with [ and ]
        if (Input.GetKey(KeyCode.LeftBracket)) refIdx = Mathf.Max(1.0f, refIdx - 0.01f);
        if (Input.GetKey(KeyCode.RightBracket)) refIdx = Mathf.Min(2.5f, refIdx + 0.01f);

        // Move sphere on X
        if (Input.GetKey(KeyCode.LeftArrow)) sphereOffsetX -= 0.5f * dt;
        if (Input.GetKey(KeyCode.RightArrow)) sphereOffsetX += 0.5f * dt;

        // Send data to shader
        raytraceMaterial.SetVector("_CamPos", camPos);
        raytraceMaterial.SetVector("_LookAt", lookAt);
        raytraceMaterial.SetFloat("_RefIdx", refIdx);
        raytraceMaterial.SetFloat("_SphereOffsetX", sphereOffsetX);
    }
}
