using System.Collections.Generic;
using System.Linq;
using UnityEngine;

[ExecuteInEditMode]
public class ImageEffect : MonoBehaviour
{
  [SerializeField]
  private Material mat;

  public void OnRenderImage(RenderTexture source, RenderTexture destination)
  {
    Graphics.Blit(source, destination, mat);
  }
}