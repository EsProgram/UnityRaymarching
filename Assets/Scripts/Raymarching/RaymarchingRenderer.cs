using System;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode, RequireComponent(typeof(Camera))]
public class RaymarchingRenderer : MonoBehaviour, IDisposable
{
  private const CameraEvent RENDER_PASS = CameraEvent.AfterGBuffer;
  private Camera cam;
  private CommandBuffer command;
  private Mesh quad;

  [SerializeField]
  private Material material = null;

  public void Dispose()
  {
    if(cam != null && command != null)
      cam.RemoveCommandBuffer(RENDER_PASS, command);
    cam = null;
    command = null;
  }

  private Mesh CreateQuad()
  {
    var mesh = new Mesh();
    mesh.vertices = new Vector3[4] {
      new Vector3( 1.0f , 1.0f,  0.0f),
      new Vector3(-1.0f , 1.0f,  0.0f),
      new Vector3(-1.0f ,-1.0f,  0.0f),
      new Vector3( 1.0f ,-1.0f,  0.0f),
    };
    mesh.triangles = new int[6] { 0, 1, 2, 2, 3, 0 };
    return mesh;
  }

  private void OnDestroy()
  {
    Dispose();
  }

  private void OnDisable()
  {
    Dispose();
  }

  private void OnPreRender()
  {
    if(cam != null)
      return;

    if(quad == null)
      quad = CreateQuad();

    cam = GetComponent<Camera>();

    var com = new CommandBuffer();
    com.name = "Raymarching";
    com.DrawMesh(quad, Matrix4x4.identity, material, 0, 0);
    cam.AddCommandBuffer(RENDER_PASS, com);

    command = com;
  }
}