using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode, RequireComponent(typeof(Camera))]
public class RaymarchingRenderer : MonoBehaviour, IDisposable
{
  private const CameraEvent RENDER_PASS = CameraEvent.AfterGBuffer;

#if UNITY_EDITOR

  /// SceneViewでのカメラ表示(複数シーンビュー対応)
  /// PreviewSceneCameraをON/OFFにすることで切り替え可能
  /// すぐには適用されないため、一度Playボタンを押す必要がある(用改善)
  private const string USAGE =
    @"シーンビューでRaymarchingを適用するかどうかを設定できます。
    設定後は一度Playボタンを押してシーンビュー内のカメラを更新する必要があります。";

  private static List<Camera> sceneCams = new List<Camera>();

  [SerializeField, Tooltip(USAGE)]
  private bool previewSceneCamera;

#endif

  private Camera cam;
  private CommandBuffer command;
  private Mesh quad;

  [SerializeField]
  private Material material = null;

  public void Dispose()
  {
    if(cam != null && command != null)
      cam.RemoveCommandBuffer(RENDER_PASS, command);
#if UNITY_EDITOR
    if(sceneCams.Count > 0 && command != null)
      foreach(var scam in sceneCams)
        if(scam != null)
          scam.RemoveCommandBuffer(RENDER_PASS, command);
    sceneCams.Clear();
#endif

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
    if(cam == null)
      cam = GetComponent<Camera>();

    if(quad == null)
      quad = CreateQuad();

    if(command == null)
    {
      var com = new CommandBuffer();
      com.name = "Raymarching";
      com.DrawMesh(quad, Matrix4x4.identity, material, 0, 0);
      cam.AddCommandBuffer(RENDER_PASS, com);
#if UNITY_EDITOR
      sceneCams = UnityEditor.SceneView.GetAllSceneCameras().ToList();
      if(previewSceneCamera && sceneCams.Count > 0)
        foreach(var scam in sceneCams)
          scam.AddCommandBuffer(RENDER_PASS, com);
#endif
      command = com;
    }
  }
}