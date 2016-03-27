#include "RaymarchStructure.cginc"
#include "DistanceFunction.cginc"
#include "CameraInfomation.cginc"

#ifndef RAY_HIT_DISTANCE
#define RAY_HIT_DISTANCE 0.001
#endif

//使用側でDistanceFunctionを変更したい場合に
//CUSTOM_DISTANCE_FUNCTIONを定義する
#if !defined(CUSTOM_DISTANCE_FUNCTION)
#define CUSTOM_DISTANCE_FUNCTION(p) __default_distance_func(p)
#endif //CUSTOM_DISTANCE_FUNCTION

//使用側でTransformを変更したい場合に
//CUSTOM_TRANSFORMを定義する
#if !defined(CUSTOM_TRANSFORM)
#define CUSTOM_TRANSFORM(p, r, s) init_transform(p, r, s)
#endif //CUSTOM_TRANSFORM

//空間内の点の位置を受け取り, 図形と点との最短距離を返す
//この関数の値が0となる点の集合が図形の表面となる。
//つまり0に近い値を返した場合は描画されることになる
float __default_distance_func(float3 pos)
{
	return box(pos, 1);
}

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

//モデルの位置、回転、スケール決定
//(ObjectSpaceの場合、PositionとRotationはオブジェクトのTransformと同期させたほうがわかりやすそう？)
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
		CUSTOM_DISTANCE_FUNCTION(pos + float3(delta, 0.0, 0.0)) - CUSTOM_DISTANCE_FUNCTION(pos + float3(-delta, 0.0, 0.0)),
		CUSTOM_DISTANCE_FUNCTION(pos + float3(0.0, delta, 0.0)) - CUSTOM_DISTANCE_FUNCTION(pos + float3(0.0, -delta, 0.0)),
		CUSTOM_DISTANCE_FUNCTION(pos + float3(0.0, 0.0, delta)) - CUSTOM_DISTANCE_FUNCTION(pos + float3(0.0, 0.0, -delta))))
		* 0.5 + 0.5;
}

//レイマーチを行う
raymarch_out raymarch(float2 pos, transform tr, const int trial_num)
{
	raymarch_out o;

	float3 ray_dir = compute_ray_dir(pos);
	float3 cam_pos = get_cam_pos();
	float max_ray_dist = get_cam_visibl_len();

	o.ray_length = 0;
	o.ray_pos = cam_pos + _ProjectionParams.y * ray_dir;

	for (o.trial_count = 0; o.trial_count < trial_num; ++o.trial_count) {
		o.distance = CUSTOM_DISTANCE_FUNCTION(localize(o.ray_pos, tr));
		o.ray_length += o.distance;
		o.ray_pos += ray_dir * o.distance;
		if (o.distance < RAY_HIT_DISTANCE || o.ray_length > max_ray_dist)
			break;
	}
	return o;
}

v2f raymarch_vert(appdata v)
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

gbuffer raymarch_frag(v2f i)
{
	//wは射影空間（視錐台空間）にある頂点座標をそれで割ることにより
	//「頂点をスクリーンに投影するための立方体の領域（-1≦x≦1、-1≦y≦1そして0≦z≦1）に納める」
	//オブジェクトスペースでのレイマーチで描画の破綻を防ぐ
	i.screen.xy /= i.screen.w;

	raymarch_out ray_out;
	transform tr;
	tr = CUSTOM_TRANSFORM(0, 0, 1);

	ray_out = raymarch(i.screen.xy, tr, 100);
	//レイがヒットしなかった場合はclip
	clip(-ray_out.distance + RAY_HIT_DISTANCE);

	//レイがヒットした位置からデプスと法線を計算
	float depth = compute_depth(mul(UNITY_MATRIX_VP, float4(ray_out.ray_pos, 1)));
	float3 normal = compute_normal(localize(ray_out.ray_pos, tr));

	//MRTによるG-Buffer出力(Depth,Normal以外は適当)
	gbuffer gb_out;
	gb_out = init_gbuffer(0.5, 0.5, float4(normal, 1), 0, depth);

	return gb_out;
}