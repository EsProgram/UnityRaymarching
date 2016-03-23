Shader "Raymarching/e#23658"
{
	Properties{
		[KeywordEnum(NONE,KALEIDOSCOPIC_IFS,TGLAD_FORMULA,HARTVERDRAHTET,PSEUDO_KLEINIAN,PSEUDO_KNIGHTYAN)]
		_MAP("Distacne Func", Float) = 0
		_Diffuse("Diffuse (RGB) Occlusion (A)", COLOR) = (0.5, 0.5, 0.5, 1)
		_Specular("Specular (RGB) Smoothness (A)", COLOR) = (0, 0, 0, 0)
		_Emission("Emission (RGB) NoUse(A)",COLOR) = (0.1 ,0.1 ,0.1 ,1)

		[Toggle(OBJECT_SPACE_RAYMARCH)]
		_ObjectSpaceRaymarch("Object Space Raymarch", Float) = 0
	}

CGINCLUDE

#include "Raymarching.cginc"

float4 _Diffuse;
float4 _Specular;
float4 _Emission;

struct appdata
{
	float4 vertex : POSITION;
};

struct v2f
{
	float4 vertex : SV_POSITION;
	float4 screen : TEXCOORD0;
};

//MRTにより出力するG-Buffer
struct gbuffer
{
	half4 diffuse : SV_Target0; // rgb: diffuse,  a: occlusion
	half4 specular : SV_Target1; // rgb: specular, a: smoothness
	half4 normal : SV_Target2; // rgb: normal,   a: unused
	half4 emission : SV_Target3; // rgb: emission, a: unused
	float depth : SV_Depth;
};

v2f vert(appdata v)
{
	v2f o;
#if OBJECT_SPACE_RAYMARCH
	o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
#else
	o.vertex = v.vertex;
#endif
	//座標変換の必要なし(Command BufferでMeshをそのまま描画する)
	//フラグメントシェーダーではTEXCOORDはラスタライズにより各ピクセルへの位置を取得できる
	o.screen = o.vertex;
	return o;
}

gbuffer frag(v2f i)
{
	//wは射影空間（視錐台空間）にある頂点座標をそれで割ることにより
	//「頂点をスクリーンに投影するための立方体の領域（-1≦x≦1、-1≦y≦1そして0≦z≦1）に納める」
	//オブジェクトスペースでのレイマーチで描画の破綻を防ぐ
	i.screen.xy /= i.screen.w;

	int trial_count;
	float ray_len;
	float3 ray_pos;
	float last_dist;
	raymarching(i.screen.xy, 64, ray_pos, trial_count, ray_len, last_dist);


	//レイがヒットしなかった場合はclip
	clip(-last_dist + RAY_HIT_DISTANCE);

	//レイがヒットした位置からデプスと法線を計算
	float depth = compute_depth(mul(UNITY_MATRIX_VP, float4(ray_pos, 1)));
	float3 normal = compute_normal(ray_pos);

	//MRTによるG-Buffer出力(Depth,Normal以外は適当)
	gbuffer o;
	o.diffuse = _Diffuse;
	o.specular = _Specular;
	o.emission = _Emission;;
	o.depth = depth;
	o.normal = float4(normal, 1);
	return o;
}


ENDCG


	SubShader
	{
		Cull Off
		Pass
		{
			Tags { "LightMode" = "Deferred" }
			//G-Bufferへの描画はStencil を有効にして7bit目を立てる(128を足す)。
			//Stencilの7bit目が立っていないピクセルはライティングされない。
			//なので常にステンシルテストに合格させ、128で上書きする。
			Stencil
			{
				Comp Always
				Pass Replace
				Ref 128
			}

			CGPROGRAM

#pragma enable_d3d11_debug_symbols
#pragma vertex vert
#pragma fragment frag
#pragma target 3.0

#pragma multi_compile _ OBJECT_SPACE_RAYMARCH
#pragma shader_feature _ _MAP_KALEIDOSCOPIC_IFS _MAP_TGLAD_FORMULA _MAP_HARTVERDRAHTET _MAP_PSEUDO_KLEINIAN _MAP_PSEUDO_KNIGHTYAN


			ENDCG
		}
	}
}