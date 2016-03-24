Shader "Raymarching/e#23658"
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

#include "RaymarchStructure.cginc"
#include "DistanceFunction.cginc"
#include "CameraInfomation.cginc"

float4 _Diffuse;
float4 _Specular;
float4 _Emission;

float3 _Position;
float3 _Rotation;
float3 _Scale;

//レイの進むべき方向を算出する
//カメラ -> レンダリングするピクセル
float3 compute_ray_dir(float2 screen)
{
	//UNITY_UV_START_AT_TOPはV値のトップ位置
	//Direct3Dでは1、 OpenGL系では0
#if UNITY_UV_STARTS_AT_TOP
	//Direct3Dの場合、頂点をy軸対称に反転させることで凌ぐ
	screen.y *= -1.0;
#endif
	//_ScreenParamsのxはレンダリングターゲットのピクセルの幅、yはピクセルの高さ
	screen.x *= _ScreenParams.x / _ScreenParams.y;

	//カメラの情報とピクセル位置から カメラ -> ピクセル のレイの方向ベクトルを求める
	float3 camDir = get_cam_fwd();
	float3 camUp = get_cam_up();
	float3 camSide = get_cam_right();
	float  focalLen = get_cam_focal_len();

	return normalize((camSide * screen.x) + (camUp * screen.y) + (camDir * focalLen));
}

//ある位置(レイがオブジェクトにヒットした位置)の深度値を取得する。
//depthの算出方法はDirect3DとOpenGL系で違う。
float compute_depth(float4 pos)
{
#if UNITY_UV_STARTS_AT_TOP
	return pos.z / pos.w;
#else
	return (pos.z / pos.w) * 0.5 + 0.5;
#endif
}

//モデルの位置、回転、スケール決定
float3 localize(float3 p, transform tr)
{
	//Position
	p -= tr.position;

	//Rotation
	float3 x = rotate_x(p, radians(tr.rotation.x));
	float3 xy = rotate_y(x, radians(tr.rotation.y));
	float3 xyz = rotate_z(xy, radians(tr.rotation.z));
	p = xyz;

	//Scale
	p /= tr.scale;

	return p;
}

float map(float3 p)
{
	//return kaleidoscopic_IFS(p);
	//return tglad_formula(p);
	//return hartverdrahtet(p);
	//return pseudo_kleinian(p);
	//return pseudo_knightyan(p);
	//return box(p, 1);
	return additive_pseudo_knightyan(p);
}

//空間内の点の位置を受け取り, 図形と点との最短距離を返す
//この関数の値が0となる点の集合が図形の表面となる。
//つまり0に近い値を返した場合は描画されることになる
float distance_func(float3 pos)
{
	return map(pos);
}

//ある位置(レイがオブジェクトにヒットした位置)におけるオブジェクトの法線を取得する。
//x,y,zは偏微分によって求められる。
//G-Bfferのnormal(法線バッファ)は符号なしデータ(RGBA 10, 10, 10, 2 bits)で格納されるため
//格納時は *0.5+0.5
//取得時は *2.0-1.0
//してやる必要がある(格納時に負数をなくし、取得時に再現する)。
float3 compute_normal(float3 pos)
{
	const float delta = 0.001;
	return normalize(float3(
		distance_func(pos + float3(delta, 0.0, 0.0)) - distance_func(pos + float3(-delta, 0.0, 0.0)),
		distance_func(pos + float3(0.0, delta, 0.0)) - distance_func(pos + float3(0.0, -delta, 0.0)),
		distance_func(pos + float3(0.0, 0.0, delta)) - distance_func(pos + float3(0.0, 0.0, -delta))))
		* 0.5 + 0.5;
}
//レイマーチを行う
raymarch_out raymarching(float2 pos, transform tr, const int trial_num)
{
	raymarch_out o;

	float3 ray_dir = compute_ray_dir(pos);
	float3 cam_pos = get_cam_pos();
	float max_ray_dist = get_cam_visibl_len();

	o.ray_length = 0;
	o.ray_pos = cam_pos + _ProjectionParams.y * ray_dir;

	for (o.trial_count = 0; o.trial_count < trial_num; ++o.trial_count) {
		o.distance = distance_func(localize(o.ray_pos, tr));
		o.ray_length += o.distance;
		o.ray_pos += ray_dir * o.distance;
		if (o.distance < RAY_HIT_DISTANCE || o.ray_length > max_ray_dist)
			break;
	}
	return o;
}

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

	raymarch_out ray_out;
	transform tr;

	tr.position = _Position;
	tr.rotation = _Rotation;
	tr.scale = _Scale;

	ray_out = raymarching(i.screen.xy, tr, 100);

	//レイがヒットしなかった場合はclip
	clip(-ray_out.distance + RAY_HIT_DISTANCE);

	//レイがヒットした位置からデプスと法線を計算
	float depth = compute_depth(mul(UNITY_MATRIX_VP, float4(ray_out.ray_pos, 1)));
	float3 normal = compute_normal(ray_out.ray_pos);

	//MRTによるG-Buffer出力(Depth,Normal以外は適当)
	gbuffer gb_out;
	gb_out.diffuse = _Diffuse;
	gb_out.specular = _Specular;
	gb_out.emission = _Emission;;
	gb_out.depth = depth;
	gb_out.normal = float4(normal, 1);
	return gb_out;
}

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
#pragma vertex vert
#pragma fragment frag
#pragma target 3.0

#pragma multi_compile _ OBJECT_SPACE_RAYMARCH
#pragma shader_feature _ _MAP_KALEIDOSCOPIC_IFS _MAP_TGLAD_FORMULA _MAP_HARTVERDRAHTET _MAP_PSEUDO_KLEINIAN _MAP_PSEUDO_KNIGHTYAN _MAP_CUBE


			ENDCG
		}
	}
}