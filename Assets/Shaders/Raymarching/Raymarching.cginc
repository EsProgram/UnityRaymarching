#ifndef RAYMARCHING
#define RAYMARCHING

#include "UnityCG.cginc"
#include "UnityStandardCore.cginc"
#include "DistanceFunctionVariant.cginc"

#define RAY_HIT_DISTANCE 0.001

//ワールド座標系のカメラの位置
float3 get_cam_pos() { return _WorldSpaceCameraPos; }
//変換行列からカメラの情報を取得
float3 get_cam_fwd() { return -UNITY_MATRIX_V[2].xyz; }
float3 get_cam_up() { return UNITY_MATRIX_V[1].xyz; }
float3 get_cam_right() { return UNITY_MATRIX_V[0].xyz; }
float  get_cam_focal_len() { return abs(UNITY_MATRIX_P[1][1]); }
//_ProjectionParamsのyはカメラのClippingPlanes[Near]、zは[Far]
//カメラがレンダリングする距離を算出する
float  get_cam_visibl_len() { return _ProjectionParams.z - _ProjectionParams.y; }

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

float map(float3 p)
{
#ifdef _MAP_KALEIDOSCOPIC_IFS
	return kaleidoscopic_IFS(p);
#elif _MAP_TGLAD_FORMULA
	return tglad_formula(p);
#elif _MAP_HARTVERDRAHTET
	return hartverdrahtet(p);
#elif _MAP_PSEUDO_KLEINIAN
	return pseudo_kleinian(p);
#elif _MAP_PSEUDO_KNIGHTYAN
	return pseudo_knightyan(p);
#else
	return additive_pseudo_knightyan(p);
#endif
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
void raymarching(float2 pos, const int trial_num, out float3 o_ray_pos, out int o_trial_count, out float ray_len, out float last_dist) {
	float3 ray_dir = compute_ray_dir(pos);
	float3 cam_pos = get_cam_pos();
	float max_ray_dist = get_cam_visibl_len();

	ray_len = 0;
	o_ray_pos = cam_pos + _ProjectionParams.y * ray_dir;

	for (o_trial_count = 0; o_trial_count < trial_num; ++o_trial_count) {
		last_dist = distance_func(o_ray_pos);
		ray_len += last_dist;
		o_ray_pos += ray_dir * last_dist;
		if (last_dist < RAY_HIT_DISTANCE || ray_len > max_ray_dist)
			break;
	}
}

#endif //RAYMARCHING