Shader "Raymarching/StanderdRaymarch"
{

	Properties{
		_Diffuse("Diffuse (RGB) Occlusion (A)", COLOR) = (0.5, 0.5, 0.5, 1)
		_Specular("Specular (RGB) Smoothness (A)", COLOR) = (0.5, 0.5, 0.5, 1)
		_Emission("Emission (RGB) NoUse(A)",COLOR) = (0.5 ,0.5 ,0.5 ,1)

		_Position("Position (XYZ) Axis (W) no use", Vector) = (0, 0, 0, 0)
		_Rotation("Rotate (XYZ) Axis (W) no use", Vector) = (0, 0, 0, 0)
		_Scale("Scale (XYZ) Axis (W) no use", Vector) = (1, 1, 1, 0)

		[Toggle(OBJECT_SPACE_RAYMARCH)]
		_ObjectSpaceRaymarch("Object Space Raymarch", Float) = 0
	}

CGINCLUDE

//#define CUSTOM_DISTANCE_FUNCTION(p) sphere(p, 1)
#define CUSTOM_DISTANCE_FUNCTION(p) additive_pseudo_knightyan(p)
#define CUSTOM_TRANSFORM(p, r, s) init_transform(_Position, _Rotation, _Scale)
#define CUSTOM_GBUFFER_OUTPUT(diff, spec, norm, emit, dep) init_gbuffer(_Diffuse, _Specular, norm, _Emission, dep)

float4 _Position;
float4 _Rotation;
float4 _Scale;

float4 _Diffuse;
float4 _Specular;
float4 _Emission;

#include "Assets/CGINC/Raymarch/RaymarchFoundation.cginc"

ENDCG


	SubShader
	{
		Cull Off
		Stencil
		{
			Comp Always
			Pass Replace
			Ref 128
		}
		Pass
		{
			Tags { "LightMode" = "Deferred" }
			//G-Bufferへの描画はStencil を有効にして7bit目を立てる(128を足す)。
			//Stencilの7bit目が立っていないピクセルはライティングされない。
			//なので常にステンシルテストに合格させ、128で上書きする。

			CGPROGRAM

#pragma enable_d3d11_debug_symbols
#pragma vertex raymarch_vert
#pragma fragment raymarch_frag
#pragma target 3.0

#pragma multi_compile _ OBJECT_SPACE_RAYMARCH

			ENDCG
		}
	}
}