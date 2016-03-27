#ifndef RAYMARCH_STRUCT
#define RAYMARCH_STRUCT

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

struct raymarch_out
{
	float3 ray_pos;//Rayが進んだ最終的なワールド位置
	int trial_count;//DistanceFunction試行回数
	float ray_length;//最終的にRayが進んだ長さ
	float distance;//最後に試行された距離関数の出力値
};

struct transform
{
	float3 position;
	float3 rotation;
	float3 scale;
};

gbuffer init_gbuffer(half4 diffuse, half4 specular, half3 normal, half4 emission, float depth)
{
	gbuffer gb;
	gb.diffuse = diffuse;
	gb.specular = specular;
	gb.normal = half4(normal, 1);
	gb.emission = emission;
	gb.depth = depth;

	return gb;
}

transform init_transform(float3 pos, float3 rot, float3 scl)
{
	transform tr;
	tr.position = pos;
	tr.rotation = rot;
	tr.scale = scl;
	return tr;
}
#endif //RAYMARCH_STRUCT