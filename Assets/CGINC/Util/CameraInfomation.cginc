#ifndef CAMERA_INFOMATION
#define CAMERA_INFOMATION

#include "UnityCG.cginc"
#include "UnityStandardCore.cginc"

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

//カメラ -> レンダリングするピクセル
float3 camera_to_screen_dir(float2 screen)
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

#endif //CAMERA_INFOMATION